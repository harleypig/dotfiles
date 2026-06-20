"""Tests for the audit-cadence SessionStart hook.

Runs the hook as a subprocess (the way Claude Code invokes it), pointing
XDG_STATE_HOME at a throwaway dir so the per-day dedup marker never touches
real state. Asserts it nudges once per calendar day and stays silent on
repeat runs the same day. See the hook under config/claude/hooks/.
"""

import datetime
import json
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "config" / "claude" / "hooks" / "audit-cadence.py"

TODAY = datetime.date.today().isoformat()


def _run(state_home: Path, payload: str | None = None) -> dict:
  """Invoke the hook with XDG_STATE_HOME redirected; return parsed JSON (or {}
  when the hook emits nothing)."""
  event = '{"hook_event_name": "SessionStart", "source": "startup"}'
  res = subprocess.run(
    ["python3", str(HOOK)],
    input=event if payload is None else payload,
    capture_output=True,
    text=True,
    env={
      "XDG_STATE_HOME": str(state_home),
      "HOME": str(state_home)
    },
  )
  assert res.returncode == 0, res.stderr    # always fail-safe exit 0
  out = res.stdout.strip()
  return json.loads(out) if out else {}


def _ctx(out: dict) -> str:
  return out.get("hookSpecificOutput", {}).get("additionalContext", "")


def _marker(state_home: Path) -> Path:
  return state_home / "claude-audit-cadence"


def test_nudges_on_first_run_of_day(tmp_path):
  out = _run(tmp_path)
  assert "/claude-audit" in _ctx(out)
  assert _marker(tmp_path).read_text(encoding="utf-8").strip() == TODAY


def test_silent_on_second_run_same_day(tmp_path):
  assert _ctx(_run(tmp_path)) != ""    # first run nudges
  assert _run(tmp_path) == {}          # second run is silent


def test_nudges_again_when_marker_is_an_earlier_day(tmp_path):
  _marker(tmp_path).write_text("2000-01-01\n", encoding="utf-8")
  out = _run(tmp_path)
  assert "/claude-audit" in _ctx(out)
  assert _marker(tmp_path).read_text(encoding="utf-8").strip() == TODAY


def test_creates_missing_state_dir(tmp_path):
  nested = tmp_path / "deep" / "state"
  out = _run(nested)
  assert "/claude-audit" in _ctx(out)
  assert _marker(nested).exists()


def test_failsafe_on_bad_json(tmp_path):
  assert _run(tmp_path, payload="not json") == {}
  assert not _marker(tmp_path).exists()     # nothing recorded on a no-op
