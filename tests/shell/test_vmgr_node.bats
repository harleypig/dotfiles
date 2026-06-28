#!/usr/bin/env bats

# Unit tests for the nvm_report function in lib/version-managers/node. They
# source the module and drive nvm_report against constructed NVM_DIR fixtures
# (no real nvm, no network, no docker) to assert the expected-vs-current report
# and its drift findings. The real install/update/remove lifecycle is proven in
# test_integration_vmgr.bats.

load ../helpers/common

setup() {
  load_bats_libs

  # shellcheck disable=SC1090,SC1091  # path resolved from the repo root at runtime
  source "$(dotfiles_root)/lib/version-managers/node"

  XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
  mkdir -p "$XDG_DATA_HOME"

  # Hermetic pins config (override the repo's), so tests don't couple to the
  # real config/vmgr/node values.
  VMGR_CONFIG_DIR="$BATS_TEST_TMPDIR/vmgrconf"
  mkdir -p "$VMGR_CONFIG_DIR"
  printf 'NVM_PIN=v0.40.5\nNODE_PIN=v22.23.1\n' > "$VMGR_CONFIG_DIR/node"
}

@test "nvm_report flags a location mismatch and suggests migrating" {
  # NVM_DIR points somewhere other than the expected XDG_DATA_HOME/nvm.
  local other="$BATS_TEST_TMPDIR/elsewhere/nvm"
  mkdir -p "$other"

  XDG_DATA_HOME="$XDG_DATA_HOME" NVM_DIR="$other" run nvm_report
  assert_success
  assert_output --partial 'but vmgr expects'
  assert_output --partial "$XDG_DATA_HOME/nvm"
  assert_output --partial 'Consider migrating'
  assert_output --partial 'from environment (NVM_DIR)'
}

@test "nvm_report reports a clean match when at the expected location" {
  # No NVM_DIR override: defaults to XDG_DATA_HOME/nvm. Mark it present with a
  # non-git nvm.sh so no git is needed.
  unset NVM_DIR
  mkdir -p "$XDG_DATA_HOME/nvm"
  touch "$XDG_DATA_HOME/nvm/nvm.sh"

  XDG_DATA_HOME="$XDG_DATA_HOME" run nvm_report
  assert_success
  assert_output --partial 'matches the expected vmgr location'
  assert_output --partial 'vmgr default'
  assert_output --partial 'present (not a git checkout)'
}

@test "nvm_report says not installed when NVM_DIR is empty" {
  unset NVM_DIR
  XDG_DATA_HOME="$XDG_DATA_HOME" run nvm_report
  assert_success
  assert_output --partial 'not installed'
  assert_output --partial "run 'vmgr install node'"
}

@test "nvm_report lists installed node versions and the default alias" {
  unset NVM_DIR
  mkdir -p "$XDG_DATA_HOME/nvm/versions/node/v22.0.0" \
    "$XDG_DATA_HOME/nvm/versions/node/v20.1.0" \
    "$XDG_DATA_HOME/nvm/alias"
  touch "$XDG_DATA_HOME/nvm/nvm.sh"
  echo "22" > "$XDG_DATA_HOME/nvm/alias/default"

  XDG_DATA_HOME="$XDG_DATA_HOME" run nvm_report
  assert_success
  assert_output --partial 'v20.1.0 v22.0.0'
  assert_output --partial 'default alias -> 22'
}

@test "nvm_report reads the pinned versions from config, not code" {
  unset NVM_DIR
  printf 'NVM_PIN=v0.40.9\nNODE_PIN=v18.0.0\n' > "$VMGR_CONFIG_DIR/node"

  XDG_DATA_HOME="$XDG_DATA_HOME" run nvm_report
  assert_success
  assert_output --partial 'nvm ver : v0.40.9'
  assert_output --partial 'node    : v18.0.0 (default)'
}

@test "nvm_report flags an nvm version older than the pin" {
  unset NVM_DIR
  # A real git checkout tagged below NVM_PIN so 'git describe --tags' reports it.
  local dir="$XDG_DATA_HOME/nvm"
  git init -q "$dir"
  git -C "$dir" config user.email t@example.com
  git -C "$dir" config user.name test
  git -C "$dir" commit -q --allow-empty -m init
  git -C "$dir" tag v0.40.3

  XDG_DATA_HOME="$XDG_DATA_HOME" run nvm_report
  assert_success
  assert_output --partial 'v0.40.3 installed vs v0.40.5 pinned'
}
