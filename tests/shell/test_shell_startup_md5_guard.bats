#!/usr/bin/env bats

# Tests for .claude/skills/shell-startup-guard/scripts/guard.sh — the md5 drift
# guard for shell-startup. (Distinct from test_shell_startup_guard.bats, which
# tests shell-startup's double-source guard.)
#
# guard.sh resolves the repo root with `git rev-parse --show-toplevel` and
# operates on shell-startup / shell-startup.md5 there, so the tests run it
# inside an isolated fixture git repo (cwd = fixture) — it never touches the
# real shell-startup.

load ../helpers/common

setup() {
  load_bats_libs
  GUARD="$(dotfiles_root)/.claude/skills/shell-startup-guard/scripts/guard.sh"

  FIX="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$FIX"
  cd "$FIX" || return 1

  git init -q
  git config user.email test@example.com
  git config user.name test

  printf '#!/bin/bash\necho blessed\n' > shell-startup
  "$GUARD" bless
  git add shell-startup shell-startup.md5
  git commit -qm 'baseline'
}

# Append a representative out-of-band line (a tool installer adding itself).
add_drift() {
  # shellcheck disable=SC2016  # literal installer line; no expansion wanted
  printf 'export PATH="$HOME/.grok/bin:$PATH"\n' >> shell-startup
}

@test "check: clean when shell-startup matches the checksum" {
  run "$GUARD" check
  assert_success
  assert_output --partial 'clean'
}

@test "check: drift (exit 1) when shell-startup changed out of band" {
  add_drift

  run "$GUARD" check
  assert_failure 1
  assert_output --partial 'DRIFT'
}

@test "check: no baseline (exit 2) when the checksum is missing" {
  rm shell-startup.md5

  run "$GUARD" check
  assert_failure 2
  assert_output --partial 'no baseline'
}

@test "diff: shows what drifted since the last blessed state" {
  add_drift

  run "$GUARD" diff
  assert_success
  assert_output --partial '.grok/bin'
}

@test "bless: re-blessing a wanted change makes check clean again" {
  printf 'echo more\n' >> shell-startup

  "$GUARD" bless
  run "$GUARD" check
  assert_success
  assert_output --partial 'clean'
}

@test "restore: reverts an out-of-band change to the blessed content" {
  add_drift

  run "$GUARD" restore
  assert_success

  run grep -c '.grok/bin' shell-startup
  assert_output '0'

  run "$GUARD" check
  assert_success
}
