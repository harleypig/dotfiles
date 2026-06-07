#!/usr/bin/env bats

# Tests for bin/proj — print the path to cd into ($PROJECTS_DIR or
# $PROJECTS_DIR/<name>); for a missing name, offer a select menu to create it,
# go to $PROJECTS_DIR, or cancel. (It only prints a path; the proj() shell
# wrapper does the cd.)

load ../helpers/common

setup() {
  load_bats_libs
  PROJ="$(dotfiles_root)/bin/proj"
  export PROJECTS_DIR="$BATS_TEST_TMPDIR/projects"
  mkdir -p "$PROJECTS_DIR"
}

@test "no argument prints PROJECTS_DIR" {
  run "$PROJ"
  assert_success
  assert_output "$PROJECTS_DIR"
}

@test "an existing project prints its path" {
  mkdir -p "$PROJECTS_DIR/foo"
  run "$PROJ" foo
  assert_success
  assert_output "$PROJECTS_DIR/foo"
}

@test "-h prints usage and exits 0" {
  run "$PROJ" -h
  assert_success
  assert_output --partial 'Usage: proj'
}

@test "an unknown option exits 2" {
  run "$PROJ" --bogus
  assert_failure 2
  assert_output --partial 'Unknown option'
}

@test "more than one argument exits 2" {
  run "$PROJ" a b
  assert_failure 2
  assert_output --partial 'Usage'
}

@test "unset PROJECTS_DIR errors" {
  run env -u PROJECTS_DIR "$PROJ"
  assert_failure 1
  assert_output --partial 'PROJECTS_DIR is not set'
}

@test "missing project: select 'create' makes and prints it" {
  run "$PROJ" newproj <<< '1'
  assert_success
  assert_output --partial "$PROJECTS_DIR/newproj"
  assert_dir_exists "$PROJECTS_DIR/newproj"
}

@test "missing project: select 'cancel' exits 1 without creating" {
  run "$PROJ" nope <<< '3'
  assert_failure 1
  run [ -d "$PROJECTS_DIR/nope" ]
  assert_failure
}
