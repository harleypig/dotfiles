#!/usr/bin/env python3

"""PreToolUse hook: gate PR merges on the merge-time finalization.

Fires on a PR-merge command (`gh pr merge ...` / `push.sh merge ...`) — NOT
`git merge`, so routine branch syncs are never gated. It backstops the
merge-time documentation finalization that the push-pr skill (Step 4.5) and a
repo's `WORKFLOW.md` describe: completed items pruned from the planning docs,
the GitHub issues those items resolve closed, and the changelog refreshed
before the PR lands.

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

The scanned repo is the merge's **target**, not blindly the session dir — a
``--repo``/``-R`` flag or a ``cd <path> &&`` prefix means the merge lands in a
*different* repo, whose planning docs are the ones that matter (scanning the
session repo instead false-blocked cross-repo merges twice: PRs #38/#40 in
terraform-provider-mxroute, blocked on harleydev's kept-branch ``[x]`` marks).
A ``--repo`` target resolves to a local clone via the related-repos convention
(a sibling directory named after the repo); when no clone is found the hook
cannot verify anything, so it emits the reminder and never blocks.

Fail-safe: any error exits 0 silently so a hook bug can never block a merge.
"""

from __future__ import annotations

import json
import os
import re
import sys
from pathlib import Path

# A PR-merge invocation, but not `git merge` (branch sync). Matches
# `gh pr merge`, `push.sh merge`, `push merge`.
MERGE_RE = re.compile(r"\b(?:gh\s+pr\s+merge|push(?:\.sh)?\s+merge)\b")

# The merge's explicit target repo: `--repo`/`-R` takes `[HOST/]OWNER/REPO`
# or a full URL; only the trailing repo name matters for finding a clone.
REPO_FLAG_RE = re.compile(r"(?:^|\s)(?:--repo|-R)(?:=|\s+)(\S+)")

# A `cd <path> && ...` prefix — the merge runs in <path>, not the session dir.
CD_PREFIX_RE = re.compile(
  r"^\s*cd\s+(?:\"([^\"]+)\"|'([^']+)'|([^\s;&|]+))\s*&&"
)

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
  "Merge-time finalization (push-pr Step 4.5 / repo WORKFLOW.md), docs-only:\n"
  " - Prune completed items from TODO.md / ROADMAP.md per the repo's "
  "convention (where it removes them outright, do not leave them `[x]`).\n"
  " - Close the GitHub issues those completed items resolve (with a "
  "closing comment), unless a `Closes #N` keyword in the PR already "
  "auto-closes them.\n"
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


def _target_repo(command: str, session: Path) -> Path | None:
  """The local repo the merge actually targets. `--repo`/`-R` names a repo
  explicitly — resolve it to the session repo (name match) or a sibling
  clone (the related-repos convention: `$PARENT_DIR/<repo-name>/`); None if
  no local clone is found (unverifiable — the caller must not block on some
  *other* repo's docs). A `cd <path> &&` prefix runs the merge in <path>.
  Otherwise the merge targets the session repo, as before."""
  m = REPO_FLAG_RE.search(command)
  if m:
    name = m.group(1).rstrip("/").split("/")[-1]
    if name.endswith(".git"):
      name = name[:-4]

    if session.name == name:
      return session

    sibling = session.parent / name
    if (sibling / ".git").exists():
      return sibling

    return None

  m = CD_PREFIX_RE.match(command)
  if m:
    path = Path(os.path.expanduser(next(g for g in m.groups() if g)))
    if not path.is_absolute():
      path = session / path
    if path.is_dir():
      return path

  return session


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

  session = Path(
    os.environ.get("CLAUDE_PROJECT_DIR") or event.get("cwd") or os.getcwd()
  )

  repo = _target_repo(command, session)
  if repo is None:
    _emit(
      None,
      "This merge targets a repo with no local clone found beside the "
      "session repo — its merge-time finalization cannot be verified from "
      "here; confirm it yourself. " + CHECKLIST,
    )
    return 0

  hits = _done_items(repo) if _enforces(repo) else []
  if hits:
    _emit(
      "deny",
      "Merge blocked — merge-time finalization not done: completed `- [x]` "
      "items remain in " + ", ".join(hits) + ".\n\n" + CHECKLIST
      + "\n\nPrune the completed items, close the issues they resolve, "
      "refresh the changelog, commit, re-watch CI, then merge. This hook "
      "fails safe.",
    )
  else:
    _emit(
      None,
      "Before merging, confirm this repo's merge-time finalization is done — "
      "planning docs reflect only open work, the issues those items resolve "
      "are closed, and the changelog is refreshed. " + CHECKLIST,
    )
  return 0


if __name__ == "__main__":
  sys.exit(main())
