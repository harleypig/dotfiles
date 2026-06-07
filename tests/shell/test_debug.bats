#!/usr/bin/env bats

# Tests for lib/debug — a sourced library providing sourced() and debug().
# It refuses to be executed; debug() is a no-op unless $DEBUG is truthy,
# otherwise it writes each message to stderr prefixed with an
# interactive/login + call-stack tag.

load ../helpers/common

setup() {
  load_bats_libs
  # shellcheck disable=SC1090  # path resolved at runtime via dotfiles_root
  source "$(dotfiles_root)/lib/debug"
}

@test "lib/debug refuses to be executed" {
  run bash "$(dotfiles_root)/lib/debug"
  assert_failure
  assert_output --partial 'must only be sourced'
}

@test "sourcing lib/debug defines sourced() and debug()" {
  assert_equal "$(type -t sourced)" function
  assert_equal "$(type -t debug)" function
}

@test "debug is silent unless DEBUG is set" {
  DEBUG='' run debug "should not appear"
  assert_success
  assert_output ''
}

@test "debug prints the message (after a [...] prefix) when DEBUG is set" {
  DEBUG=1 run debug "hello world"
  assert_success
  assert_output --partial '] hello world'
}

@test "debug prints one prefixed line per argument" {
  DEBUG=1 run debug "first" "second"
  assert_success
  assert_equal "${#lines[@]}" 2
  assert_line --partial 'first'
  assert_line --partial 'second'
}

@test "debug reads the message from stdin" {
  # shellcheck disable=SC2016  # $1 is for the inner bash -c, not this shell
  run bash -c 'source "$1/lib/debug"; echo piped | DEBUG=1 debug' _ \
    "$(dotfiles_root)"
  assert_success
  assert_output --partial 'piped'
}
