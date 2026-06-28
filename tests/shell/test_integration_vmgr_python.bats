#!/usr/bin/env bats

# Integration test for vmgr's python module, run in a throwaway container (repo
# mounted read-only at /dotfiles) so the REAL install paths run - uv via its
# standalone installer, and pipx via the pip->uv fallback (pip is PEP 668
# managed in the image, so pipx falls back to uv). Skips when docker is absent.
#
# Networked (astral.sh for uv, PyPI for pipx) and slower; sits in the same
# gating suite as the node integration and skips without docker.

# shellcheck disable=SC2016  # $VARs run in the container's shell, not here.

load ../helpers/common

setup() {
  load_bats_libs
  IMAGE="$(vmgr_harness_image)"
}

@test "vmgr installs python's uv (standalone) and pipx (fallback), for real" {
  vmgr_run "$IMAGE" '
    set -e
    export PATH="$HOME/.local/bin:$PATH"

    # uv via the standalone installer (astral.sh). No system uv -> standalone.
    vmgr install python uv
    echo "UV=$(uv --version)"
    vmgr report python uv | grep -q "\[standalone\]" && echo "UVHOW=standalone"

    # pipx: pip --user is PEP 668-blocked here, so vmgr falls back to uv.
    # (No system pipx in the image, so no interactive confirm.)
    vmgr install python pipx
    echo "PIPX=$(pipx --version)"

    # remove both (uv self uninstall; pipx via uv tool uninstall)
    vmgr remove python pipx uv
    command -v uv > /dev/null 2>&1 || echo "UVGONE=ok"
  '
  assert_success
  assert_output --partial 'UV='
  assert_output --partial 'UVHOW=standalone'
  assert_output --partial 'PIPX='
  assert_output --partial 'UVGONE=ok'
}
