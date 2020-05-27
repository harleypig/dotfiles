#!/usr/bin/env bats

#------------------------------------------------------------------------------
@test 'utility no source' {
  run "$DOTFILES/lib/Is"
  assert_failure
  assert_output 'utility must only be sourced'
}
