#!/usr/bin/env bats

# vmgr and mise side by side (#435): when both manage a language, vmgr's
# toolchain wins on PATH; mise is the fallback for whatever vmgr does not
# manage. The mechanism is load order, not a switch -- config/shell-startup
# sources mise before node/perl/python/rust (glob order), mise's default
# (non-aggressive) activation lets later PATH changes take precedence, and the
# vmgr-side modules prepend their toolchain after it.
#
# So these tests source the five real modules in that order, in a fresh
# non-interactive bash child, against a throwaway HOME/XDG tree holding:
#   - a fake mise: a `mise` function whose `activate` output prepends a shims
#     dir holding node/perl/python3/rustc/cargo stand-ins (the shims path the
#     module takes when non-interactive -- the full-activation path goes
#     through the same eval and is covered by test_shell_startup_mise.bats);
#   - a fake vmgr node: nvm.sh plus a default alias naming an installed
#     version, as `vmgr install node` leaves it;
#   - a fake vmgr perl: a perlbrew etc/bashrc that prepends its default Perl,
#     as perlbrew's real bashrc does;
#   - a fake vmgr rust: rustc/cargo/rustup in $CARGO_HOME/bin, where
#     `vmgr install rust` (rustup-init) puts rustup's proxies.
# Each stand-in is a script that only exists under the throwaway tree, so a
# resolved path says unambiguously which manager supplied the tool, whatever
# the host or CI runner has installed system-wide.

load ../helpers/common

setup() {
  load_bats_libs

  ROOT="$(dotfiles_root)"
  T="$BATS_TEST_TMPDIR"
  SHIMS="$T/mise/shims"
  NVM_BIN="$T/data/nvm/versions/node/v22.23.1/bin"
  PB_BIN="$T/data/perlbrew/perls/perl-5.40.0/bin"
  CARGO_BIN="$T/data/cargo/bin"
}

# A stand-in executable named $2 in dir $1.
fake_bin() {
  mkdir -p "$1"
  printf '#!/bin/sh\necho %s\n' "$1/$2" > "$1/$2"
  chmod +x "$1/$2"
}

install_mise() {
  local tool

  for tool in node perl python3 rustc cargo; do
    fake_bin "$SHIMS" "$tool"
  done
}

install_vmgr_node() {
  fake_bin "$NVM_BIN" node
  echo "# fake nvm" > "$T/data/nvm/nvm.sh"
  mkdir -p "$T/data/nvm/alias"
  printf 'v22.23.1\n' > "$T/data/nvm/alias/default"
}

install_vmgr_perl() {
  fake_bin "$PB_BIN" perl
  mkdir -p "$T/data/perlbrew/etc"
  # shellcheck disable=SC2016  # $PATH is for the bashrc to expand, not us
  printf 'export PATH="%s:$PATH"\n' "$PB_BIN" > "$T/data/perlbrew/etc/bashrc"
}

install_vmgr_rust() {
  local tool

  for tool in rustc cargo rustup; do
    fake_bin "$CARGO_BIN" "$tool"
  done
}

# Source mise, node, perl, python, rust in startup order and print where each
# tool resolves, one `tool=path` per line (empty when nothing provides it),
# then the rust homes the rust module chose.
run_startup() {
  run bash --norc -c '
    root=$1 t=$2 shims=$3

    HOME="$t/home" XDG_DATA_HOME="$t/data" XDG_CONFIG_HOME="$t/cfg"
    XDG_CACHE_HOME="$t/cache" XDG_STATE_HOME="$t/state" DOTFILES="$t/dot"
    export HOME XDG_DATA_HOME XDG_CONFIG_HOME XDG_CACHE_HOME XDG_STATE_HOME

    havecmd() { command -v "$1" > /dev/null 2>&1; }
    addpath() {
      local first=0
      [[ $1 == --first || $1 == -f ]] && { first=1; shift; }
      for p in "$@"; do
        ((first)) && PATH="$p:$PATH" || PATH="$PATH:$p"
      done
    }

    if [[ -d $shims ]]; then
      mise() { [[ $1 == activate ]] && printf "export PATH=%q\n" "$shims:$PATH"; }
    fi

    # Only the system dirs, so the host'"'"'s own mise/nvm never leak in; perl
    # must stay findable because the perl module gates on havecmd perl.
    PATH=/usr/bin:/bin

    for m in mise node perl python rust; do
      source "$root/config/shell-startup/$m"
    done

    for tool in node perl python3 rustc cargo; do
      echo "$tool=$(type -P "$tool")"
    done
    echo "CARGO_HOME=$CARGO_HOME"
    echo "RUSTUP_HOME=$RUSTUP_HOME"
    echo "AGGRESSIVE=${MISE_ACTIVATE_AGGRESSIVE-unset}"
  ' _ "$ROOT" "$T" "$SHIMS"
}

