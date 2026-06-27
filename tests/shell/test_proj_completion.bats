#!/usr/bin/env bats

# Tests for config/completions/proj — the _proj bash-completion function for the
# proj() wrapper. It completes directory names under $PROJECTS_DIR (with a
# trailing slash and nospace), including nested subdirectories, and yields
# nothing when $PROJECTS_DIR is unset or missing.
#
# The completion file is sourceable on its own (just defines _proj and registers
# it), so the tests source it directly and drive _proj by setting the bash
# completion variables (COMP_WORDS / COMP_CWORD), then assert on COMPREPLY.

load ../helpers/common

setup() {
  load_bats_libs
  source "$(dotfiles_root)/config/completions/proj"

  PROJECTS_DIR="$BATS_TEST_TMPDIR/projects"
  mkdir -p "$PROJECTS_DIR/alpha/sub1" "$PROJECTS_DIR/beta" "$PROJECTS_DIR/gamma"
  export PROJECTS_DIR
}

# Run _proj for a given current word and leave the result in COMPREPLY. _proj's
# return code is not its contract (COMPREPLY is) — it returns non-zero on its
# `[[ ... ]] || return` early-out — so tolerate it and assert on COMPREPLY.
complete_proj() {
  COMP_WORDS=(proj "$1")
  COMP_CWORD=1
  COMPREPLY=()
  _proj || true
}

@test "_proj completes all top-level projects for an empty word" {
  complete_proj ''
  # order is filesystem-dependent, so assert membership
  [[ " ${COMPREPLY[*]} " == *" alpha/ "* ]]
  [[ " ${COMPREPLY[*]} " == *" beta/ "* ]]
  [[ " ${COMPREPLY[*]} " == *" gamma/ "* ]]
}

@test "_proj completes a single project by prefix" {
  complete_proj 'al'
  assert_equal "${#COMPREPLY[@]}" 1
  assert_equal "${COMPREPLY[0]}" 'alpha/'
}

@test "_proj completes nested subdirectories" {
  complete_proj 'alpha/'
  assert_equal "${#COMPREPLY[@]}" 1
  assert_equal "${COMPREPLY[0]}" 'alpha/sub1/'
}

@test "_proj yields nothing when PROJECTS_DIR is unset" {
  unset PROJECTS_DIR
  complete_proj ''
  assert_equal "${#COMPREPLY[@]}" 0
}

@test "_proj yields nothing when PROJECTS_DIR points nowhere" {
  PROJECTS_DIR="$BATS_TEST_TMPDIR/does-not-exist"
  complete_proj ''
  assert_equal "${#COMPREPLY[@]}" 0
}
