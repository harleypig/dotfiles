#!/usr/bin/env bats

# Unit tests for lib/version-managers/rust. No real rustup, network or docker:
# curl, uname and the downloaded rustup-init are stubs, and the rustup that
# rustup-init "installs" is itself a stub that records its arguments. The
# report and dispatch cases drive the real bin/vmgr, because it runs under
# `set -u` and sourcing the module into bats would not reproduce an
# unbound-variable crash; the install/remove cases source the module and call
# its functions directly so the stubs' records can be read afterwards.

load ../helpers/common

setup() {
  load_bats_libs

  VMGR="$(dotfiles_root)/bin/vmgr"

  export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/cfg"
  mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME"
  unset RUSTUP_HOME CARGO_HOME

  # Hermetic pins config, so tests don't couple to config/vmgr/rust.
  export VMGR_CONFIG_DIR="$BATS_TEST_TMPDIR/vmgrconf"
  mkdir -p "$VMGR_CONFIG_DIR"
  printf 'RUSTUP_PIN=9.9.9\nRUST_TOOLCHAIN_PIN=8.8.8\n' > "$VMGR_CONFIG_DIR/rust"

  CARGO_BIN="$XDG_DATA_HOME/cargo/bin"
  BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$BIN"

  # shellcheck disable=SC2016  # $vars expand when the stub runs
  make_script_stub "$BIN" uname '[[ $1 == -s ]] && echo Linux || echo x86_64'
}

# Write a stub rustup into $CARGO_BIN reporting version $1, recording every
# call (with the RUSTUP_HOME it saw) in $CARGO_BIN/rustup.args.
fake_rustup() {
  mkdir -p "$CARGO_BIN"

  # shellcheck disable=SC2016  # $vars expand when the stub runs
  make_script_stub "$CARGO_BIN" rustup '
printf "%s | RUSTUP_HOME=%s\n" "$*" "$RUSTUP_HOME" >> "'"$CARGO_BIN"'/rustup.args"
[[ $1 == --version ]] && echo "rustup '"$1"' (abc 2026-01-01)"
exit 0'
}

# A curl stub serving a fake rustup-init (which installs fake_rustup at the
# pin) and its sha256 file. $1 = "bad" serves a checksum that does not match.
fake_curl() {
  local sum_mode=${1:-good}

  # The rustup-init it serves: records its args, then installs a rustup
  # reporting the pinned version.
  INIT_SRC="$BATS_TEST_TMPDIR/rustup-init.src"
  cat > "$INIT_SRC" << EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> '$BIN/rustup-init.args'
mkdir -p '$CARGO_BIN'
cat > '$CARGO_BIN/rustup' << 'INNER'
#!/usr/bin/env bash
printf '%s | RUSTUP_HOME=%s\n' "\$*" "\$RUSTUP_HOME" >> '$CARGO_BIN/rustup.args'
[[ \$1 == --version ]] && echo 'rustup 9.9.9 (abc 2026-01-01)'
exit 0
INNER
chmod +x '$CARGO_BIN/rustup'
EOF

  # shellcheck disable=SC2016  # $vars expand when the stub runs
  make_script_stub "$BIN" curl '
printf "%s\n" "$*" >> "'"$BIN"'/curl.args"
out= url=
while (($#)); do
  case $1 in
    -o) out=$2; shift 2 ;;
    -*) shift ;;
    *) url=$1; shift ;;
  esac
done
if [[ $url == *.sha256 ]]; then
  if [[ '"$sum_mode"' == bad ]]; then
    echo "0000  *./rustup-init" > "$out"
  else
    echo "$(sha256sum "'"$INIT_SRC"'" | cut -d" " -f1) *./rustup-init" > "$out"
  fi
else
  cp "'"$INIT_SRC"'" "$out"
fi'
}

# Source the module and run one of its functions with the stubs first on PATH.
# rc + output are captured without tripping bats's errexit.
mod() {
  # shellcheck disable=SC1090,SC1091  # path resolved from the repo root at runtime
  source "$(dotfiles_root)/lib/version-managers/rust"

  local saved=$PATH
  PATH="$BIN:$PATH"
  MOD_RC=0
  "$@" > "$BATS_TEST_TMPDIR/out" 2>&1 || MOD_RC=$?
  PATH=$saved
  MOD_OUT=$(cat "$BATS_TEST_TMPDIR/out")
}

# --- dispatch -----------------------------------------------------------------

@test "the real lib dir ships a rust module advertising rustup" {
  run "$VMGR" list
  assert_success
  assert_output --partial 'rust: rustup'
}

@test "help rust shows rust-specific help" {
  run "$VMGR" help rust
  assert_success
  assert_output --partial 'config/vmgr/rust'
  assert_output --partial '--no-modify-path'
}

# --- report -------------------------------------------------------------------

@test "report rust with nothing installed exits 0 and suggests installing" {
  run "$VMGR" report rust
  assert_success
  assert_output --partial 'rustup      : not installed'
  assert_output --partial "rustup not installed at the current cargo home; run 'vmgr install rust'."
  assert_output --partial 'toolchains  : none installed'
  refute_output --partial 'unbound variable'
}

@test "report rust reads the pinned versions from config, not code" {
  run "$VMGR" report rust
  assert_success
  assert_output --partial 'rustup      : 9.9.9'
  assert_output --partial 'toolchain   : 8.8.8 (default)'
}

