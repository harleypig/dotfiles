#!/usr/bin/env bats

# Tests for the bats-toolbox helper library — also proves it loads as a
# first-class lib via bats_load_library (BATS_LIB_PATH includes lib/bats).

load ../helpers/common

setup() {
  load_bats_libs
}

@test "random_string defaults to 32 alphanumeric characters" {
  run random_string
  assert_success
  assert_equal "${#output}" 32
  assert_output --regexp '^[a-zA-Z0-9]+$'
}

@test "random_string alpha respects length and class" {
  run random_string alpha 12
  assert_equal "${#output}" 12
  assert_output --regexp '^[a-zA-Z]+$'
}

@test "random_string numeric respects length and class" {
  run random_string numeric 6
  assert_equal "${#output}" 6
  assert_output --regexp '^[0-9]+$'
}

@test "setup_temp_dir / cleanup_temp_dir create and remove a workspace" {
  setup_temp_dir
  assert_dir_exists "$TEST_TEMP_DIR"
  local saved="$TEST_TEMP_DIR"
  cleanup_temp_dir
  assert_not_exists "$saved"
  assert_equal "${TEST_TEMP_DIR-unset}" "unset"
}
