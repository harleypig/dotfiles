#!/usr/bin/env python3

"""PreToolUse hook: block file edits while a protected branch is checked out.

Fires on `Edit` / `Write` / `MultiEdit`. Enforces git.md's "Never Work
Directly on a Protected Branch" at *edit time* — the earliest of the three
layers, below the commit-time `no-commit-to-branch` pre-commit hook and the
push-time server ruleset. It stops the slip before the first character is
written: branch first, then edit.

**Detection is the repo's own declaration, not a guess.** A repo is treated as
protecting a branch only when its `.pre-commit-config.yaml` configures the
`no-commit-to-branch` hook; the protected set is read straight from that
hook's `--branch` args (single source of truth, matching git.md's "a local
`no-commit-to-branch` hook names it"). Consequences:

  - On a protected branch in such a repo → **block** the edit, naming the
    branch and suggesting the working-branch command.
  - On any other branch, or in a repo with no `no-commit-to-branch` hook →
    **allow** silently.

**Known limitation (foreign / forked repos):** this leans on pre-commit being
installed and configured. A cloned upstream or third-party repo that has no
`.pre-commit-config.yaml` (or no `no-commit-to-branch` hook) gets no edit-time
guard here — the agent's git.md discipline and the server ruleset still apply.
Revisit if that gap bites in practice.

Edits to a plan file (`.../claude/plans/...`) are always allowed, so plan mode
is never blocked. Edits to a **gitignored, untracked** file are likewise
allowed: such a file is local-only state (logs, caches, the agent's own
gitignored memory) that can never be committed to the protected branch, so the
"don't author on it" rule does not apply. The *untracked* half matters — a
force-added file that is both tracked and ignore-matched can still land in a
commit, so it stays protected.

Fail-safe: any error exits 0 silently so a hook bug can never block editing.
"""

from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

# The pre-commit hook id whose presence declares branch protection, and the
# id line that marks its entry in `.pre-commit-config.yaml`.
GUARD_HOOK_ID = "no-commit-to-branch"
ID_RE = re.compile(r"-\s*id:\s*" + re.escape(GUARD_HOOK_ID) + r"\s*$")

# A line that starts the next hook/repo entry — the boundary of the guard
# hook's own config block when scanning for its args.
NEXT_ENTRY_RE = re.compile(r"-\s*(?:id|repo):")

# no-commit-to-branch's default protected branches when invoked with no
# `--branch` args; union with the repo's derived default branch for safety.
DEFAULT_PROTECTED = {"master", "main"}


def _emit(decision: str | None, message: str) -> None:
  out: dict = {"hookEventName": "PreToolUse"}
  if decision:
    out["permissionDecision"] = decision
    out["permissionDecisionReason"] = message
  else:
    out["additionalContext"] = message
  print(json.dumps({"hookSpecificOutput": out}))


def _git(repo: Path, *args: str) -> str | None:
  """Run a git command in `repo`; return stripped stdout, or None on error."""
  try:
    res = subprocess.run(
      ["git", "-C", str(repo), *args],
      capture_output=True,
      text=True,
      timeout=5,
    )
  except Exception:
    return None
  if res.returncode != 0:
    return None
  return res.stdout.strip()


def _git_ok(repo: Path, *args: str) -> bool:
  """True iff `git <args>` exits 0 in `repo`. For check-ignore / ls-files
  probes where only the exit status matters; any error is False (fail-safe —
  an unconfirmed probe falls through to the normal protection logic)."""
  try:
    res = subprocess.run(
      ["git", "-C", str(repo), *args],
      capture_output=True,
      text=True,
      timeout=5,
    )
  except Exception:
    return False
  return res.returncode == 0


def _is_local_only(repo: Path, target: Path) -> bool:
  """True when `target` is gitignored AND not tracked — purely local state
  (logs, caches, the agent's own gitignored memory) that can never be
  committed, so editing it on a protected branch breaks nothing. A force-added
  file that is both tracked and ignore-matched stays protected (it can still
  land in a commit), which is why the tracked check is required."""
  if not _git_ok(repo, "check-ignore", "-q", "--", str(target)):
    return False
  return not _git_ok(repo, "ls-files", "--error-unmatch", "--", str(target))


