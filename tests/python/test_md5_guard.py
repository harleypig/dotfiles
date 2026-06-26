"""Tests for the md5-guard PostToolUse hook.

Runs the hook as a subprocess (the way Claude Code invokes it) against an
isolated git repo, so the tests are hermetic. The hook auto-regenerates a
git-tracked `<name>.md5` sibling after its file is edited; it stays silent and
inert everywhere a tracked sibling does not exist. See the hook under
config/claude/hooks/md5-guard.py.
"""

import hashlib
import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "config" / "claude" / "hooks" / "md5-guard.py"


def _git(repo: Path, *args: str) -> None:
  subprocess.run(["git", *args], cwd=repo, check=True, capture_output=True)


def _repo(tmp_path: Path) -> Path:
  repo = tmp_path / "repo"
  repo.mkdir()
  _git(repo, "init", "-q")
  _git(repo, "config", "user.email", "test@example.com")
  _git(repo, "config", "user.name", "test")
  return repo


def _md5_line(content: bytes, name: str) -> str:
  # md5 is for drift detection, not security (usedforsecurity=False → B324).
  digest = hashlib.md5(content, usedforsecurity=False).hexdigest()
  return f"{digest}  {name}\n"


def _run(file_path: str) -> dict:
  event = {"tool_name": "Write", "tool_input": {"file_path": file_path}}
  res = subprocess.run(
    [sys.executable, str(HOOK)],
    input=json.dumps(event),
    capture_output=True,
    text=True,
  )
  assert res.returncode == 0, res.stderr    # always fail-safe exit 0
  out = res.stdout.strip()
  return json.loads(out) if out else {}


def _context(out: dict) -> str:
  return out.get("hookSpecificOutput", {}).get("additionalContext", "")


def test_regenerates_tracked_md5_sibling(tmp_path):
  repo = _repo(tmp_path)
  target = repo / "shell-startup"
  content = b"#!/bin/bash\necho new\n"
  target.write_bytes(content)

  sumfile = repo / "shell-startup.md5"
  sumfile.write_text("deadbeef  shell-startup\n", encoding="utf-8")  # stale
  _git(repo, "add", "shell-startup.md5")

  out = _run(str(target))
  assert "Auto-blessed" in _context(out)
  expected = _md5_line(content, "shell-startup")
  assert sumfile.read_text(encoding="utf-8") == expected


def test_noop_when_md5_already_current(tmp_path):
  repo = _repo(tmp_path)
  target = repo / "shell-startup"
  content = b"#!/bin/bash\necho ok\n"
  target.write_bytes(content)

  sumfile = repo / "shell-startup.md5"
  sumfile.write_text(_md5_line(content, "shell-startup"), encoding="utf-8")
  _git(repo, "add", "shell-startup.md5")

  assert _run(str(target)) == {}


def test_skips_file_without_md5_sibling(tmp_path):
  repo = _repo(tmp_path)
  target = repo / "shell-startup"
  target.write_bytes(b"#!/bin/bash\necho hi\n")

  assert _run(str(target)) == {}


def test_skips_untracked_md5_sibling(tmp_path):
  repo = _repo(tmp_path)
  target = repo / "shell-startup"
  target.write_bytes(b"#!/bin/bash\necho hi\n")

  sumfile = repo / "shell-startup.md5"
  stale = "deadbeef  shell-startup\n"
  # Present but never `git add`ed, so the tracked-sibling check fails.
  sumfile.write_text(stale, encoding="utf-8")

  assert _run(str(target)) == {}
  assert sumfile.read_text(encoding="utf-8") == stale      # left untouched


def test_fail_open_outside_git_repo(tmp_path):
  # A tracked check can't run outside a repo -> stay silent, mutate nothing.
  target = tmp_path / "shell-startup"
  target.write_bytes(b"#!/bin/bash\necho hi\n")

  sumfile = tmp_path / "shell-startup.md5"
  stale = "deadbeef  shell-startup\n"
  sumfile.write_text(stale, encoding="utf-8")

  assert _run(str(target)) == {}
  assert sumfile.read_text(encoding="utf-8") == stale
