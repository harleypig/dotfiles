#!/usr/bin/env bats

# Tests for bin/hr — a horizontal-rule printer, and the worked example of
# driving bin/parse_params (options + a slurp positional) from a shell script.

load ../helpers/common

setup() {
  load_bats_libs
  # hr calls `parse_params`; make both resolvable from the repo's bin/.
  PATH="$(dotfiles_root)/bin:$PATH"
}

@test "hr defaults to a 40-char rule of '#' (non-tty)" {
  run hr
  assert_success
  assert_equal "${#output}" 40
  assert_output --regexp '^#+$'
}

@test "hr -l sets the length" {
  run hr -l 10
  assert_success
  assert_output '##########'
}

@test "hr -c sets the rule character" {
  run hr -c = -l 12
  assert_success
  assert_output '============'
}

@test "hr prints a title (slurp positional) then fills the rest" {
  run hr -l 30 My title
  assert_success
  assert_equal "${#output}" 30
  assert_output --regexp '^## My title #+$'
}

@test "hr combines -c and a title" {
  run hr -c = -l 20 Section
  assert_success
  assert_output --regexp '^== Section =+$'
}

@test "hr rejects a non-integer length (parse_params, exit 2)" {
  run hr -l abc
  assert_failure 2
  assert_output --partial 'is not a integer'
}

@test "hr rejects a non-positive length (exit 1)" {
  run hr -l 0
  assert_failure 1
  assert_output --partial 'greater than 0'
}

@test "hr rejects a multi-char rule character (parse_params, exit 2)" {
  run hr -c xx
  assert_failure 2
  assert_output --partial 'is not a char'
}

@test "hr --help prints usage and exits 0" {
  run hr --help
  assert_success
  assert_output --partial 'Usage: hr'
}
