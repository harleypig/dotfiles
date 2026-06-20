#!/usr/bin/env python3

"""SessionStart hook: re-inject a git/session-state snapshot after compaction.

Fires on `SessionStart` with source `compact` (auto or manual `/compact`). A
compaction rebuilds the conversation from a summary; Claude Code auto-reinjects
the durable guidance (global + project `CLAUDE.md`, `MEMORY.md`), but the
*working git state* — which branch, which open PR, what's staged — is not
preserved. This hook emits a short, deterministic snapshot of that state as
`additionalContext` so it survives the compaction instead of being re-derived.

There is **no** `# Compact instructions` CLAUDE.md heading feature (verified
against the docs, 2026-06-19) — a `SessionStart`/`compact` hook is the
documented lever for making content reappear post-compaction. See the decision
in `config/claude/audit/decisions-log.md`.

Read-only and fail-safe: any error, a non-git cwd, a detached HEAD, or a
non-`compact` source emits nothing and exits 0, never disrupting the session.
The `gh` PR lookup is best-effort (short timeout); if gh is absent, slow, or
unauthenticated the PR line is simply omitted.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


def _run(cmd: list[str], cwd: Path, timeout: float) -> str | None:
  """Run `cmd` in `cwd`; return stripped stdout, or None on any failure."""
  try:
    res = subprocess.run(
      cmd, cwd=str(cwd), capture_output=True, text=True, timeout=timeout
    )
  except Exception:
    return None

  if res.returncode != 0:
    return None

  return res.stdout.strip()


def _repo_root(cwd: Path) -> Path | None:
  top = _run(["git", "rev-parse", "--show-toplevel"], cwd, 5)
  return Path(top) if top else None


def _default_branch(repo: Path) -> str | None:
  ref = _run(["git", "symbolic-ref", "refs/remotes/origin/HEAD"], repo, 5)
  return ref.rsplit("/", 1)[-1] if ref else None


def _open_pr(repo: Path, branch: str) -> str | None:
  """A one-line `PR #N title (url)` for the branch's OPEN PR, or None. Best
  effort — gh may be absent/slow/unauthenticated or the repo non-GitHub."""
  out = _run(
    [
      "gh",
      "pr",
      "view",
      branch,
      "--json",
      "number,title,url,state",
      "--jq",
      r'select(.state == "OPEN") | "PR #\(.number) \(.title) (\(.url))"',
    ],
    repo,
    8,
  )
  return out or None


def _worktree(repo: Path) -> str:
  """A short summary of the working tree: 'clean' or 'N changed (S staged)'."""
  status = _run(["git", "status", "--porcelain"], repo, 5)
  if status is None:
    return "unknown"

  if status == "":
    return "clean"

  lines = status.splitlines()
  staged = sum(1 for ln in lines if ln[:1] not in (" ", "?"))
  return f"{len(lines)} changed ({staged} staged)"


def main() -> int:
  try:
    event = json.load(sys.stdin)
  except Exception:
    return 0

  # Only after a compaction. The settings matcher already scopes this to
  # source `compact`; the explicit check keeps the hook self-contained and
  # testable (invoked directly, it ignores startup/resume/clear).
  if event.get("source") != "compact":
    return 0

  cwd = Path(
    event.get("cwd") or os.environ.get("CLAUDE_PROJECT_DIR") or os.getcwd()
  )

  repo = _repo_root(cwd)
  if repo is None:
    return 0  # not in a git repo → nothing useful to snapshot

  branch = _run(["git", "rev-parse", "--abbrev-ref", "HEAD"], repo, 5)
  if not branch or branch == "HEAD":
    return 0  # detached HEAD / unreadable → skip

  lines = [f"Session state (post-compaction snapshot, {repo.name}):"]

  if branch == _default_branch(repo):
    lines.append(
      f"- Branch: {branch} — this is the protected default; create a working "
      "branch before editing."
    )
  else:
    lines.append(f"- Branch: {branch}")

  pr = _open_pr(repo, branch)
  if pr:
    lines.append(f"- Open {pr}")

  lines.append(f"- Working tree: {_worktree(repo)}")

  print(
    json.dumps({
      "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": "\n".join(lines),
      }
    })
  )
  return 0


if __name__ == "__main__":
  sys.exit(main())
