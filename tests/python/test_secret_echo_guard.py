"""Tests for the secret-echo-guard PreToolUse hook.

Runs the hook as a subprocess (the way Claude Code invokes it), feeding a Bash
command and asserting whether it blocks (permissionDecision "deny"). Hermetic —
the hook only pattern-matches the command string. See the hook under
config/claude/hooks/secret-echo-guard.py.
"""

import json
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "config" / "claude" / "hooks" / "secret-echo-guard.py"


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


def _denies(command: str, tool: str = "Bash") -> bool:
  out = _run(command, tool).get("hookSpecificOutput", {})
  return out.get("permissionDecision") == "deny"


# --- leaks to the terminal: BLOCK ---


def test_bare_secret_echo():
  assert _denies('echo "$LINODE_TOKEN"')


def test_dash_fallback_footgun():
  # The `:-` fallback prints the value when set — the classic mistake.
  assert _denies('echo "${LINODE_TOKEN:-unset}"')


def test_mixed_set_and_value_markers():
  # `${:+set}` is safe but the `${:-UNSET}` beside it leaks — the exact
  # pattern that caused the incidents.
  assert _denies('echo "TOKEN: ${GH_TOKEN:+set}${GH_TOKEN:-UNSET}"')


def test_printf_secret():
  assert _denies("printf '%s\\n' \"$AWS_SECRET_ACCESS_KEY\"")


def test_bare_dollar_no_braces():
  assert _denies("echo $ANTHROPIC_API_KEY")


def test_secret_inside_larger_string():
  assert _denies('echo "api key is $MY_API_KEY today"')


def test_after_command_separator():
  assert _denies('. bin/set_env; echo "$LINODE_TOKEN"')


def test_echo_then_andand():
  assert _denies('echo "$SSH_PRIVATE_KEY" && true')


def test_password_variable():
  assert _denies('echo "$DB_PASSWORD"')


# --- value consumed, not leaked: ALLOW ---


def test_piped_to_consumer():
  assert not _denies('echo "$GH_TOKEN" | gh auth login --with-token')


def test_redirected_to_file():
  assert not _denies("printf '%s' \"$LINODE_TOKEN\" > /tmp/tok")


def test_captured_in_substitution():
  assert not _denies('hash=$(printf "%s" "$API_KEY" | sha256sum)')


# --- safe expansions: ALLOW ---


def test_set_marker_only():
  assert not _denies('echo "${LINODE_TOKEN:+set}"')


def test_set_marker_no_colon():
  assert not _denies('echo "${GH_TOKEN+present}"')


def test_length_expansion():
  assert not _denies('echo "${#AWS_SECRET_ACCESS_KEY}"')


def test_correct_presence_check():
  # The pattern the rule prescribes — no secret value is printed.
  assert not _denies('[[ -n $LINODE_TOKEN ]] && echo set || echo unset')


# --- non-secret / no variable: ALLOW ---


def test_no_variable():
  assert not _denies('echo "nothing secret here"')


def test_non_secret_variable():
  assert not _denies('echo "$PATH"')
  assert not _denies('echo "$USER is here"')


# --- only Bash is inspected ---


def test_non_bash_tool_ignored():
  assert not _denies('echo "$LINODE_TOKEN"', tool="Edit")