@test "both installed: vmgr node, perl and rust win, mise keeps python" {
  install_mise
  install_vmgr_node
  install_vmgr_perl
  install_vmgr_rust

  run_startup

  assert_success
  assert_line "node=$NVM_BIN/node"
  assert_line "perl=$PB_BIN/perl"
  assert_line "rustc=$CARGO_BIN/rustc"
  assert_line "cargo=$CARGO_BIN/cargo"
  # vmgr manages uv/pipx, not a Python interpreter, so mise supplies it.
  assert_line "python3=$SHIMS/python3"
}

@test "only vmgr installed: vmgr node, perl and rust are on PATH" {
  install_vmgr_node
  install_vmgr_perl
  install_vmgr_rust

  run_startup

  assert_success
  assert_line "node=$NVM_BIN/node"
  assert_line "perl=$PB_BIN/perl"
  assert_line "rustc=$CARGO_BIN/rustc"
  assert_line "cargo=$CARGO_BIN/cargo"
  refute_output --partial "$SHIMS"
}

@test "only mise installed: mise supplies node, perl, python and rust" {
  install_mise

  run_startup

  assert_success
  assert_line "node=$SHIMS/node"
  assert_line "perl=$SHIMS/perl"
  assert_line "python3=$SHIMS/python3"
  assert_line "rustc=$SHIMS/rustc"
  assert_line "cargo=$SHIMS/cargo"
}

@test "neither installed: no tool resolves to either manager" {
  run_startup

  assert_success
  refute_output --partial "$SHIMS"
  refute_output --partial "$NVM_BIN"
  refute_output --partial "$PB_BIN"
  refute_output --partial "rustc=$CARGO_BIN"
  refute_output --partial "cargo=$CARGO_BIN"
}

# The rust homes are XDG data, and $CARGO_HOME/bin is prepended only when it
# exists, so a machine without it gains no dead PATH entry.
@test "rust homes: CARGO_HOME and RUSTUP_HOME default to XDG_DATA_HOME" {
  run_startup

  assert_success
  assert_line "CARGO_HOME=$T/data/cargo"
  assert_line "RUSTUP_HOME=$T/data/rustup"
}

# Before vmgr managed rust, RUSTUP_HOME was $XDG_CONFIG_HOME/rustup. A machine
# whose toolchains still live there keeps using them until the new home
# exists, so moving the default cannot orphan an installed toolchain.
@test "rust homes: toolchains only in the old config home keep it in use" {
  mkdir -p "$T/cfg/rustup/toolchains/stable-x86_64-unknown-linux-gnu"

  run_startup

  assert_success
  assert_line "RUSTUP_HOME=$T/cfg/rustup"
}

@test "rust homes: once the new data home has toolchains it wins" {
  mkdir -p "$T/cfg/rustup/toolchains/stable-x86_64-unknown-linux-gnu"
  mkdir -p "$T/data/rustup/toolchains/1.99.0-x86_64-unknown-linux-gnu"

  run_startup

  assert_success
  assert_line "RUSTUP_HOME=$T/data/rustup"
}

# Any rustup call pointed at the new home creates it with only a
# settings.toml; that alone must not strand the toolchains in the old home.
@test "rust homes: a new data home with no toolchains does not win" {
  mkdir -p "$T/cfg/rustup/toolchains/stable-x86_64-unknown-linux-gnu"
  mkdir -p "$T/data/rustup"
  touch "$T/data/rustup/settings.toml"

  run_startup

  assert_success
  assert_line "RUSTUP_HOME=$T/cfg/rustup"
}

# The old home is a tracked directory in this repo (its settings.toml), so it
# exists on every checkout; without toolchains it is not a reason to stay.
@test "rust homes: an old config home with no toolchains is not used" {
  mkdir -p "$T/cfg/rustup"
  touch "$T/cfg/rustup/settings.toml"

  run_startup

  assert_success
  assert_line "RUSTUP_HOME=$T/data/rustup"
}

# nvm's default alias can name something other than an installed version
# (lts/*, node, a version since removed). Then there is nothing to put on
# PATH at login, and the lazy loader is left to resolve it on first use.
@test "both installed, unresolvable nvm default: lazy loader, mise node" {
  install_mise
  install_vmgr_node
  printf 'lts/*\n' > "$T/data/nvm/alias/default"

  run_startup

  assert_success
  assert_line "node=$SHIMS/node"
}

# The precedence above holds only while mise runs non-aggressively:
# activate_aggressive (MISE_ACTIVATE_AGGRESSIVE) makes every prompt push
# mise's paths back in front of vmgr's. Nothing in this repo may turn it on.
@test "guard: startup and tracked mise config leave activate_aggressive off" {
  install_mise
  install_vmgr_node

  run_startup

  assert_success
  assert_line "AGGRESSIVE=unset"

  # Settings, not mentions: the mise module names the setting in a comment.
  run git -C "$ROOT" grep -n -E -i \
    -e 'activate_aggressive[[:space:]]*=[[:space:]]*(true|1)' \
    -e 'MISE_ACTIVATE_AGGRESSIVE=' -- config/ shell-startup
  assert_failure
}
