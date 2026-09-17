#!/usr/bin/env bats

# Tests for bin/parse_params's --prog option: it must set the prefix used by
# both error helpers (bail_input for bad input, def_err for a broken
# definition), not just the generated usage header. Regression for #353.

load ../helpers/common

setup() {
  load_bats_libs
  PP="$(dotfiles_root)/bin/parse_params"
}

@test "--prog sets the prefix on an input error (bail_input)" {
  run "$PP" --prog myprog 'x,string,x,,required'
  assert_failure 1
  assert_output --partial "myprog: x is required"
  refute_output --partial "parse_params:"
}

@test "--prog sets the prefix on a definition error (def_err)" {
  run "$PP" --prog myprog
  assert_failure 2
  assert_output --partial "myprog: definition error: no definition string given"
  refute_output --partial "parse_params:"
}

@test "without --prog, the error prefix falls back to parse_params" {
  run "$PP" 'x,string,x,,required'
  assert_failure 1
  assert_output --partial "parse_params: x is required"
}

@test "--prog also sets the prefix on the --auto input-error path" {
  run "$PP" --auto --prog myprog 'x,string,x,,required'
  assert_success
  assert_output --partial "myprog: x is required"
  assert_output --partial "exit 2"
}
