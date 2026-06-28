#!/usr/bin/env bats

# Unit tests for lib/version-managers/python - specifically the install-method
# PRIORITY/FALLBACK logic for uv and pipx. The real uv/pipx/pip are present on
# dev/CI boxes, so each test runs the module function under a fully isolated
# PATH ($BIN stubs + $TOOLS coreutils only), with `set -o pipefail` to match
# bin/vmgr (uv's `curl ... | sh` relies on it to detect a failed download).

load ../helpers/common

setup() {
  load_bats_libs

  # Pins the module reads (arbitrary, distinctive values for assertions).
  export VMGR_CONFIG_DIR="$BATS_TEST_TMPDIR/conf"
  mkdir -p "$VMGR_CONFIG_DIR"
  printf 'UV_PIN=9.9.9\nPIPX_PIN=8.8.8\n' > "$VMGR_CONFIG_DIR/python"

  # shellcheck disable=SC1090,SC1091  # path resolved from the repo root at runtime
  source "$(dotfiles_root)/lib/version-managers/python"

  BIN="$BATS_TEST_TMPDIR/bin"     # command stubs go here
  TOOLS="$BATS_TEST_TMPDIR/tools" # only the tools the module + stubs need
  mkdir -p "$BIN" "$TOOLS"

  # env + bash are needed by the stub shebangs (#!/usr/bin/env bash).
  local t
  for t in sh bash env readlink grep cat; do
    ln -sf "$(command -v "$t")" "$TOOLS/$t"
  done

  set -o pipefail
}

# Run a module function with the isolated PATH; capture rc + output without
# letting a non-zero return trip bats's errexit (which would skip the restore).
iso() {
  local saved=$PATH
  PATH="$BIN:$TOOLS"
  ISO_RC=0
  "$@" > "$BATS_TEST_TMPDIR/out" 2>&1 || ISO_RC=$?
  PATH=$saved
  ISO_OUT=$(cat "$BATS_TEST_TMPDIR/out")
}

# --- uv install priority ------------------------------------------------------

@test "uv install: standalone installer succeeds, pipx not touched" {
  make_stub "$BIN" curl 0   # download "succeeds" (empty body -> sh no-ops)

  iso uv_install
  [ "$ISO_RC" -eq 0 ]
  grep -q 'astral.sh/uv/9.9.9/install.sh' "$BIN/curl.args"
  [ ! -e "$BIN/pipx.args" ]
}

@test "uv install: standalone fails, falls back to pipx" {
  make_stub "$BIN" curl 1   # download fails (firewall)
  make_stub "$BIN" pipx 0

  iso uv_install
  [ "$ISO_RC" -eq 0 ]
  grep -q 'install uv==9.9.9' "$BIN/pipx.args"
}

@test "uv install: standalone fails and no pipx -> error" {
  make_stub "$BIN" curl 1   # download fails, no pipx stub present

  iso uv_install
  [ "$ISO_RC" -ne 0 ]
  [[ $ISO_OUT == *"pipx unavailable for fallback"* ]]
}

# --- pipx install priority ----------------------------------------------------

@test "pipx install: prefers pip (--user)" {
  # No existing pipx (none on the isolated PATH). pip available via python3.
  make_script_stub "$BIN" python3 'printf "%s\n" "$*" >> "'"$BIN"'/python3.args"; exit 0'

  iso pipx_install
  [ "$ISO_RC" -eq 0 ]
  grep -q 'pip install --user pipx==8.8.8' "$BIN/python3.args"
}

@test "pipx install: pip absent, falls back to uv" {
  # python3 -m pip --version fails -> pip unavailable; uv present.
  make_script_stub "$BIN" python3 'exit 1'
  make_stub "$BIN" uv 0

  iso pipx_install
  [ "$ISO_RC" -eq 0 ]
  grep -q 'tool install pipx==8.8.8' "$BIN/uv.args"
}

@test "pipx install: pip present but install fails (PEP 668) -> uv fallback" {
  # python3 -m pip --version succeeds (pip present), but the install fails;
  # the module must fall through to uv rather than giving up.
  make_script_stub "$BIN" python3 \
    'case "$*" in *"--version") exit 0;; *"install"*) exit 1;; esac'
  make_stub "$BIN" uv 0

  iso pipx_install
  [ "$ISO_RC" -eq 0 ]
  grep -q 'tool install pipx==8.8.8' "$BIN/uv.args"
}

@test "pipx install: neither pip nor uv -> error" {
  make_script_stub "$BIN" python3 'exit 1'   # no pip, no uv stub

  iso pipx_install
  [ "$ISO_RC" -ne 0 ]
  [[ $ISO_OUT == *"neither pip nor uv"* ]]
}

@test "pipx install: a system pipx, non-interactive, is left alone" {
  # A pipx not at ~/.local/bin reads as "system"; bats has no tty, so the
  # confirm path declines and nothing is installed.
  make_stub "$BIN" pipx 0
  make_script_stub "$BIN" python3 'printf "%s\n" "$*" >> "'"$BIN"'/python3.args"; exit 0'

  iso pipx_install
  [ "$ISO_RC" -eq 0 ]
  [[ $ISO_OUT == *"re-run interactively"* ]]
  [ ! -e "$BIN/python3.args" ]   # no pip install attempted
}

# --- report -------------------------------------------------------------------

@test "uv report: shows the pin and 'not installed' when absent" {
  iso uv_report
  [ "$ISO_RC" -eq 0 ]
  [[ $ISO_OUT == *"uv 9.9.9"* ]]
  [[ $ISO_OUT == *"not installed"* ]]
}
