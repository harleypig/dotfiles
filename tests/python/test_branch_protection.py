"""Tests for the branch-protection PreToolUse hook.

Runs the hook as a subprocess (the way Claude Code invokes it) against
throwaway git repos, asserting it blocks edits on a declared-protected branch
and stays silent everywhere else. See the hook under config/claude/hooks/.
"""

import json
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "config" / "claude" / "hooks" / "branch-protection.py"

# A .pre-commit-config.yaml that protects `master` via no-commit-to-branch.
PROTECT_MASTER = (
  "repos:\n"
  "  - repo: https://github.com/pre-commit/pre-commit-hooks\n"
  "    rev: v6.0.0\n"
  "    hooks:\n"
  "      - id: no-commit-to-branch\n"
  "        args: [--branch, master]\n"
  "      - id: check-yaml\n"
)

# Same hook but with no args — exercises the default-protected fallback.
PROTECT_DEFAULTS = (
  "repos:\n"
  "  - repo: https://github.com/pre-commit/pre-commit-hooks\n"
  "    rev: v6.0.0\n"
  "    hooks:\n"
  "      - id: no-commit-to-branch\n"
)


def _git(repo: Path, *args: str) -> None:
  subprocess.run(
    ["git", "-C", str(repo), *args],
    check=True,
    capture_output=True,
    text=True,
  )


def _make_repo(tmp_path: Path, branch: str, config: str | None) -> Path:
  """A git repo on `branch` with one commit, optionally carrying a
  pre-commit config."""
  repo = tmp_path / "repo"
  repo.mkdir()
  _git(repo, "init", "-q", "-b", branch)
  _git(
    repo, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q",
    "--allow-empty", "-m", "init"
  )
  if config is not None:
    (repo / ".pre-commit-config.yaml").write_text(config, encoding="utf-8")
  return repo


def _run(tool_input_path: str, cwd: str, tool: str = "Write") -> dict:
  """Invoke the hook with a crafted event; return parsed JSON (or {} when the
  hook emits nothing, i.e. allows)."""
  event = {
    "tool_name": tool,
    "tool_input": {
      "file_path": tool_input_path
    },
    "cwd": cwd,
  }
  res = subprocess.run(
    ["python3", str(HOOK)],
    input=json.dumps(event),
    capture_output=True,
    text=True,
  )
  assert res.returncode == 0, res.stderr    # always fail-safe exit 0
  out = res.stdout.strip()
  return json.loads(out) if out else {}


def _is_deny(out: dict) -> bool:
  return out.get("hookSpecificOutput", {}).get("permissionDecision") == "deny"


def test_blocks_edit_on_protected_master(tmp_path):
  repo = _make_repo(tmp_path, "master", PROTECT_MASTER)
  out = _run(str(repo / "foo.txt"), str(repo))
  assert _is_deny(out)
  assert "master" in out["hookSpecificOutput"]["permissionDecisionReason"]


def test_blocks_edit_for_not_yet_created_file(tmp_path):
  # A Write to a new path (nonexistent file/dir) must still resolve the repo.
  repo = _make_repo(tmp_path, "master", PROTECT_MASTER)
  out = _run(str(repo / "newdir" / "new.txt"), str(repo))
  assert _is_deny(out)


def test_blocks_on_default_branch_when_hook_has_no_args(tmp_path):
  repo = _make_repo(tmp_path, "main", PROTECT_DEFAULTS)
  out = _run(str(repo / "foo.txt"), str(repo))
  assert _is_deny(out)


def test_allows_edit_on_working_branch(tmp_path):
  repo = _make_repo(tmp_path, "master", PROTECT_MASTER)
  _git(repo, "switch", "-q", "-c", "docs/x")
  out = _run(str(repo / "foo.txt"), str(repo))
  assert out == {}


def test_allows_when_repo_declares_no_protection(tmp_path):
  # Foreign / forked repo with no no-commit-to-branch hook → no signal.
  repo = _make_repo(tmp_path, "master", config=None)
  out = _run(str(repo / "foo.txt"), str(repo))
  assert out == {}


def test_allows_plan_files_even_on_protected_branch(tmp_path):
  repo = _make_repo(tmp_path, "master", PROTECT_MASTER)
  plan = repo / "config" / "claude" / "plans" / "p.md"
  out = _run(str(plan), str(repo))
  assert out == {}


def test_allows_outside_any_git_repo(tmp_path):
  out = _run(str(tmp_path / "loose.txt"), str(tmp_path))
  assert out == {}


@pytest.mark.parametrize("tool", ["Bash", "Read", "Grep"])
def test_ignores_non_edit_tools(tmp_path, tool):
  repo = _make_repo(tmp_path, "master", PROTECT_MASTER)
  out = _run(str(repo / "foo.txt"), str(repo), tool=tool)
  assert out == {}
