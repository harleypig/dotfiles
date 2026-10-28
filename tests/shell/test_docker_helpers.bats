#!/usr/bin/env bats

# Unit tests for lib/docker_helpers (the dw_* helpers). Pure logic — no docker
# daemon needed.

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"
  # shellcheck source=/dev/null
  source "$ROOT/lib/docker_helpers"
  unset DW_TAG DW_LOG
}

#------------------------------------------------------------------------------
# dw_user

@test "dw_user defaults to current uid:gid" {
  local -a args=()
  dw_user args
  assert_equal "${args[*]}" "--user $(id -u):$(id -g)"
}

@test "dw_user positional uid and gid" {
  local -a args=()
  dw_user args 999 888
  assert_equal "${args[*]}" "--user 999:888"
}

@test "dw_user positional uid only keeps default gid" {
  local -a args=()
  dw_user args 999
  assert_equal "${args[*]}" "--user 999:$(id -g)"
}

@test "dw_user -gid flag sets only the gid" {
  local -a args=()
  dw_user args -gid 888
  assert_equal "${args[*]}" "--user $(id -u):888"
}

@test "dw_user flags work in any order" {
  local -a args=()
  dw_user args -gid 888 -uid 777
  assert_equal "${args[*]}" "--user 777:888"
}

@test "dw_user rejects an unknown flag with exit 2" {
  local -a args=()
  run dw_user args -bogus 1
  assert_failure 2
}

#------------------------------------------------------------------------------
# dw_mount / dw_set_home

@test "dw_mount builds a read-write volume" {
  local -a args=()
  dw_mount args /src /dst
  assert_equal "${args[*]}" "--volume /src:/dst"
}

@test "dw_mount appends a non-empty mode" {
  local -a args=()
  dw_mount args /src /dst ro
  assert_equal "${args[*]}" "--volume /src:/dst:ro"
}

@test "dw_set_home adds a HOME env entry" {
  local -a args=()
  dw_set_home args /home/x
  assert_equal "${args[*]}" "--env HOME=/home/x"
}

#------------------------------------------------------------------------------
# dw_warn

@test "dw_warn writes one tagged line per argument to DW_LOG" {
  DW_LOG="$BATS_TEST_TMPDIR/log"
  DW_TAG="t: " dw_warn "one" "two"
  run cat "$DW_LOG"
  assert_line --index 0 "t: one"
  assert_line --index 1 "t: two"
}

@test "dw_warn splits embedded newlines into tagged lines" {
  DW_LOG="$BATS_TEST_TMPDIR/log"
  DW_TAG="t: " dw_warn "$(printf 'a\nb')"
  run cat "$DW_LOG"
  assert_line --index 0 "t: a"
  assert_line --index 1 "t: b"
}

@test "dw_warn with no arguments writes nothing" {
  DW_LOG="$BATS_TEST_TMPDIR/log"
  dw_warn
  assert_file_not_exist "$DW_LOG"
}

#------------------------------------------------------------------------------
# dw_die

@test "dw_die exits with the given numeric code and warns" {
  run dw_die 3 "boom"
  assert_failure 3
  assert_output --partial "boom"
}

@test "dw_die defaults to exit 1 when no numeric code is given" {
  run dw_die "just a message"
  assert_failure
  assert_equal "$status" 1
}

#------------------------------------------------------------------------------
# dw_require_host

@test "dw_require_host passes on the current host" {
  run dw_require_host "$(hostname -s)"
  assert_success
}

@test "dw_require_host dies on a mismatched host" {
  run dw_require_host not-this-host-ever
  assert_failure 1
  assert_output --partial "refusing to run"
}

#------------------------------------------------------------------------------
# dw_mount_workdir

# A git checkout for the top-level cases; the ceiling keeps git from finding
# any repository that happens to sit above the bats temp dir.
make_checkout() {
  export GIT_CEILING_DIRECTORIES
  GIT_CEILING_DIRECTORIES=$(dirname "$(realpath "$BATS_TEST_TMPDIR")")
  REPO=$(realpath "$BATS_TEST_TMPDIR")/repo
  mkdir -p "$REPO/sub"
  git init -q "$REPO"
}