@test "report rust at the vmgr location: clean match, version, toolchains" {
  fake_rustup 9.9.9
  mkdir -p "$XDG_DATA_HOME/rustup/toolchains/8.8.8-x86_64-unknown-linux-gnu"
  printf 'default_toolchain = "8.8.8-x86_64-unknown-linux-gnu"\n' \
    > "$XDG_DATA_HOME/rustup/settings.toml"

  run "$VMGR" report rust
  assert_success
  assert_output --partial 'matches the expected vmgr location'
  assert_output --partial 'vmgr default'
  assert_output --partial 'rustup      : 9.9.9'
  assert_output --partial '(default -> 8.8.8-x86_64-unknown-linux-gnu)'
  refute_output --partial 'rustup version:'
}

@test "report rust flags a rustup older than the pin" {
  fake_rustup 9.9.1

  run "$VMGR" report rust
  assert_success
  assert_output --partial '9.9.1 installed vs 9.9.9 pinned'
}

@test "report rust flags the old config rustup home and suggests migrating" {
  mkdir -p "$XDG_CONFIG_HOME/rustup/toolchains/nightly-x86_64-unknown-linux-gnu"

  RUSTUP_HOME="$XDG_CONFIG_HOME/rustup" run "$VMGR" report rust
  assert_success
  assert_output --partial 'from environment (RUSTUP_HOME)'
  assert_output --partial 'but vmgr expects'
  assert_output --partial "$XDG_DATA_HOME/rustup"
  assert_output --partial 'Consider migrating'
  assert_output --partial 'nightly-x86_64-unknown-linux-gnu'
}

# --- install / update ---------------------------------------------------------

@test "install: fetches the pinned rustup-init, then the pinned toolchain" {
  fake_curl

  mod rustup_install
  [ "$MOD_RC" -eq 0 ]

  grep -q 'rustup/archive/9.9.9/x86_64-unknown-linux-gnu/rustup-init' "$BIN/curl.args"
  grep -qx -- '-y --no-modify-path --default-toolchain none' "$BIN/rustup-init.args"
  grep -q -- 'toolchain install --no-self-update --profile default 8.8.8' "$CARGO_BIN/rustup.args"
  grep -q -- '^default 8.8.8' "$CARGO_BIN/rustup.args"
}

@test "install: a checksum mismatch stops before rustup-init runs" {
  fake_curl bad

  mod rustup_install
  [ "$MOD_RC" -ne 0 ]
  [[ $MOD_OUT == *"checksum mismatch"* ]]
  [ ! -e "$BIN/rustup-init.args" ]
  [ ! -e "$CARGO_BIN/rustup" ]
}

@test "install: a rustup already at the pin is not re-downloaded" {
  fake_curl
  fake_rustup 9.9.9

  mod rustup_install
  [ "$MOD_RC" -eq 0 ]
  [ ! -e "$BIN/curl.args" ]
  grep -q -- 'toolchain install --no-self-update --profile default 8.8.8' "$CARGO_BIN/rustup.args"
}

@test "install: a rustup at another version is moved to the pin" {
  fake_curl
  fake_rustup 9.9.1

  mod rustup_install
  [ "$MOD_RC" -eq 0 ]
  grep -q 'rustup/archive/9.9.9/' "$BIN/curl.args"
  [ -e "$BIN/rustup-init.args" ]
}

@test "install: an unmapped architecture fails without downloading" {
  fake_curl
  # shellcheck disable=SC2016  # $vars expand when the stub runs
  make_script_stub "$BIN" uname '[[ $1 == -s ]] && echo Linux || echo riscv64'

  mod rustup_install
  [ "$MOD_RC" -ne 0 ]
  [[ $MOD_OUT == *"no rustup-init mapping"* ]]
  [ ! -e "$BIN/curl.args" ]
}

@test "update: refuses when rustup is not installed" {
  fake_curl

  mod rustup_update
  [ "$MOD_RC" -ne 0 ]
  [[ $MOD_OUT == *"vmgr install rust"* ]]
  [ ! -e "$BIN/curl.args" ]
}

# --- remove -------------------------------------------------------------------

@test "remove: nothing installed is a successful no-op" {
  mod rustup_remove
  [ "$MOD_RC" -eq 0 ]
  [[ $MOD_OUT == *"nothing to remove"* ]]
}

@test "remove: uses rustup self uninstall at the vmgr location" {
  fake_rustup 9.9.9

  mod rustup_remove
  [ "$MOD_RC" -eq 0 ]
  grep -q -- "^self uninstall -y | RUSTUP_HOME=$XDG_DATA_HOME/rustup" "$CARGO_BIN/rustup.args"
}

# self uninstall deletes RUSTUP_HOME whole, and the old home is a tracked
# directory of the dotfiles checkout.
@test "remove: refuses when RUSTUP_HOME is not the vmgr location" {
  fake_rustup 9.9.9
  mkdir -p "$XDG_CONFIG_HOME/rustup"

  RUSTUP_HOME="$XDG_CONFIG_HOME/rustup" mod rustup_remove
  [ "$MOD_RC" -ne 0 ]
  [[ $MOD_OUT == *"remove it by hand"* ]]
  run grep -q 'self uninstall' "$CARGO_BIN/rustup.args"
  assert_failure
  [ -d "$XDG_CONFIG_HOME/rustup" ]
}
