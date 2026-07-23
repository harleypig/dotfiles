#!/usr/bin/env bats

# config/shell-startup/perl defines load-time helper functions (setup_perlbrew,
# setup_dzil, setup_prove) and must unset them so they don't linger in the
# shell namespace. Regression for the env-pollution-hygiene fix: after a
# non-interactive source (the BASH_ENV path — the one that runs even without a
# tty), setup_perlbrew must be gone. setup_dzil/setup_prove are interactive-only
# and never defined in a non-interactive shell, so this covers the leak that
# actually reaches a non-interactive namespace.

load ../helpers/common

setup() {
  load_bats_libs
}

@test "a non-interactive source of the perl module leaves no setup_perlbrew" {
  local module
  module="$(dotfiles_root)/config/shell-startup/perl"

  # Fresh non-interactive bash: stub havecmd (perl present, perlbrew absent),
  # point XDG/HOME at a throwaway dir, source the module, then report whether
  # the load-time helper leaked into the namespace.
  run bash -c '
    havecmd() { [[ $1 == perl ]]; }
    HOME="$1"; export HOME
    XDG_CACHE_HOME="$1/cache"
    XDG_DATA_HOME="$1/data"
    source "$2"
    declare -F setup_perlbrew > /dev/null && echo LEAKED || echo clean
  ' _ "$BATS_TEST_TMPDIR" "$module"

  assert_success
  assert_output 'clean'
}
