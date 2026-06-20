"""Tests for the extra-planning-docs mechanism of the merge-finalization hook.

Runs the hook as a subprocess against a throwaway repo with a crafted
PreToolUse merge event. Covers the per-repo `merge-finalization-docs:`
declaration that lets a repo enforce the prune on planning docs beyond the
generic defaults (e.g. the audit BACKLOG.md). See the hook under
config/claude/hooks/.
"""

import json
import os
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "config" / "claude" / "hooks" / "merge-finalization.py"


def _make_repo(
  tmp_path: Path,
  *,
  declare_extra: bool = True,
  extra_has_done: bool = True,
) -> Path:
  """A repo opted in to merge-finalization, optionally declaring an extra
  planning doc, whose extra doc optionally carries a completed `- [x]` item."""
  repo = tmp_path / "repo"
  (repo / ".claude").mkdir(parents=True)

  wf = "# Workflow\n\nmerge-finalization: enforce\n"
  if declare_extra:
    wf += "\nmerge-finalization-docs: config/audit/BACKLOG.md\n"
  (repo / ".claude" / "WORKFLOW.md").write_text(wf, encoding="utf-8")

  backlog_dir = repo / "config" / "audit"
  backlog_dir.mkdir(parents=True)
  body = "- [ ] still open\n"
  if extra_has_done:
    body += "- [x] completed but not pruned\n"
  (backlog_dir / "BACKLOG.md").write_text(body, encoding="utf-8")

  return repo


def _run(repo: Path, command: str = "gh pr merge 1 --squash") -> dict:
  event = {
    "tool_name": "Bash",
    "tool_input": {
      "command": command
    },
    "cwd": str(repo),
  }
  env = {k: v for k, v in os.environ.items() if k != "CLAUDE_PROJECT_DIR"}
  res = subprocess.run(
    ["python3", str(HOOK)],
    input=json.dumps(event),
    capture_output=True,
    text=True,
    env=env,
  )
  assert res.returncode == 0, res.stderr
  out = res.stdout.strip()
  return json.loads(out) if out else {}


def _hook_out(out: dict) -> dict:
  return out.get("hookSpecificOutput", {})


def test_blocks_merge_when_declared_extra_doc_has_done_items(tmp_path):
  out = _hook_out(_run(_make_repo(tmp_path)))
  assert out.get("permissionDecision") == "deny"
  assert "BACKLOG.md" in out.get("permissionDecisionReason", "")


def test_allows_merge_when_declared_extra_doc_is_clean(tmp_path):
  out = _hook_out(_run(_make_repo(tmp_path, extra_has_done=False)))
  assert "permissionDecision" not in out    # reminder-only, not a block
  assert "additionalContext" in out


def test_extra_doc_ignored_without_declaration(tmp_path):
  # The extra doc still carries a [x], but it is not declared, so the hook
  # checks only the generic defaults (absent here) and allows.
  out = _hook_out(_run(_make_repo(tmp_path, declare_extra=False)))
  assert "permissionDecision" not in out


def test_non_merge_command_is_ignored(tmp_path):
  assert _run(_make_repo(tmp_path), command="git status") == {}
