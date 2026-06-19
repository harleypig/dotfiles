"""Tests for the compact-snapshot SessionStart hook.

Runs the hook as a subprocess (the way Claude Code invokes it) against
throwaway git repos, asserting it emits a git/session-state snapshot only on
source `compact` and stays silent everywhere else. See the hook under
config/claude/hooks/. The gh PR lookup is best-effort and omitted in these
local (non-GitHub) repos, so the tests don't assert on it.
"""

import json
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "config" / "claude" / "hooks" / "compact-snapshot.py"


def _git(repo: Path, *args: str) -> None:
  subprocess.run(
    ["git", "-C", str(repo), *args],
    check=True,
    capture_output=True,
    text=True,
  )


def _make_repo(tmp_path: Path, branch: str = "feature/x") -> Path:
  """A git repo on `branch` with one commit."""
  repo = tmp_path / "myrepo"
  repo.mkdir()
  _git(repo, "init", "-q", "-b", branch)
  _git(
    repo, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q",
    "--allow-empty", "-m", "init"
  )
  return repo


def _run(cwd: str, source: str = "compact") -> dict:
  """Invoke the hook with a crafted SessionStart event; return parsed JSON (or
  {} when the hook emits nothing)."""
  event = {"hook_event_name": "SessionStart", "source": source, "cwd": cwd}
  res = subprocess.run(
    ["python3", str(HOOK)],
    input=json.dumps(event),
    capture_output=True,
    text=True,
  )
  assert res.returncode == 0, res.stderr    # always fail-safe exit 0
  out = res.stdout.strip()
  return json.loads(out) if out else {}


def _ctx(out: dict) -> str:
  return out.get("hookSpecificOutput", {}).get("additionalContext", "")


def test_emits_snapshot_on_compact(tmp_path):
  repo = _make_repo(tmp_path, branch="feature/y")
  ctx = _ctx(_run(str(repo)))
  assert "myrepo" in ctx
  assert "feature/y" in ctx
  assert "Working tree: clean" in ctx


def test_silent_on_non_compact_sources(tmp_path):
  repo = _make_repo(tmp_path)
  for src in ("startup", "resume", "clear"):
    assert _run(str(repo), source=src) == {}, src


def test_silent_outside_git_repo(tmp_path):
  assert _run(str(tmp_path), source="compact") == {}


def test_reports_dirty_worktree_with_staged_count(tmp_path):
  repo = _make_repo(tmp_path)
  (repo / "new.txt").write_text("x\n", encoding="utf-8")
  _git(repo, "add", "new.txt")
  ctx = _ctx(_run(str(repo)))
  assert "1 changed (1 staged)" in ctx


def test_flags_protected_default_branch(tmp_path):
  # When the current branch is the repo's default, the snapshot warns to
  # branch before editing. Point origin/HEAD at the current branch to mark it
  # default (the symbolic-ref need not have a real target ref to be read back).
  repo = _make_repo(tmp_path, branch="main")
  _git(
    repo, "symbolic-ref", "refs/remotes/origin/HEAD",
    "refs/remotes/origin/main"
  )
  ctx = _ctx(_run(str(repo)))
  assert "protected" in ctx
