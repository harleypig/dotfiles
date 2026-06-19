#!/usr/bin/env python3

"""PostToolUse hook: shellcheck a shell file right after it is edited.

After an Edit/Write/MultiEdit, if the touched file is a shell script, run
shellcheck and surface any findings to the agent (via additionalContext — the
same channel rule-coverage.py uses) so a shell bug is caught at edit time, not
only at commit. Check-only and non-blocking: it never modifies the file and
never blocks the tool. Formatting (shfmt) stays with the commit-time fix
config; this is the bug-catching linter only.

Fail-open: any problem — no shellcheck on PATH, the file outside the project,
a non-shell file, a timeout — exits 0 silently, so the hook can never wedge an
edit. It is global config, so it must stay safe in every repo.
"""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

SHELL_EXTS = {".sh", ".bash"}
SHEBANG_SH = re.compile(r"\b(?:ba|da|k)?sh\b")
TIMEOUT_S = 25


def _is_shell(path: Path) -> bool:
  """True for a .sh/.bash file, or an extension-less script with a shell
  shebang (bin/, lib/, config/shell-startup/, ...)."""
  if path.suffix.lower() in SHELL_EXTS:
    return True

  try:
    with path.open("r", encoding="utf-8", errors="replace") as fh:
      first = fh.readline()
  except OSError:
    return False

  return first.startswith("#!") and bool(SHEBANG_SH.search(first))


def main() -> int:
  try:
    event = json.load(sys.stdin)
  except Exception:
    return 0

  file_path = (event.get("tool_input") or {}).get("file_path")
  if not file_path:
    return 0

  path = Path(file_path)
  if not path.is_file() or not _is_shell(path):
    return 0

  project_dir = (
    os.environ.get("CLAUDE_PROJECT_DIR") or event.get("cwd") or os.getcwd()
  )

  # bin/shellcheck is a docker wrapper that mounts $PWD and needs the file
  # path relative to (and under) $PWD. Run from the project dir with a
  # relative path; if the file is not under it, skip (fail-open).
  try:
    rel = path.resolve().relative_to(Path(project_dir).resolve())
  except ValueError:
    return 0

  try:
    proc = subprocess.run(
      ["shellcheck", str(rel)],
      cwd=project_dir,
      capture_output=True,
      text=True,
      timeout=TIMEOUT_S,
    )
  except Exception:
    return 0

  if proc.returncode == 0:
    return 0

  findings = (proc.stdout or proc.stderr or "").strip()
  if not findings:
    return 0

  message = (
    f"shellcheck flagged {rel} (just edited) — fix before continuing:\n\n"
    f"{findings}\n\n"
    "(PostToolUse shell-check hook, check-only. Per shellcheck.md no errors "
    "or warnings are permitted; an inline `# shellcheck disable=SCxxxx` needs "
    "a reason comment.)"
  )

  print(
    json.dumps({
      "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": message,
      }
    })
  )
  return 0


if __name__ == "__main__":
  sys.exit(main())
