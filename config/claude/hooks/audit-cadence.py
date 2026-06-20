#!/usr/bin/env python3

"""SessionStart hook: a once-a-day nudge that a claude-audit pass is due.

Wired in settings.json for SessionStart sources startup/resume/clear (NOT
compact — that has its own compact-snapshot.py). It injects a short
additionalContext suggesting a quick `/claude-audit` pass, deduped to at most
one nudge per calendar day via a state file, so it reminds without nagging
every session.

The audit re-evaluates the global config from whatever repo invoked it (by
design — see the claude-audit skill, "Global is re-evaluated from every
repo"), so the nudge is global, not dotfiles-only.

Fail-safe: any error exits 0 silently so the session is never disrupted.
"""

from __future__ import annotations

import datetime
import json
import os
import sys
from pathlib import Path

NUDGE = (
  "Audit cadence (daily nudge): a `/claude-audit` pass is due. Quick pass — "
  "scan enabled plugins/MCP and obvious always-on bloat; run a deeper audit "
  "periodically. The audit re-evaluates the global config from whatever repo "
  "you're in (by design). Decisions are recorded in "
  "config/claude/audit/decisions-log.md. Fires at most once per day; skip it "
  "if now isn't the time."
)

#------------------------------------------------------------------------------
# The per-day dedup marker lives in the XDG state dir; it holds the date
# of the last nudge (YYYY-MM-DD). A separate file (not a project state
# dir) because the cadence is global, not per-repo.


def _state_file() -> Path:
  base = os.environ.get("XDG_STATE_HOME") or os.path.join(
    os.path.expanduser("~"), ".local", "state"
  )

  return Path(base) / "claude-audit-cadence"


def _already_nudged_today(state: Path, today: str) -> bool:
  try:
    return state.read_text(encoding="utf-8").strip() == today
  except OSError:
    return False


def _record(state: Path, today: str) -> None:
  state.parent.mkdir(parents=True, exist_ok=True)
  state.write_text(today + "\n", encoding="utf-8")


def main() -> int:
  try:
    json.load(sys.stdin)
  except Exception:
    return 0

  today = datetime.date.today().isoformat()
  state = _state_file()

  if _already_nudged_today(state, today):
    return 0

  _record(state, today)

  print(
    json.dumps({
      "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": NUDGE,
      }
    })
  )

  return 0


if __name__ == "__main__":
  sys.exit(main())
