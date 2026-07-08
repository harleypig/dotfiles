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


# --- Target-repo resolution (regression: PRs #38/#40 false-blocked a clean
# --- cross-repo merge on the *session* repo's kept-branch [x] marks).


def _make_simple_repo(
  path: Path,
  *,
  enforce: bool = True,
  has_done: bool = True,
  git: bool = True,
) -> Path:
  """A minimal repo with a generic TODO.md, optionally opted in, optionally
  carrying a completed item, optionally looking like a git clone."""
  (path / ".claude").mkdir(parents=True)

  wf = "# Workflow\n"
  if enforce:
    wf += "\nmerge-finalization: enforce\n"
  (path / ".claude" / "WORKFLOW.md").write_text(wf, encoding="utf-8")

  body = "- [ ] still open\n"
  if has_done:
    body += "- [x] completed but not pruned\n"
  (path / "TODO.md").write_text(body, encoding="utf-8")

  if git:
    (path / ".git").mkdir()

  return path


def test_repo_flag_scans_target_not_session(tmp_path):
  # Session repo is dirty ([x] marks, e.g. a kept branch mid-batch); the
  # merge targets a clean sibling clone via --repo. Must NOT block.
  session = _make_simple_repo(tmp_path / "session")
  _make_simple_repo(tmp_path / "other", has_done=False)

  out = _hook_out(
    _run(session, command="gh pr merge 40 --repo owner/other --squash")
  )
  assert "permissionDecision" not in out


def test_repo_flag_blocks_on_target_items(tmp_path):
  # Inverse: session is clean, the -R target sibling has unpruned items.
  session = _make_simple_repo(tmp_path / "session", has_done=False)
  _make_simple_repo(tmp_path / "other")

  out = _hook_out(_run(session, command="gh pr merge 40 -R owner/other"))
  assert out.get("permissionDecision") == "deny"
  assert "TODO.md" in out.get("permissionDecisionReason", "")


def test_repo_flag_unresolvable_never_blocks(tmp_path):
  # --repo names a repo with no local clone: unverifiable, so remind — never
  # block on the session repo's docs.
  session = _make_simple_repo(tmp_path / "session")

  out = _hook_out(
    _run(session, command="gh pr merge 40 --repo owner/elsewhere --squash")
  )
  assert "permissionDecision" not in out
  assert "cannot be verified" in out.get("additionalContext", "")


def test_repo_flag_matching_session_scans_session(tmp_path):
  # --repo naming the session repo itself still scans (and blocks on) it.
  session = _make_simple_repo(tmp_path / "session")

  out = _hook_out(
    _run(session, command="gh pr merge 40 --repo owner/session --squash")
  )
  assert out.get("permissionDecision") == "deny"


def test_cd_prefix_scans_target(tmp_path):
  # `cd <path> && gh pr merge` runs the merge in <path>; scan there.
  session = _make_simple_repo(tmp_path / "session", has_done=False)
  other = _make_simple_repo(tmp_path / "other")

  out = _hook_out(
    _run(session, command=f"cd {other} && gh pr merge 40 --squash")
  )
  assert out.get("permissionDecision") == "deny"


# --- Quoted / heredoc merge phrases are not real invocations (regression:
# --- PR #224 — a `--body` heredoc quoting `gh pr merge` fired the hook).


def test_merge_phrase_in_commit_message_ignored(tmp_path):
  # A commit message that merely mentions the merge syntax must NOT be treated
  # as a merge (session has unpruned [x] items, so a false match would block).
  session = _make_simple_repo(tmp_path / "session")

  out = _run(session, command='git commit -m "fix gh pr merge false positive"')
  assert out == {}


def test_merge_phrase_in_heredoc_body_ignored(tmp_path):
  # A PR body heredoc quoting the merge syntax must NOT fire the gate.
  session = _make_simple_repo(tmp_path / "session")
  command = (
    "gh pr create --title t --body \"$(cat <<'EOF'\n"
    "## Summary\n- document how `push.sh merge` works\nEOF\n)\""
  )
  assert _run(session, command=command) == {}


def test_real_merge_after_quoted_arg_still_matches(tmp_path):
  # Stripping quotes must not lose a genuine merge chained after a quoted
  # command: `... "done" && push.sh merge N` still blocks on unpruned items.
  session = _make_simple_repo(tmp_path / "session")

  out = _hook_out(
    _run(session, command='echo "all done" && push.sh merge 40 --squash')
  )
  assert out.get("permissionDecision") == "deny"
