#!/usr/bin/env python3

"""PreToolUse hook: remind on `terraform import` to verify it is additive.

Fires on a terraform import command — invoked directly
(`terraform … import …`) or through a docker-wrapper convenience script
(`bin/tf <module> import …`). The hook matches the *command string* Claude
submits, so it never needs to know about a repo-local `bin/tf`; a hook does
not intercept the subprocess the wrapper spawns, only the top-level command.

It does **not** hard-block. Whether a target address is already in state can
only be answered by querying the remote backend (`terraform state list`),
which needs credentials the hook does not have: each Bash call sources
`. set_env` inside its own shell, so the creds live only in the command's
shell, never this hook's environment. A best-effort check would near-always
fail-open, so the hook stays a reminder.

It injects a just-in-time reminder of the import-safety rule so the
verify-first step is not skipped (e.g. after a context compaction):

  - additive import (target address NOT yet in state) is fine, with the
    user's confirmation;
  - importing onto an ALREADY-managed address is a re-import/overwrite —
    operator-only, never the agent — because it can corrupt real state.

Fail-safe: any error exits 0 silently so a hook bug can never block a
command. Reminder-only — it never denies.
"""

from __future__ import annotations

import json
import re
import sys

# A terraform import invocation, either directly (`terraform`) or via the
# `bin/tf` wrapper (with or without a `./` / `../` path prefix). The tool must
# be followed by whitespace, so a hyphenated mention like the filename
# `terraform-import-safety.py` (in `cat …`, `pre-commit --files …`, etc.) does
# NOT match. `import` is a whitespace-delimited subcommand on the same command
# segment (stop at `; | &`), so `terraform … plan` / `bin/tf … state list` do
# not match. Prose that literally contains "terraform import" (e.g. a commit
# message) can still match — harmless, since the hook only reminds.
IMPORT_RE = re.compile(r"(?:\bterraform|\bbin/tf)\s+(?:[^\n;|&]*\s+)?import\b")

REMINDER = (
  "terraform import detected — verify BEFORE importing (import-safety rule):\n"
  " - Additive import (the target address is NOT yet in state) is fine with "
  "the user's confirmation.\n"
  " - Importing onto an ALREADY-managed address is a re-import/overwrite: "
  "operator-only, never the agent — it can corrupt real state.\n"
  " - So FIRST run `terraform -chdir=<module> state list` (or `bin/tf "
  "<module> state list`) and confirm the target address is NOT listed. If it "
  "is, stop and hand the overwrite to the operator. If the task mixes new and "
  "already-managed addresses, do the additive ones and hand the rest over."
)


def main() -> int:
  try:
    event = json.load(sys.stdin)
  except Exception:
    return 0

  if event.get("tool_name") != "Bash":
    return 0

  command = (event.get("tool_input") or {}).get("command") or ""
  if not IMPORT_RE.search(command):
    return 0

  print(
    json.dumps({
      "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": REMINDER,
      }
    })
  )
  return 0


if __name__ == "__main__":
  sys.exit(main())
