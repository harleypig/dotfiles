#!/usr/bin/env bash

# shell-startup-guard: detect un-managed (out-of-band) changes to the
# `shell-startup` script and help resolve them. See the sibling SKILL.md for
# the full procedure (this script is its judgment-free mechanics).
#
# Subcommands:
#   check    compare shell-startup against shell-startup.md5
#            (exit 0 = clean, 1 = drift, 2 = no baseline / error)
#   diff     show what drifted since the last blessed state
#   bless    regenerate shell-startup.md5 from the current shell-startup
#   restore  restore shell-startup to its last blessed content
#
# The "last blessed state" is the shell-startup content at the most recent
# commit that touched shell-startup.md5 — the two always change together (the
# bless step and the PostToolUse auto-bless hook keep them in lockstep), so
# that commit is the baseline drift is measured against. Going back to it
# captures all drift accumulated since, even across several commits.
#
# This is a flat dispatcher (subcommands, not options), so it uses a plain
# case rather than parse_params.

set -euo pipefail

readonly TARGET="shell-startup"
readonly SUMFILE="shell-startup.md5"

#-----------------------------------------------------------------------------
# Move to the repo root so TARGET/SUMFILE paths are stable wherever we run.

root="$(git rev-parse --show-toplevel 2> /dev/null)" || {
  echo "shell-startup-guard: not inside a git repository" >&2
  exit 2
}

cd "$root" || {
  echo "shell-startup-guard: cannot cd to $root" >&2
  exit 2
}

#-----------------------------------------------------------------------------
# The commit that last blessed the checksum. TARGET and SUMFILE move together,
# so this commit's TARGET is the last-known-good baseline.

bless_commit() {
  git log -1 --format=%H -- "$SUMFILE" 2> /dev/null
}

#-----------------------------------------------------------------------------
do_check() {
  [[ -f $TARGET ]] || {
    echo "shell-startup-guard: $TARGET not found" >&2
    exit 2
  }

  [[ -f $SUMFILE ]] || {
    echo "shell-startup-guard: no baseline ($SUMFILE missing); run 'bless'" >&2
    exit 2
  }

  if md5sum -c "$SUMFILE" > /dev/null 2>&1; then
    echo "shell-startup-guard: clean — $TARGET matches $SUMFILE"
    return 0
  fi

  echo "shell-startup-guard: DRIFT — $TARGET no longer matches $SUMFILE" >&2
  return 1
}

#-----------------------------------------------------------------------------
do_diff() {
  local commit
  commit="$(bless_commit)"

  [[ -n $commit ]] || {
    echo "shell-startup-guard: $SUMFILE has no commit history; no baseline diff" >&2
    exit 2
  }

  echo "# drift in $TARGET since last blessed at ${commit:0:12}:"
  git --no-pager diff "$commit" -- "$TARGET"
}

#-----------------------------------------------------------------------------
do_bless() {
  [[ -f $TARGET ]] || {
    echo "shell-startup-guard: $TARGET not found" >&2
    exit 2
  }

  md5sum "$TARGET" > "$SUMFILE"
  echo "shell-startup-guard: blessed — regenerated $SUMFILE for current $TARGET"
  echo "Stage both $TARGET and $SUMFILE in the same commit."
}

#-----------------------------------------------------------------------------
do_restore() {
  local commit
  commit="$(bless_commit)"

  [[ -n $commit ]] || {
    echo "shell-startup-guard: $SUMFILE has no commit history; nothing to restore" >&2
    exit 2
  }

  git checkout "$commit" -- "$TARGET"
  echo "shell-startup-guard: restored $TARGET to its last blessed content (${commit:0:12})"

  if md5sum -c "$SUMFILE" > /dev/null 2>&1; then
    echo "shell-startup-guard: clean — $TARGET matches $SUMFILE"
  else
    echo "shell-startup-guard: warning — $TARGET still differs from $SUMFILE" >&2
  fi
}

##############################################################################
# Dispatch

cmd="${1:-check}"

case $cmd in
  check) do_check ;;
  diff) do_diff ;;
  bless) do_bless ;;
  restore) do_restore ;;
  *)
    echo "usage: guard.sh {check|diff|bless|restore}" >&2
    exit 2
    ;;
esac