@test "dw_mount_workdir mounts PWD at /mnt outside a git checkout" {
  export GIT_CEILING_DIRECTORIES
  GIT_CEILING_DIRECTORIES=$(dirname "$(realpath "$BATS_TEST_TMPDIR")")
  cd "$BATS_TEST_TMPDIR"
  local -a args=()
  dw_mount_workdir args
  assert_equal "${args[*]}" "--volume $(realpath .):/mnt --workdir /mnt"
}

@test "dw_mount_workdir mounts the checkout's top level and maps the workdir" {
  make_checkout
  cd "$REPO/sub"
  local -a args=()
  dw_mount_workdir args
  assert_equal "${args[*]}" "--volume $REPO:/mnt --workdir /mnt/sub"
  assert_equal "$DW_ROOT" "$REPO"
}

@test "dw_mount_workdir with DW_MOUNT=pwd mounts only PWD in a checkout" {
  make_checkout
  cd "$REPO/sub"
  local -a args=()
  DW_MOUNT='pwd' dw_mount_workdir args
  assert_equal "${args[*]}" "--volume $REPO/sub:/mnt --workdir /mnt"
}

@test "dw_mount_workdir allows a path elsewhere in the checkout" {
  make_checkout
  touch "$REPO/top.md"
  cd "$REPO/sub"
  local -a args=()
  run dw_mount_workdir args tool ../top.md
  assert_success
}

@test "dw_mount_workdir rejects a path outside the mounted root" {
  make_checkout
  cd "$REPO/sub"
  local -a args=()
  run dw_mount_workdir args tool /etc/passwd
  assert_failure
  assert_output --partial "not under the mounted directory"
}

@test "dw_mount_workdir rejects a path outside PWD when DW_MOUNT=pwd" {
  make_checkout
  touch "$REPO/top.md"
  cd "$REPO/sub"
  local -a args=()
  DW_MOUNT='pwd' run dw_mount_workdir args tool ../top.md
  assert_failure
  assert_output --partial "not under the mounted directory"
}

@test "dw_mount_workdir skips flag arguments" {
  cd "$BATS_TEST_TMPDIR"
  local -a args=()
  run dw_mount_workdir args tool -x
  assert_success
}

@test "dw_mount_workdir maps an absolute path under the root to /mnt in DW_ARGV" {
  make_checkout
  touch "$REPO/top.md"
  cd "$REPO/sub"
  local -a args=()
  dw_mount_workdir args tool "$REPO/top.md" ../top.md -x "$REPO/missing"
  assert_equal "${DW_ARGV[*]}" "/mnt/top.md ../top.md -x $REPO/missing"
}

@test "dw_mount_workdir maps an absolute path under PWD when DW_MOUNT=pwd" {
  make_checkout
  touch "$REPO/sub/f.md"
  cd "$REPO/sub"
  local -a args=()
  DW_MOUNT='pwd' dw_mount_workdir args tool "$REPO/sub/f.md"
  assert_equal "${DW_ARGV[*]}" "/mnt/f.md"
}

@test "dw_mount_workdir without a tool leaves DW_ARGV empty" {
  cd "$BATS_TEST_TMPDIR"
  local -a args=()
  DW_ARGV=(stale)
  dw_mount_workdir args
  assert_equal "${#DW_ARGV[@]}" 0
}

#------------------------------------------------------------------------------
# dw_tty_if_attached (no tty under bats -> no-op)

@test "dw_tty_if_attached is a no-op when not attached to a tty" {
  local -a args=()
  dw_tty_if_attached args
  assert_equal "${args[*]}" ""
}

#------------------------------------------------------------------------------
# dw_stdin_if_piped (stdin is not a tty under bats -> keeps stdin open)

@test "dw_stdin_if_piped adds --interactive when stdin is not a tty" {
  local -a args=()
  dw_stdin_if_piped args
  assert_equal "${args[*]}" "--interactive"
}
