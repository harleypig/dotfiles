"""Tests for the terraform-import-safety PreToolUse hook.

Runs the hook as a subprocess (the way Claude Code invokes it), feeding a Bash
command and asserting whether it injects the import-safety reminder. Hermetic —
no terraform / docker needed, since the hook only pattern-matches the command
string. See the hook under config/claude/hooks/terraform-import-safety.py.
"""

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "config" / "claude" / "hooks" / "terraform-import-safety.py"


def _run(command: str, tool: str = "Bash") -> dict:
  """Invoke the hook with a crafted event; return parsed JSON ({} when the
  hook stays silent). The hook always fail-safe exits 0."""
  event = {"tool_name": tool, "tool_input": {"command": command}}
  res = subprocess.run(
    [sys.executable, str(HOOK)],
    input=json.dumps(event),
    capture_output=True,
    text=True,
  )
  assert res.returncode == 0, res.stderr
  out = res.stdout.strip()
  return json.loads(out) if out else {}


def _reminds(command: str, tool: str = "Bash") -> bool:
  out = _run(command, tool)
  return "additionalContext" in out.get("hookSpecificOutput", {})


# --- real import invocations: remind ---


def test_direct_terraform_import():
  assert _reminds("terraform import addr 123")


def test_terraform_import_with_chdir_and_set_env():
  assert _reminds(". set_env; terraform -chdir=account import 'module.x.y' 1")


def test_bin_tf_import():
  assert _reminds("bin/tf account import addr 123")


def test_relative_bin_tf_import():
  assert _reminds("../bin/tf account import addr 123")


# --- false positives that must stay silent ---


def test_filename_mention_in_precommit_is_silent():
  # The hook filename literally contains "terraform...import"; a command that
  # only references it (hyphenated path, no whitespace after "terraform") must
  # not fire. This was a real regression.
  assert not _reminds(
    "pre-commit run --files config/claude/hooks/terraform-import-safety.py"
  )


def test_cat_hook_file_is_silent():
  assert not _reminds("cat config/claude/hooks/terraform-import-safety.py")


# --- non-import terraform commands: silent ---


def test_terraform_plan_is_silent():
  assert not _reminds("terraform -chdir=account plan")


def test_bin_tf_state_list_is_silent():
  assert not _reminds("bin/tf account state list")


# --- non-Bash tools and junk: silent / fail-safe ---


def test_non_bash_tool_is_silent():
  assert not _reminds("terraform import addr 123", tool="Edit")


def test_empty_command_is_silent():
  assert not _reminds("")


def test_malformed_json_exits_zero():
  res = subprocess.run(
    [sys.executable, str(HOOK)],
    input="not json",
    capture_output=True,
    text=True,
  )
  assert res.returncode == 0
  assert res.stdout.strip() == ""
