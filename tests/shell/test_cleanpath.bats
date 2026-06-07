#!/usr/bin/env bats

# Tests for bin/cleanpath — cleans a colon-separated path variable: drops
# duplicate and nonexistent directories, and honours the colon-separated
# control variables SHOULD_BE_FIRST / SHOULD_BE_LAST / SHOULD_BE_IGNORED /
# SHOULD_BE_STRIPPED (see the script header).

load ../helpers/common

setup() {
  load_bats_libs
  cd "$(dotfiles_root)" || return 1
}

@test "cleanpath de-duplicates and drops nonexistent dirs" {
  TESTV="/usr/bin:/usr/bin:/nonexistent-xyz:/etc:/etc" run bin/cleanpath TESTV
  assert_success
  assert_output "/usr/bin:/etc"
}

@test "cleanpath honours SHOULD_BE_FIRST and SHOULD_BE_LAST" {
  TESTV="/usr/bin:/etc:/tmp" SHOULD_BE_FIRST="/tmp" SHOULD_BE_LAST="/usr/bin" \
    run bin/cleanpath TESTV
  assert_success
  assert_output "/tmp:/etc:/usr/bin"
}

@test "cleanpath removes SHOULD_BE_STRIPPED entries" {
  TESTV="/usr/bin:/etc:/tmp" SHOULD_BE_STRIPPED="/etc" run bin/cleanpath TESTV
  assert_success
  assert_output "/usr/bin:/tmp"
}

@test "cleanpath keeps SHOULD_BE_IGNORED entries verbatim" {
  TESTV="/usr/bin:/nonexistent-ig" SHOULD_BE_IGNORED="/nonexistent-ig" \
    run bin/cleanpath TESTV
  assert_success
  assert_output "/usr/bin:/nonexistent-ig"
}

@test "cleanpath drops '.' and blank entries" {
  TESTV="/usr/bin:.::/etc" run bin/cleanpath TESTV
  assert_success
  assert_output "/usr/bin:/etc"
}

@test "cleanpath fails with no argument" {
  run bin/cleanpath
  assert_failure
  assert_output --partial "No environment variable name"
}

@test "cleanpath fails when the named variable does not exist" {
  run bin/cleanpath DEFINITELY_NOT_SET_XYZ
  assert_failure
  assert_output --partial "does not exist"
}
