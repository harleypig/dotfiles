#!/usr/bin/env bats

# Tests for bin/yesno — prompt for a Y/N answer, reprompting on invalid input.
# The chosen letter is printed (uppercased) to stdout; the prompt and the
# invalid-input warning go to stderr. Input is fed on stdin.

load ../helpers/common

setup() {
  load_bats_libs
  cd "$(dotfiles_root)" || return 1
}

@test "yesno returns Y for 'y'" {
  run bash -c 'printf y | bin/yesno 2> /dev/null'
  assert_success
  assert_output Y
}

@test "yesno returns N for 'n'" {
  run bash -c 'printf n | bin/yesno 2> /dev/null'
  assert_success
  assert_output N
}

@test "yesno reprompts past invalid input" {
  run bash -c 'printf xY | bin/yesno -q 2> /dev/null'
  assert_success
  assert_output Y
}

@test "yesno -h prints usage and exits 0" {
  run bin/yesno -h
  assert_success
  assert_output --partial 'Usage:'
}

@test "yesno rejects an unknown option (exit 2)" {
  run bin/yesno --bogus
  assert_failure 2
  assert_output --partial 'Unknown option'
}
