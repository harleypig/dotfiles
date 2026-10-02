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

@test "cleanpath drops an entry whose '..' climbs out of a missing dir" {
  # Lexical resolution (realpath -m) would keep this as /usr/bin; the kernel
  # refuses to walk through the missing dir, so it must be dropped.
  TESTV="/nonexistent-xyz/../usr/bin:/etc" run bin/cleanpath TESTV
  assert_success
  assert_output "/etc"
}

@test "cleanpath drops a dangling symlink" {
  local dir
  dir=$(mktemp -d)
  ln -s "$dir/gone" "$dir/dangling"

  TESTV="$dir/dangling:/etc" run bin/cleanpath TESTV
  rm -rf "$dir"
  assert_success
  assert_output "/etc"
}

@test "cleanpath sends only /mnt/* entries to the parallel resolver" {
  local dir
  dir=$(mktemp -d)

  # A pass-through xargs that logs what it is fed, so the WSL routing can be
  # seen without a real /mnt drive.
  # shellcheck disable=SC2016  # expanded when the stub runs, not here
  make_script_stub "$dir" xargs '
mapfile -d "" -t in
((${#in[@]})) || exec "$REAL_XARGS" "$@" < /dev/null
printf "%s\n" "${in[@]}" >> "$XARGS_LOG"
printf "%s\0" "${in[@]}" | "$REAL_XARGS" "$@"'

  REAL_XARGS=$(command -v xargs) XARGS_LOG="$dir/xargs.in" PATH="$dir:$PATH" \
    TESTV="/mnt/c/nope-xyz:/usr/bin:/etc" run bin/cleanpath TESTV
  assert_success
  assert_output "/usr/bin:/etc"

  run cat "$dir/xargs.in"
  rm -rf "$dir"
  assert_output "/mnt/c/nope-xyz"
}
