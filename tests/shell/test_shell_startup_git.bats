#!/usr/bin/env bats

# Tests for config/shell-startup/git's repo-navigation helpers:
#   gtoplevel — echo the repo toplevel, or fail with a message outside a repo
#   gtl       — cd to the toplevel (used interactively)
#
# Named test_shell_startup_git to avoid confusion with the bin/git-* tests
# (test_git-status, test_git-all, test_git-branch-clean), which cover separate
# executables. The two functions are extracted from the module and eval'd in
# isolation — the module also defines ~9 other thin git aliases not worth
# unit-testing. Same in-isolation approach as test_havecmd.

load ../helpers/common

setup() {
  load_bats_libs
  # Eval just gtoplevel + gtl out of the module (it also defines ~9 thin git
  # aliases and sets config we don't want sourced here).
  eval "$(source_funcs "$(dotfiles_root)/config/shell-startup/git" gtoplevel gtl)"

  REPO="$BATS_TEST_TMPDIR/sample"
  make_test_repo "$REPO"
}

@test "gtoplevel prints the toplevel inside a repo" {
  cd "$REPO"
  run gtoplevel
  assert_success
  assert_output "$(cd "$REPO" && git rev-parse --show-toplevel)"
}

@test "gtoplevel fails with a message outside a repo" {
  cd "$BATS_TEST_TMPDIR"
  run gtoplevel
  assert_failure
  assert_output --partial 'Not in a git repository.'
}

@test "gtl cd's to the repo toplevel from a subdirectory" {
  mkdir -p "$REPO/sub/dir"
  cd "$REPO/sub/dir"

  local top
  top=$(git rev-parse --show-toplevel)
  gtl

  assert_equal "$PWD" "$top"
}

@test "gtl fails outside a repo" {
  cd "$BATS_TEST_TMPDIR"
  run gtl
  assert_failure
}
