#!/usr/bin/env bats

# Tests for bin/ansible_wrapper, the multi-call dispatcher that sets the
# ansible environment per invocation (instead of exporting it from
# shell-startup) and execs the real ansible command found later on PATH.
#
# The real commands are stand-ins: a stub dir holds an executable named for
# the command that reports the environment and arguments it was handed, and
# sits on PATH *after* the repo's bin/ — the same order the live shell has
# with ~/.local/bin, which is what makes self-recursion possible at all.

load ../helpers/common

# For `run -127` (the not-found case), which otherwise warns BW01.
bats_require_minimum_version 1.5.0

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"

  STUB="$BATS_TEST_TMPDIR/realbin"
  WORK="$BATS_TEST_TMPDIR/work"
  mkdir -p "$STUB" "$WORK"

  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/config"
  export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
  export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
  unset ANSIBLE_CONFIG ANSIBLE_HOME

  # SC2016: the body is meant to expand when the stub runs, not here.
  # shellcheck disable=SC2016
  make_script_stub "$STUB" ansible-playbook '
printf "real=%s\n" "$0"
printf "cfg=%s\n" "${ANSIBLE_CONFIG-<unset>}"
printf "home=%s\n" "${ANSIBLE_HOME-<unset>}"
printf "arg=%s\n" "$@"
exit 3'

  cd "$WORK" || return
}

# Run a dispatcher symlink with the repo's bin/ ahead of the stub dir. The
# timeout turns a self-exec loop into a failure rather than a hung suite.
run_cmd() {
  local cmd=$1
  shift
  run timeout 10 env "PATH=$ROOT/bin:$STUB:/usr/bin:/bin" "$ROOT/bin/$cmd" "$@"
}

# --- environment ------------------------------------------------------------

@test "no ./ansible.cfg: ANSIBLE_CONFIG points at the dotfiles config" {
  run_cmd ansible-playbook site.yml
  assert_failure 3
  assert_line "cfg=$XDG_CONFIG_HOME/ansible/ansible.cfg"
  assert_line "home=$XDG_CONFIG_HOME/ansible"
}

@test "./ansible.cfg present: ANSIBLE_CONFIG is left unset so ansible finds it" {
  touch ansible.cfg

  run_cmd ansible-playbook site.yml
  assert_failure 3
  assert_line "cfg=<unset>"
  assert_line "home=$XDG_CONFIG_HOME/ansible"
}

@test "a caller's own ANSIBLE_CONFIG and ANSIBLE_HOME are respected" {
  export ANSIBLE_CONFIG=/elsewhere/ansible.cfg ANSIBLE_HOME=/elsewhere

  run_cmd ansible-playbook site.yml
  assert_line "cfg=/elsewhere/ansible.cfg"
  assert_line "home=/elsewhere"
}

@test "the XDG cache and data dirs the config names are created" {
  run_cmd ansible-playbook site.yml

  for d in "$XDG_CACHE_HOME"/ansible/{tmp,galaxy} \
    "$XDG_DATA_HOME"/ansible/{collections,inventory,roles}; do
    assert_dir_exists "$d"
  done
}

# --- exec of the real binary ------------------------------------------------

@test "execs the real command with args verbatim and its exit status" {
  run_cmd ansible-playbook -i 'host one,' 'a b.yml'
  assert_failure 3
  assert_line "real=$STUB/ansible-playbook"
  assert_line "arg=-i"
  assert_line "arg=host one,"
  assert_line "arg=a b.yml"
}

@test "skips every PATH entry that resolves back to the dispatcher" {
  # A second dir holding its own symlink to the dispatcher, plus the repo's
  # bin/ listed twice: each must be passed over to reach the real command.
  local alt="$BATS_TEST_TMPDIR/alt"
  mkdir -p "$alt"
  ln -s "$ROOT/bin/ansible_wrapper" "$alt/ansible-playbook"

  run timeout 10 env "PATH=$ROOT/bin:$alt:$ROOT/bin:$STUB:/usr/bin:/bin" \
    "$ROOT/bin/ansible-playbook" site.yml
  assert_failure 3
  assert_line "real=$STUB/ansible-playbook"
}

@test "no real command on PATH: fails 127 without looping" {
  run -127 timeout 10 env "PATH=$ROOT/bin:/usr/bin:/bin" "$ROOT/bin/ansible-vault"
  assert_failure 127
  assert_output --partial "ansible-vault: not found"
}

# --- dispatcher by its own name ---------------------------------------------

@test "run by its own name without a flag it prints usage and exits 2" {
  run "$ROOT/bin/ansible_wrapper"
  assert_failure 2
  assert_output --partial "Usage: ansible_wrapper"
}

@test "-h prints usage and exits 0" {
  run "$ROOT/bin/ansible_wrapper" -h
  assert_success
  assert_output --partial "Usage: ansible_wrapper"
}

@test "a symlink name outside the registry is refused (exit 2)" {
  local d="$BATS_TEST_TMPDIR/rogue"
  mkdir -p "$d"
  ln -s "$ROOT/bin/ansible_wrapper" "$d/ansible-bogus"

  run "$d/ansible-bogus"
  assert_failure 2
  assert_output --partial "not a registered ansible command"
}

# --- registry consistency ---------------------------------------------------

@test "--known-tools lists the registry, sorted, without ansible-lint" {
  run "$ROOT/bin/ansible_wrapper" --known-tools
  assert_success
  assert_line "ansible"
  assert_line "ansible-playbook"
  refute_line "ansible-lint"

  run bash -c '"$1" --known-tools | LC_ALL=C sort -c' _ "$ROOT/bin/ansible_wrapper"
  assert_success
}

@test "the live bin/ symlinks to ansible_wrapper match its registry" {
  # Every bin/ symlink whose target is ansible_wrapper, compared both ways
  # with the registry: a registered command with no link, or a stray link,
  # fails this.
  local links
  links=$(find "$ROOT/bin" -maxdepth 1 -type l -lname ansible_wrapper \
    -printf '%f\n' | LC_ALL=C sort)

  # Floor: two empty lists would also compare equal.
  [[ -n $links ]] || fail "no bin/ symlinks to ansible_wrapper found"

  assert_equal "$links" "$("$ROOT/bin/ansible_wrapper" --known-tools)"
}

@test "bin/ansible-lint stays on docker_wrapper" {
  assert_equal "$(readlink "$ROOT/bin/ansible-lint")" docker_wrapper
}
