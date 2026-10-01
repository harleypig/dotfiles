#!/usr/bin/env bats

# Unit tests for perlbrew_report in lib/version-managers/perl. They drive the
# real bin/vmgr dispatcher, because the dispatcher runs under `set -u` and
# sourcing the module into bats would not reproduce an unbound-variable crash.
# PERLBREW_ROOT points at an empty dir, so no real perlbrew, network or docker
# is involved. The install/update/remove lifecycle is proven in
# test_integration_vmgr_perl.bats.

load ../helpers/common

setup() {
  load_bats_libs

  VMGR="$(dotfiles_root)/bin/vmgr"

  XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
  mkdir -p "$XDG_DATA_HOME"

  # Hermetic pins config, so tests don't couple to config/vmgr/perl.
  VMGR_CONFIG_DIR="$BATS_TEST_TMPDIR/vmgrconf"
  mkdir -p "$VMGR_CONFIG_DIR"
  printf 'PERLBREW_PIN=1.02\nPERL_PIN=5.40.2\n' > "$VMGR_CONFIG_DIR/perl"
}

# #485 - regression: an absent perlbrew left `installed` unset, and the
# Findings check crashed under set -u before printing the install hint.
@test "report perl with no perlbrew exits 0 and suggests installing" {
  XDG_DATA_HOME="$XDG_DATA_HOME" VMGR_CONFIG_DIR="$VMGR_CONFIG_DIR" \
    PERLBREW_ROOT="$BATS_TEST_TMPDIR/no-perlbrew" run "$VMGR" report perl
  assert_success
  assert_output --partial 'perlbrew  : not installed'
  assert_output --partial "perlbrew not installed at the current root; run 'vmgr install perl'."
  refute_output --partial 'unbound variable'
}
