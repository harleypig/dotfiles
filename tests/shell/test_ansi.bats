#!/usr/bin/env bats

# Tests for bin/ansi — emit tput/ANSI escape sequences, optionally wrapped in
# PS1 (-sb) or readline (-n) delimiters. The TERM-unset/incomplete-terminal
# path is covered by test_integration_context; here we check usage, the
# no-color fallback, sequence emission, and the prompt-delimiter wrapping.

load ../helpers/common

setup() {
  load_bats_libs
  ANSI="$(dotfiles_root)/bin/ansi"
}

@test "ansi with no arguments prints usage" {
  run "$ANSI"
  assert_success
  assert_output --partial 'Usage:'
}

@test "ansi -h prints usage" {
  run "$ANSI" -h
  assert_success
  assert_output --partial 'Usage:'
}

@test "ansi emits nothing under TERM=dumb (no colors)" {
  TERM=dumb run "$ANSI" fg red
  assert_success
  assert_output ''
}

@test "ansi emits an escape sequence for a color" {
  TERM=xterm run "$ANSI" fg red
  assert_success
  assert_output --partial $'\e['
}

@test "ansi -sb wraps the sequence in PS1 delimiters" {
  TERM=xterm run "$ANSI" -sb fg red
  assert_success
  assert_output --partial '\['
  assert_output --partial '\]'
}

@test "ansi accepts a hex color" {
  command -v bc > /dev/null || skip "bc not available (hex conversion needs it)"
  TERM=xterm run "$ANSI" fg '#ff5733'
  assert_success
  assert_output --partial $'\e['
}
