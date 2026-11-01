#!/usr/bin/env bats

# Tests for bin/loadavg — the 15 minute load average for the bash prompt,
# printed only when it is above one load per CPU. Load averages come from
# fixture files passed as the argument and the CPU count from an nproc stub;
# ansi is stubbed to emit recognizable markers so the colours are assertable.
# The thresholds themselves are tested against lib/loadavg in
# test_lib_loadavg.bats.

load ../helpers/common

setup() {
  load_bats_libs

  LOADAVG="$BATS_TEST_TMPDIR/loadavg"

  STUB="$(make_stub_dir)"
  make_script_stub "$STUB" nproc 'echo 2'
  make_script_stub "$STUB" ansi 'printf "[ansi:%s]" "$*"'

  PATH="$STUB:$(dotfiles_root)/bin:$PATH"
}

teardown() {
  rm -rf "$STUB"
}

fixture() {
  printf '%s\n' "$1" > "$LOADAVG"
}

@test "more than one argument is a usage error" {
  run loadavg a b
  assert_failure 2
  assert_output --partial 'Usage:'
}

@test "loadavg prints nothing when the 15 minute load is at or under one per CPU" {
  fixture '9.00 9.00 2.00 1/123 4567'

  run loadavg "$LOADAVG"
  assert_success
  assert_output ''
}

@test "loadavg prints yellow when the 15 minute load is over one per CPU" {
  fixture '0.10 0.10 2.01 1/123 4567'

  run loadavg "$LOADAVG"
  assert_success
  assert_output '[ansi:-n fg yellow]Load Avg: 2.01[ansi:-n off]'
}

@test "loadavg prints yellow on red when the 15 minute load is over two per CPU" {
  fixture '0.10 0.10 4.01 1/123 4567'

  run loadavg "$LOADAVG"
  assert_success
  assert_output '[ansi:-n fg yellow bg red]Load Avg: 4.01[ansi:-n off]'
}

@test "loadavg prints nothing for a missing file" {
  run loadavg "$BATS_TEST_TMPDIR/absent"
  assert_success
  assert_output ''
}

@test "loadavg prints nothing for a file that does not parse" {
  fixture 'not a load average'

  run loadavg "$LOADAVG"
  assert_success
  assert_output ''
}
