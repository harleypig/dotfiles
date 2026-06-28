#!/usr/bin/env bats

# Integration test for bin/vmgr, run in a throwaway container (the repo mounted
# read-only at /dotfiles) so the REAL install/update/remove path is exercised -
# nvm is actually cloned and a real Node is actually downloaded - without
# touching the host. Skips when docker is unavailable.
#
# The whole lifecycle runs in a single container (one set of downloads): a
# clean machine -> install nvm + Node -> prove Node runs -> update -> remove.

# shellcheck disable=SC2016  # $VARs in the command string run in the
# container's shell, not here - deliberately single-quoted.

load ../helpers/common

setup() {
  load_bats_libs
  IMAGE="$(vmgr_harness_image)"
}

@test "vmgr installs, exposes, updates, and removes node (nvm) for real" {
  vmgr_run "$IMAGE" '
    set -e
    export NVM_DIR="$HOME/.local/share/nvm"

    # From a clean machine: install nvm + a default Node.
    vmgr install node

    # nvm landed at the XDG dir, pinned tag checked out.
    test -s "$NVM_DIR/nvm.sh"
    echo "PIN=$(git -C "$NVM_DIR" describe --tags)"

    # The installed Node is actually usable.
    \. "$NVM_DIR/nvm.sh"
    nvm use default > /dev/null
    echo "NODE=$(node --version)"

    # Re-installing is idempotent (already present, no re-clone).
    echo "REINSTALL=$(vmgr install node 2>&1 | grep -c "already present")"

    # Update is a no-op move to the same pinned tag, exits clean.
    vmgr update node
    echo "UPDATED=ok"

    # Remove wipes the whole NVM_DIR.
    vmgr remove node
    test ! -e "$NVM_DIR"
    echo "REMOVED=ok"
  '
  assert_success
  assert_output --partial 'PIN=v0.40.5'
  assert_output --partial 'NODE=v22'
  assert_output --partial 'REINSTALL=1'
  assert_output --partial 'UPDATED=ok'
  assert_output --partial 'REMOVED=ok'
}

@test "vmgr remove on a clean machine is a successful no-op" {
  vmgr_run "$IMAGE" '
    set -e
    export NVM_DIR="$HOME/.local/share/nvm"
    test ! -e "$NVM_DIR"
    vmgr remove node
    echo "NOOP=ok"
  '
  assert_success
  assert_output --partial 'NOOP=ok'
}