def _existing_ancestor(path: Path) -> Path | None:
  """Nearest existing directory at or above `path` (a Write target may not
  exist yet, but its parent does)."""
  cur = path if path.is_dir() else path.parent
  for p in (cur, *cur.parents):
    if p.is_dir():
      return p
  return None


def _repo_root(path: Path) -> Path | None:
  """The git work-tree root containing `path`, or None if not in a repo."""
  anchor = _existing_ancestor(path)
  if anchor is None:
    return None
  top = _git(anchor, "rev-parse", "--show-toplevel")
  return Path(top) if top else None


def _default_branch(repo: Path) -> str | None:
  """The repo's default branch from the local symbolic ref (no network)."""
  ref = _git(repo, "symbolic-ref", "refs/remotes/origin/HEAD")
  if not ref:
    return None
  return ref.rsplit("/", 1)[-1] or None


def _protected_branches(repo: Path) -> set[str] | None:
  """Branches the repo declares protected via no-commit-to-branch, or None
  when the hook isn't configured (no protection signal → don't enforce)."""
  cfg = repo / ".pre-commit-config.yaml"
  try:
    lines = cfg.read_text(encoding="utf-8").splitlines()
  except Exception:
    return None

  # Find the guard hook's `- id: no-commit-to-branch` line, then collect the
  # tokens of its config block (up to the next hook/repo entry).
  start = next((i for i, ln in enumerate(lines) if ID_RE.search(ln)), None)
  if start is None:
    return None

  block: list[str] = []
  for ln in lines[start + 1:]:
    if NEXT_ENTRY_RE.search(ln):
      break
    block.append(ln)

  # Tokenize the block, then read the value after each --branch / -b flag.
  tokens = re.split(r"[\s,\[\]]+", " ".join(block))
  branches: set[str] = set()
  i = 0
  while i < len(tokens):
    tok = tokens[i]
    if tok in ("--branch", "-b"):
      if i + 1 < len(tokens) and tokens[i + 1]:
        branches.add(tokens[i + 1])
      i += 2
      continue
    if tok.startswith("--branch="):    # `--branch=master` form
      branches.add(tok.split("=", 1)[1])
    i += 1

  if branches:
    return branches

  # Hook present but no explicit branches: mirror its defaults, plus the
  # repo's actual default branch.
  protected = set(DEFAULT_PROTECTED)
  default = _default_branch(repo)
  if default:
    protected.add(default)
  return protected


def main() -> int:
  try:
    event = json.load(sys.stdin)
  except Exception:
    return 0

  if event.get("tool_name") not in ("Edit", "Write", "MultiEdit"):
    return 0

  file_path = (event.get("tool_input") or {}).get("file_path")
  if not file_path:
    return 0

  # Plan-mode edits land in a claude plans dir — never block those.
  if "/claude/plans/" in file_path.replace("\\", "/"):
    return 0

  project_dir = (
    os.environ.get("CLAUDE_PROJECT_DIR") or event.get("cwd") or os.getcwd()
  )
  target = Path(file_path)
  if not target.is_absolute():
    target = Path(project_dir) / target

  repo = _repo_root(target)
  if repo is None:
    return 0  # not in a git repo → nothing to protect

  # A gitignored, untracked file is local-only state that can never be
  # committed to the protected branch, so the "don't author on it" rule does
  # not apply — allow it (e.g. the agent's own gitignored memory files).
  if _is_local_only(repo, target):
    return 0

  protected = _protected_branches(repo)
  if not protected:
    return 0  # repo declares no protected branch (e.g. foreign/forked repo)

  branch = _git(repo, "rev-parse", "--abbrev-ref", "HEAD")
  if not branch or branch == "HEAD":
    return 0  # detached HEAD or unreadable → don't enforce

  if branch in protected:
    default = _default_branch(repo) or branch
    _emit(
      "deny",
      f"Edit blocked — you're on protected branch '{branch}' in "
      f"{repo.name}. This repo protects it (no-commit-to-branch in "
      ".pre-commit-config.yaml), and git.md's \"Never Work Directly on a "
      "Protected Branch\" forbids authoring here. Branch FIRST, then edit:\n\n"
      f"  git switch -c <type>/<name> origin/{default}   "
      "# feature/ | bugfix/ | docs/\n\n"
      "Uncommitted changes carry across the switch, so create the branch and "
      "retry the edit. This hook fails safe.",
    )

  return 0


if __name__ == "__main__":
  sys.exit(main())
