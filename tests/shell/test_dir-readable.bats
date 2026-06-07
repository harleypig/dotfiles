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
