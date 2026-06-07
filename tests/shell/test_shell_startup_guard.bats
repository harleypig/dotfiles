#!/usr/bin/env bats

# Tests shell-startup's double-source guard. Both ~/.bash_profile and
# ~/.bashrc are symlinked to shell-startup, so a shell that reads both would
# run startup twice. A non-exported _DOTFILES_STARTUP_DONE flag makes a second
# source in the same shell a no-op (child shells, not inheriting the flag,
# still run their own startup).
#
# Tested hermetically: extract just the guard lines and source those (no full
# orchestrator run), so the test is fast and CI-portable.

load ../helpers/common

# The guard lines from shell-startup (both mention _DOTFILES_STARTUP_DONE).
extract_guard() {
  awk '/_DOTFILES_STARTUP_DONE/ { print }' "$(dotfiles_root)/shell-startup"
}

setup() {
  load_bats_libs
  setup_temp_dir
  unset _DOTFILES_STARTUP_DONE
}

teardown() {
  cleanup_temp_dir
}

@test "shell-startup defines the double-source guard" {
  run extract_guard
  assert_success
  assert_output --partial '_DOTFILES_STARTUP_DONE'
  assert_line --index 0 --partial 'return 0'
}

@test "a second source is a no-op in the same shell (guard short-circuits)" {
  local probe="$TEST_TEMP_DIR/probe"
  {
    extract_guard
    printf 'echo ran >> %q\n' "$TEST_TEMP_DIR/marker"
  } > "$probe"

  # shellcheck disable=SC1090  # probe path is built at runtime
  source "$probe"
  # shellcheck disable=SC1090
  source "$probe"

  assert_equal "$(wc -l < "$TEST_TEMP_DIR/marker")" 1
}

@test "the guard flag is not exported (child shells run their own startup)" {
  _DOTFILES_STARTUP_DONE=1
  run bash -c 'echo "${_DOTFILES_STARTUP_DONE-unset}"'
  assert_output 'unset'
}
