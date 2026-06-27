#!/usr/bin/env bats

# Tests for bin/showvars — list the variables assigned in a bash script (via
# `shfmt -tojson | jq`). Its success path needs the shfmt docker wrapper + jq,
# so it is integration-deferred; these tests cover only the three pure-bash
# GUARD paths, which die before any shfmt/jq call and so need no docker:
#   1. no args            → usage heredoc, exit 1
#   2. missing dependency → "depends on <tool>", exit 1 (shfmt/jq absent)
#   3. unreadable file    → "<file> is not readable.", exit 1

load ../helpers/common

SHOWVARS() { "$(dotfiles_root)/bin/showvars" "$@"; }

setup() {
  load_bats_libs
}

@test "showvars with no args prints usage and exits 1" {
  run SHOWVARS
  assert_failure 1
  assert_output --partial 'usage: showvars filename'
}

@test "showvars dies when a dependency (shfmt) is unavailable" {
  # Empty PATH → command_exists shfmt fails before the file loop.
  run env PATH="$(make_stub_dir)" "$(dotfiles_root)/bin/showvars" somefile
  assert_failure 1
  assert_output --partial 'depends on shfmt'
}

@test "showvars dies on an unreadable file once dependencies are present" {
  # Stub shfmt + jq so the dependency check passes; the unreadable-file guard
  # in _showvars then fires before either is actually invoked.
  local stub
  stub="$(make_stub_dir)"
  make_stub "$stub" shfmt
  make_stub "$stub" jq

  run env PATH="$stub:$PATH" "$(dotfiles_root)/bin/showvars" \
    "$BATS_TEST_TMPDIR/does-not-exist"
  assert_failure 1
  assert_output --partial 'is not readable.'
}
