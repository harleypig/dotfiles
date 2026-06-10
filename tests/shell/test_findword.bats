#!/usr/bin/env bats

# Tests for bin/findword — a Wordle solver/cheat that builds a per-position
# character-class regex from its flags, greps the dictionary, and ranks the
# matches by vowel richness.
#
# The script reads the real /usr/share/dict/words. Rather than assert exact
# words (which depend on the installed wordlist), the result tests check
# structural invariants — length, allowed letters, position constraints — over
# whatever matched. They skip when no dictionary is installed.

load ../helpers/common

setup() {
  load_bats_libs
  # findword calls `parse_params`; make both resolvable from the repo's bin/.
  PATH="$(dotfiles_root)/bin:$PATH"
}

# Skip a result-producing test when the dictionary the script needs is absent.
require_dict() {
  [[ -r /usr/share/dict/words ]] || skip "no /usr/share/dict/words installed"
}

@test "every result is a 5-letter word by default" {
  require_dict
  run findword --pos1 z
  assert_success
  for w in $output; do
    assert_equal "${#w}" 5
  done
}

@test "--pos1 pins the first letter" {
  require_dict
  run findword --pos1 q
  assert_success
  [[ -n $output ]]
  for w in $output; do
    assert_equal "${w:0:1}" q
  done
}

@test "--exclude removes words containing any excluded letter" {
  require_dict
  run findword --pos1 a --exclude eiou
  assert_success
  for w in $output; do
    assert_equal "$w" "${w//[eiou]/}"
  done
}

@test "--include requires every included letter to be present" {
  require_dict
  run findword --pos1 a --include z
  assert_success
  [[ -n $output ]]
  for w in $output; do
    assert_output --regexp "$w" # token is in output
    [[ $w == *z* ]] || fail "word '$w' lacks required letter z"
  done
}

@test "--not_posN forbids letters at that position only" {
  require_dict
  run findword --pos1 a --not_pos2 b
  assert_success
  for w in $output; do
    assert [ "${w:1:1}" != b ]
  done
}

@test "--posN overrides --exclude for that position" {
  require_dict
  # 'a' is globally excluded yet pinned at position 1: it must still appear
  # there (and nowhere else, since it is excluded elsewhere).
  run findword --pos1 a --exclude a
  assert_success
  [[ -n $output ]]
  for w in $output; do
    assert_equal "${w:0:1}" a
    [[ ${w:1} != *a* ]] || fail "word '$w' has 'a' after the pinned position"
  done
}

@test "a longer --length generates the matching --posN flags" {
  require_dict
  run findword --length 7 --pos1 a
  assert_success
  for w in $output; do
    assert_equal "${#w}" 7
  done
}

@test "an out-of-range --posN is an unknown option (parse_params, exit 2)" {
  run findword --pos6 e
  assert_failure 2
  assert_output --partial 'Unknown option: pos6'
}

@test "a non-integer length is rejected (parse_params, exit 2)" {
  run findword --length abc
  assert_failure 2
  assert_output --partial 'is not a integer'
}

@test "a non-positive length is rejected (exit 1)" {
  run findword --length 0
  assert_failure 1
  assert_output --partial 'greater than 0'
}

@test "contradictory constraints yield no matches and exit 0" {
  run findword --length 1 --exclude abcdefghijklmnopqrstuvwxyz
  assert_success
  assert_output ''
}

@test "--help prints usage and exits 0" {
  run findword --help
  assert_success
  assert_output --partial 'Usage: findword'
}
