#!/usr/bin/env bats

# Tests for config/docker/code-tools/run-tools — the batched runner baked into
# the code-tools image (ADR-0006). It just runs the commands it is given, so it
# runs on the host directly here; no docker/image is needed.

load ../helpers/common

setup() {
  load_bats_libs
  RUN_TOOLS="$(dotfiles_root)/config/docker/code-tools/run-tools"
}

@test "run-tools runs a single invocation and passes its status" {
  run "$RUN_TOOLS" true
  assert_success

  run "$RUN_TOOLS" false
  assert_failure 1
}

@test "run-tools runs every --separated invocation" {
  run "$RUN_TOOLS" echo one -- echo two
  assert_success
  assert_line "one"
  assert_line "two"
}

@test "run-tools fails if ANY invocation fails, but still runs them all" {
  # false in the middle; the echo after it must still run (no short-circuit),
  # so one pass reports every tool's output.
  run "$RUN_TOOLS" echo before -- false -- echo after
  assert_failure 1
  assert_line "before"
  assert_line "after"
}

@test "run-tools tolerates empty groups (doubled / trailing --)" {
  run "$RUN_TOOLS" echo hi -- -- echo bye --
  assert_success
  assert_line "hi"
  assert_line "bye"
}

@test "run-tools with no invocation is a usage error (exit 2)" {
  run "$RUN_TOOLS"
  assert_failure 2
  assert_output --partial "no invocation"
}

@test "run-tools --help prints usage and exits 0" {
  run "$RUN_TOOLS" --help
  assert_success
  assert_output --partial "Usage:"
}
