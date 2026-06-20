#!/usr/bin/env python3

"""PreToolUse hook: gate PR merges on the merge-time finalization.

Fires on a PR-merge command (`gh pr merge ...` / `ship.sh merge ...`) — NOT
`git merge`, so routine branch syncs are never gated. It backstops the
merge-time documentation finalization that the ship-pr skill (Step 4.5) and a
repo's `WORKFLOW.md` describe: completed items pruned from the planning docs
and the changelog refreshed before the PR lands.

**Opt-in, because "prune completed `[x]` items" is a repo convention, not a
universal one** — some repos deliberately keep `[x]` as a done-work record or
nested progress markers. So the hook only **hard-blocks** in a repo that
declares the convention, via the sentinel ``merge-finalization: enforce`` in
its ``.claude/WORKFLOW.md`` or ``.claude/CONVENTIONS.md``:

  - **Opted-in repo with unpruned `- [x]` items** in TODO.md / ROADMAP.md /
    docs/ROADMAP.md → **block** the merge (the prune step was skipped), naming
    the offending files.
  - **Otherwise** (opted-in but clean, or a repo that hasn't opted in) →
    **allow**, injecting the finalization checklist as a reminder so the
    not-statically-checkable step (refresh the changelog) isn't forgotten.

A repo can extend the pruned set beyond the generic defaults (TODO.md /
ROADMAP.md / docs/ROADMAP.md) with a ``merge-finalization-docs:`` line in the
same opt-in docs — keeping repo-specific paths out of this global hook (e.g.
the dotfiles repo adds its audit ``BACKLOG.md``).

Fail-safe: any error exits 0 silently so a hook bug can never block a merge.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

# A PR-merge invocation, but not `git merge` (branch sync). Matches
# `gh pr merge`, `ship.sh merge`, `ship merge`.
MERGE_RE = re.compile(r"\b(?:gh\s+pr\s+merge|ship(?:\.sh)?\s+merge)\b")

# A completed Markdown task-list item: `- [x]` / `* [X]` (any indent).
DONE_ITEM_RE = re.compile(r"^\s*[-*+]\s+\[[xX]\]")

# Planning docs the finalization prunes, relative to the repo root.
PLANNING_DOCS = ("TODO.md", "ROADMAP.md", "docs/ROADMAP.md", "docs/TODO.md")

# A repo opts in to the hard block by carrying this sentinel in its agent
# docs (so the convention lives with the repo that adopts it).
ENFORCE_MARKER = "merge-finalization: enforce"
OPT_IN_DOCS = (".claude/WORKFLOW.md", ".claude/CONVENTIONS.md")

# A repo may extend the pruned planning docs beyond the generic defaults with a
# line in its opt-in docs (keeps repo-specific paths out of this global hook):
#   merge-finalization-docs: config/claude/audit/BACKLOG.md, docs/OTHER.md
EXTRA_DOCS_RE = re.compile(
  r"^[ \t]*merge-finalization-docs:[ \t]*(.+?)[ \t]*$", re.M
)

CHECKLIST = (
  "Merge-time finalization (ship-pr Step 4.5 / repo WORKFLOW.md), docs-only:\n"
  " - Prune completed items from TODO.md / ROADMAP.md per the repo's "
  "convention (where it removes them outright, do not leave them `[x]`).\n"
  " - Refresh the generated changelog per the repo (mutates the tree, so "
  "commit it here, never in CI).\n"
  " - Commit the docs-only change, push, re-watch CI green, then merge."
)


def _enforces(repo: Path) -> bool:
  """Whether `repo` opted in to the hard block (sentinel in its agent docs)."""
  for rel in OPT_IN_DOCS:
    doc = repo / rel
    try:
      if doc.is_file() and ENFORCE_MARKER in doc.read_text(encoding="utf-8"):
        return True
    except Exception:
      continue
  return False


def _extra_docs(repo: Path) -> tuple[str, ...]:
  """Repo-declared extra planning docs (comma-separated, repo-relative) from a
  `merge-finalization-docs:` line in the opt-in docs. Empty if none."""
  for rel in OPT_IN_DOCS:
    doc = repo / rel
    try:
      if not doc.is_file():
        continue
      m = EXTRA_DOCS_RE.search(doc.read_text(encoding="utf-8"))
      if m:
        return tuple(p.strip() for p in m.group(1).split(",") if p.strip())
    except Exception:
      continue
  return ()


def _done_items(repo: Path) -> list[str]:
  """Planning docs under `repo` that still carry completed `- [x]` items,
  reported as "file (N)"."""
  hits: list[str] = []
  for rel in PLANNING_DOCS + _extra_docs(repo):
    doc = repo / rel
    try:
      if not doc.is_file():
        continue
      n = sum(
        1 for line in doc.read_text(encoding="utf-8").splitlines()
        if DONE_ITEM_RE.match(line)
      )
    except Exception:
      continue
    if n:
      hits.append(f"{rel} ({n})")
  return hits


def _emit(decision: str | None, message: str) -> None:
  out: dict = {"hookEventName": "PreToolUse"}
  if decision:
    out["permissionDecision"] = decision
    out["permissionDecisionReason"] = message
  else:
    out["additionalContext"] = message
  print(json.dumps({"hookSpecificOutput": out}))


def main() -> int:
  try:
    event = json.load(sys.stdin)
  except Exception:
    return 0

  if event.get("tool_name") != "Bash":
    return 0

  command = (event.get("tool_input") or {}).get("command") or ""
  if not MERGE_RE.search(command):
    return 0

  repo = Path(
    os.environ.get("CLAUDE_PROJECT_DIR") or event.get("cwd") or os.getcwd()
  )

  hits = _done_items(repo) if _enforces(repo) else []
  if hits:
    _emit(
      "deny",
      "Merge blocked — merge-time finalization not done: completed `- [x]` "
      "items remain in " + ", ".join(hits) + ".\n\n" + CHECKLIST
      + "\n\nPrune the completed items (and refresh the changelog), commit, "
      "re-watch CI, then merge. This hook fails safe.",
    )
  else:
    _emit(
      None,
      "Before merging, confirm this repo's merge-time finalization is done — "
      "planning docs reflect only open work and the changelog is refreshed. "
      + CHECKLIST,
    )
  return 0


if __name__ == "__main__":
  sys.exit(main())
