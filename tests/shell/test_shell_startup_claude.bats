#!/usr/bin/env bats

# config/shell-startup/claude moves the agent harness's temp dir under
# ~/.cache on harleypig.com only (#596 - temp dir off /tmp), and points
# TMPDIR at it inside an agent session. The module is sourced in a fresh bash
# child with a throwaway HOME and an overridden HOSTNAME, so the real ~/.cache
# is never touched.

load ../helpers/common

setup() {
  load_bats_libs

  ROOT="$(dotfiles_root)"
  T="$BATS_TEST_TMPDIR"
  mkdir -p "$T/home"
}

# Source the module as host $1, with CLAUDECODE set to $2 when given, and
# print the resulting temp-dir variables. The ambient values are cleared
# first: run from an agent session, they would otherwise leak into the child.
run_module() {
  run bash --norc -c '
    root=$1 home=$2 host=$3

    unset CLAUDE_CODE_TMPDIR TMPDIR CLAUDECODE
    HOME=$home HOSTNAME=$host
    [[ -n $4 ]] && export CLAUDECODE=$4
    havecmd() { true; }

    source "$root/config/shell-startup/claude"

    echo "TMPDIR_VAR=${CLAUDE_CODE_TMPDIR-unset}"
    echo "TMPDIR=${TMPDIR-unset}"
  ' _ "$ROOT" "$T/home" "$1" "${2-}"
}

@test "harleypig.com: temp dir is set under ~/.cache and created" {
  run_module harleypig.com

  assert_success
  assert_line "TMPDIR_VAR=$T/home/.cache/claude-tmp"
  assert_dir_exists "$T/home/.cache/claude-tmp"
}

@test "harleypig.com: an existing temp dir is reused without error" {
  mkdir -p "$T/home/.cache/claude-tmp"

  run_module harleypig.com

  assert_success
  assert_line "TMPDIR_VAR=$T/home/.cache/claude-tmp"
}

@test "other host: temp dir is not set and nothing is created" {
  run_module otherhost.example

  assert_success
  assert_line "TMPDIR_VAR=unset"
  assert_not_exists "$T/home/.cache"
}

# Match the whole name: a host that merely contains it is another host.
@test "other host: a hostname containing harleypig.com does not match" {
  run_module dev.harleypig.com

  assert_success
  assert_line "TMPDIR_VAR=unset"
}

@test "harleypig.com in an agent session: TMPDIR is the agent temp dir" {
  run_module harleypig.com 1

  assert_success
  assert_line "TMPDIR=$T/home/.cache/claude-tmp"
}

@test "harleypig.com outside an agent session: TMPDIR is left unset" {
  run_module harleypig.com

  assert_success
  assert_line "TMPDIR_VAR=$T/home/.cache/claude-tmp"
  assert_line "TMPDIR=unset"
}

@test "other host in an agent session: TMPDIR is left unset" {
  run_module otherhost.example 1

  assert_success
  assert_line "TMPDIR=unset"
}
