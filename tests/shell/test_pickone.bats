#!/usr/bin/env bats

# Tests for bin/pickone — pick one option from a numbered menu. The chosen
# option is printed to stdout; the menu, prompt, and warnings go to stderr.
# Input is fed on stdin.

load ../helpers/common

setup() {
  load_bats_libs
  cd "$(dotfiles_root)" || return 1
}

@test "pickone prints the option matching the number entered" {
  run bash -c 'printf "2\n" | bin/pickone red green blue 2> /dev/null'
  assert_success
  assert_output green
}

@test "pickone keeps an option containing spaces intact" {
  run bash -c 'printf "1\n" | bin/pickone "new session" attach 2> /dev/null'
  assert_success
  assert_output 'new session'
}

@test "pickone reprompts past non-numeric and out-of-range input" {
  run bash -c 'printf "x\n0\n4\n3\n" | bin/pickone red green blue 2> /dev/null'
  assert_success
  assert_output blue
}

@test "pickone warns on invalid input" {
  run bash -c 'printf "x\n1\n" | bin/pickone red green 2>&1 > /dev/null'
  assert_output --partial 'Please enter a number from 1 to 2'
}

@test "pickone -q suppresses the invalid-input warning" {
  run bash -c 'printf "x\n1\n" | bin/pickone -q red green 2>&1 > /dev/null'
  refute_output --partial 'Please enter'
}

@test "pickone lists the options numbered on stderr" {
  run bash -c 'printf "1\n" | bin/pickone red green 2>&1 > /dev/null'
  assert_output --partial ' 1) red'
  assert_output --partial ' 2) green'
}

@test "pickone -d chooses the default on empty input and marks it" {
  run bash -c 'printf "\n" | bin/pickone -d green red green blue 2> /dev/null'
  assert_success
  assert_output green

  run bash -c 'printf "\n" | bin/pickone -d green red green 2>&1 > /dev/null'
  assert_output --partial '* 2) green'
}

@test "pickone reprompts on empty input when there is no default" {
  run bash -c 'printf "\n1\n" | bin/pickone -q red green 2> /dev/null'
  assert_success
  assert_output red
}

@test "pickone exits 1 when input ends before a choice" {
  run bash -c 'printf "x\n" | bin/pickone -q red green 2> /dev/null'
  assert_failure 1
  assert_output ''
}

@test "pickone rejects a default that is not an option (exit 2)" {
  run bin/pickone -d purple red green < /dev/null
  assert_failure 2
  assert_output --partial 'Default is not one of the options'
}

@test "pickone with no options is a usage error (exit 2)" {
  run bin/pickone < /dev/null
  assert_failure 2
  assert_output --partial 'Usage:'
}

@test "pickone rejects an option flag missing its value (exit 2)" {
  run bin/pickone -d
  assert_failure 2
  assert_output --partial 'needs a value'
}

@test "pickone -h prints usage and exits 0" {
  run bin/pickone -h
  assert_success
  assert_output --partial 'Usage:'
}

@test "pickone rejects an unknown option (exit 2)" {
  run bin/pickone --bogus red
  assert_failure 2
  assert_output --partial 'Unknown option'
}
