#!/usr/bin/env bats

# Tests for bin/dir-readable — print $PWD (colored by writability via ansi),
# left-truncated with a marker past DIR_PWD_MAX. TERM=dumb so ansi emits no
# color, making the path text deterministic.

load ../helpers/common

setup() {
  load_bats_libs
  PATH="$(dotfiles_root)/bin:$PATH"   # dir-readable calls ansi
  export TERM=dumb
}

@test "dir-readable prints the full path when under the max" {
  cd "$BATS_TEST_TMPDIR"
  DIR_PWD_MAX=500 run dir-readable
  assert_success
  assert_output --partial "$PWD"
}

@test "dir-readable left-truncates a long path with the marker" {
  mkdir -p "$BATS_TEST_TMPDIR/aaaaaaaaaa/bbbbbbbbbb/cccccccccc"
  cd "$BATS_TEST_TMPDIR/aaaaaaaaaa/bbbbbbbbbb/cccccccccc"
  DIR_PWD_MAX=10 DIR_PWD_TRUNC='<' run dir-readable
  assert_success
  assert_output --partial "<${PWD: -10}"
  refute_output --partial 'aaaaaaaaaa'   # the truncated-away head is gone
}

# The writable/non-writable branch differs only by which ansi color is emitted,
# which TERM=dumb (above) suppresses. To observe the branch, these two tests
# stub `ansi` to echo its arguments, so 'fg green' / 'fg red' appear verbatim.

@test "dir-readable colors a writable directory green" {
  [[ $EUID -eq 0 ]] && skip "root bypasses the -w writability check"
  local stub
  stub="$(make_stub_dir)"
  make_script_stub "$stub" ansi 'echo -n "[ansi:$*]"'

  local dir="$BATS_TEST_TMPDIR/rw"
  mkdir -p "$dir"
  cd "$dir"
  DIR_PWD_MAX=500 run env PATH="$stub:$PATH" dir-readable
  assert_success
  assert_output --partial 'fg green'
}

@test "dir-readable colors a non-writable directory red" {
  [[ $EUID -eq 0 ]] && skip "root bypasses the -w writability check"
  local stub
  stub="$(make_stub_dir)"
  make_script_stub "$stub" ansi 'echo -n "[ansi:$*]"'

  local dir="$BATS_TEST_TMPDIR/ro"
  mkdir -p "$dir"
  chmod 555 "$dir"
  cd "$dir"
  DIR_PWD_MAX=500 run env PATH="$stub:$PATH" dir-readable
  assert_success
  assert_output --partial 'fg red'
}
