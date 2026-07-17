#!/usr/bin/env bats

# Integration test for bin/vmgr's perl (perlbrew) manager, run in a throwaway
# container (the repo mounted read-only at /dotfiles) so the REAL install path
# is exercised without touching the host. Skips when docker is unavailable.
#
# perlbrew COMPILES Perl from source (minutes), unlike nvm's prebuilt-binary
# download, so the expensive full lifecycle (which builds a real Perl) is
# OPT-IN via VMGR_PERL_COMPILE=1. The always-run tests exercise everything
# EXCEPT the Perl build: the pinned perlbrew self-install, `vmgr report`, and
# `vmgr remove` - fast (~15s, one network fetch) and enough to gate per-PR.

# shellcheck disable=SC2016  # $VARs in the command string run in the
# container's shell, not here - deliberately single-quoted.

load ../helpers/common

setup() {
  load_bats_libs
  IMAGE="$(perl_harness_image)"
}

@test "vmgr self-installs pinned perlbrew, reports it, and removes it (no Perl build)" {
  perl_run "$IMAGE" '
    set -e
    export PERLBREW_ROOT="$HOME/.local/share/perlbrew"

    # Install just perlbrew (the pinned self-install), skipping the slow Perl
    # build, by driving the module internals directly.
    source /dotfiles/lib/version-managers/perl
    _vmgr_load_pins perl PERLBREW_PIN PERL_PIN
    _perl_install_perlbrew

    # The pinned perlbrew landed at the XDG root and reports its version.
    test -x "$PERLBREW_ROOT/bin/perlbrew"
    echo "PBVER=$("$PERLBREW_ROOT/bin/perlbrew" version 2>&1)"

    # report sees the fresh perlbrew at the expected location.
    echo "REPORT<<"
    vmgr report perl
    echo ">>REPORT"

    # remove wipes the whole root.
    vmgr remove perl
    test ! -e "$PERLBREW_ROOT"
    echo "REMOVED=ok"
  '
  assert_success
  assert_output --partial 'PBVER='
  assert_output --partial '1.02'
  assert_output --partial 'matches the expected vmgr location'
  assert_output --partial 'REMOVED=ok'
}

@test "vmgr remove perl on a clean machine is a successful no-op" {
  perl_run "$IMAGE" '
    set -e
    export PERLBREW_ROOT="$HOME/.local/share/perlbrew"
    test ! -e "$PERLBREW_ROOT"
    vmgr remove perl
    echo "NOOP=ok"
  '
  assert_success
  assert_output --partial 'NOOP=ok'
}

@test "vmgr builds a real pinned Perl + modules, then removes them (opt-in, slow)" {
  [[ -n ${VMGR_PERL_COMPILE:-} ]] \
    || skip "set VMGR_PERL_COMPILE=1 to build a real Perl (perlbrew compiles from source; minutes)"

  perl_run "$IMAGE" '
    set -e
    export PERLBREW_ROOT="$HOME/.local/share/perlbrew"

    # Full lifecycle: install perlbrew + build the pinned Perl + cpanm + the
    # module set, then prove Perl::Tidy is usable under that Perl.
    vmgr install perl

    "$PERLBREW_ROOT/bin/perlbrew" list | grep -q perl-5.40.2
    echo "TIDY=$("$PERLBREW_ROOT/bin/perlbrew" exec --with perl-5.40.2 perl -MPerl::Tidy -e "print Perl::Tidy->VERSION" 2>&1)"

    vmgr remove perl
    test ! -e "$PERLBREW_ROOT"
    echo "LIFECYCLE=ok"
  '
  assert_success
  assert_output --partial 'TIDY='
  assert_output --partial 'LIFECYCLE=ok'
}
