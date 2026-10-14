#!/usr/bin/env bats

# Loads config/tmux/tmux.conf into a real, throwaway tmux server. A parse
# error anywhere in the file makes tmux skip the whole file silently at
# startup, so "the server came up" proves nothing; each test reads back
# something the file sets.
#
# TMUX_TMPDIR puts the server socket under the test's own tmpdir, so no
# server or socket outlives the test, and a live tmux session is untouched.

load ../helpers/common

setup() {
  load_bats_libs

  command -v tmux > /dev/null || skip "tmux not installed"

  # A Unix socket path is capped near 104 bytes, and tmux appends about 20
  # (tmux-UID/conftest); past that every test dies on "File name too long".
  ((${#BATS_TEST_TMPDIR} < 80)) || skip "BATS_TEST_TMPDIR too long for a tmux socket"

  CONF="$(dotfiles_root)/config/tmux/tmux.conf"

  export TMUX_TMPDIR=$BATS_TEST_TMPDIR
  export XDG_CONFIG_HOME
  XDG_CONFIG_HOME="$(dotfiles_root)/config"
  unset TMUX
}

teardown() {
  tmux -L conftest kill-server 2> /dev/null || true
}

# Start a detached server on the config under test.
start_server() {
  run tmux -L conftest -f "$CONF" new-session -d
  assert_success
  assert_output ''
}

@test "tmux.conf parses without errors" {
  run tmux -L conftest -f /dev/null new-session -d \; source-file "$CONF"
  assert_success
  assert_output ''
}

@test "tmux.conf is applied at server start, not skipped" {
  start_server

  run tmux -L conftest show -gv status-justify
  assert_output 'centre'

  run tmux -L conftest show -sv set-clipboard
  assert_output 'on'
}

@test "prefix r reloads the config file, not an empty path" {
  start_server

  run tmux -L conftest list-keys -T prefix r
  assert_output --partial "source-file $CONF "
}
