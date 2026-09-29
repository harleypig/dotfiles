#!/usr/bin/env bats

# Tests for bin/run-help — help for a command word, bound to Alt+h in
# config/shell-startup/010-general. The word arrives as $1 because bash never
# exports READLINE_LINE to a child process. `man` is stubbed so no pager runs.

load ../helpers/common

setup() {
  load_bats_libs

  STUB=$(make_stub_dir)
  make_stub "$STUB" man
  PATH="$STUB:$(dotfiles_root)/bin:$PATH"
}

teardown() {
  rm -rf "$STUB"
}

@test "run-help shows builtin help for a bash builtin, without man" {
  run run-help cd
  assert_success
  assert_output --partial 'cd: cd'
  # `help ""` matches every builtin, so a dropped word would still show cd.
  refute_output --partial 'pwd: pwd'
  assert_file_not_exists "$STUB/man.args"
}

@test "run-help falls back to man for a non-builtin" {
  run run-help ls
  assert_success
  assert_equal "$(cat "$STUB/man.args")" 'ls'
}

@test "run-help ignores an inherited READLINE_LINE and uses \$1" {
  READLINE_LINE='cd /tmp' run run-help ls
  assert_success
  assert_equal "$(cat "$STUB/man.args")" 'ls'
}

@test "run-help passes man's failure through" {
  make_stub "$STUB" man 16
  run run-help no-such-command-xyz
  assert_failure 16
}

@test "run-help with no word is a usage error" {
  run run-help
  assert_failure 2
  assert_output --partial 'usage: run-help'
  assert_file_not_exists "$STUB/man.args"
}
