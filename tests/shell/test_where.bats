#!/usr/bin/env bats

# Tests for bin/where — classify how each command name resolves
# (keyword / builtin / file+path / not found). The function and alias paths
# need a live shell environment and aren't exercised here.

load ../helpers/common

setup() {
  load_bats_libs
  WHERE="$(dotfiles_root)/bin/where"
}

@test "where reports a shell keyword" {
  run "$WHERE" if
  assert_success
  assert_output --partial 'if:keyword'
}

@test "where reports a builtin" {
  run "$WHERE" cd
  assert_output --partial 'cd:builtin'
}

@test "where reports a file command with its path" {
  run "$WHERE" ls
  assert_output --regexp '^ls:file:/'
}

@test "where reports a missing command" {
  run "$WHERE" __no_such_cmd_xyz__
  assert_output --partial 'is not found'
}

@test "where handles several commands at once" {
  run "$WHERE" if cd
  assert_output --partial 'if:keyword'
  assert_output --partial 'cd:builtin'
}
