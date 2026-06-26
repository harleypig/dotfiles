#!/usr/bin/env bats

# Tests for shell-startup's run_hook(). run_hook is preserved in the
# orchestrator for possible future use but is currently COMMENTED OUT and
# called nowhere, so these tests are skipped (see the skip in setup below).
# To run them: uncomment run_hook in shell-startup and remove the skip.
#
# run_hook lives inside the shell-startup orchestrator (not independently
# sourceable), so the tests extract just its definition from the file and
# eval it in isolation rather than running the whole orchestrator.

load ../helpers/common

# Extract run_hook's definition from shell-startup so the real body can be
# eval'd and exercised in isolation.
extract_run_hook() {
  awk '
    /^run_hook\(\)[[:space:]]*\{/ { capture = 1 }
    capture { print }
    capture && /^\}/ { capture = 0 }
  ' "$(dotfiles_root)/shell-startup"
}

setup() {
  # Load libs first so teardown's cleanup_temp_dir is defined even when the
  # skip below short-circuits the rest of setup.
  load_bats_libs

  skip "run_hook is commented out in shell-startup (preserved for future use)"

  # run_hook calls debug(); stub it as a quiet no-op for these tests.
  # shellcheck disable=SC2329  # invoked indirectly by the eval'd run_hook
  debug() { :; }

  eval "$(extract_run_hook)"

  setup_temp_dir
}

teardown() {
  cleanup_temp_dir
}

@test 'run_hook runs a readable hook from a custom $dfdir and returns 0' {
  printf 'touch "%s/ran"\n' "$TEST_TEMP_DIR" > "$TEST_TEMP_DIR/myhook"

  dfdir="$TEST_TEMP_DIR" run run_hook myhook

  assert_success
  assert_file_exist "$TEST_TEMP_DIR/ran"
}

@test 'run_hook falls back to $DOTFILES/shell_startup_hooks.d when $dfdir unset' {
  mkdir -p "$TEST_TEMP_DIR/shell_startup_hooks.d"
  printf 'touch "%s/ran"\n' "$TEST_TEMP_DIR" \
    > "$TEST_TEMP_DIR/shell_startup_hooks.d/deflt"

  unset dfdir
  DOTFILES="$TEST_TEMP_DIR" run run_hook deflt

  assert_success
  assert_file_exist "$TEST_TEMP_DIR/ran"
}

@test "run_hook returns non-zero for a missing hook" {
  dfdir="$TEST_TEMP_DIR" run run_hook does-not-exist

  assert_failure
}

@test "run_hook returns non-zero when the hook itself fails" {
  printf 'return 1\n' > "$TEST_TEMP_DIR/bad"

  dfdir="$TEST_TEMP_DIR" run run_hook bad

  assert_failure
}
