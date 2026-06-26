#!/usr/bin/env python3

"""PostToolUse hook: auto-bless an md5 guard after the agent edits its file.

Some files are guarded against un-managed (out-of-band) changes by a committed
`<name>.md5` checksum sibling — e.g. this dotfiles repo's `shell-startup` /
`shell-startup.md5`, watched by the shell-startup-guard skill. The guard's job
is to catch changes that did NOT come through the agent (a tool installer
writing into ~/.bashrc, a manual edit). For that to work, the agent's OWN edits
must keep the checksum current, or every managed edit would look like drift.

So: after an Edit/Write/MultiEdit, if the touched file has a git-tracked
sibling `<name>.md5`, regenerate that checksum to match the new content (the
md5sum format, so `md5sum -c` and the guard script agree). The agent then just
stages the refreshed `.md5` alongside its edit.

Scope is deliberately narrow and self-gating: it acts ONLY where a tracked
`<name>.md5` already exists, so it is inert in every repo that has no such
guard. Fail-open: any problem — no sibling, not tracked, not in a repo, a read
error — exits 0 silently and never blocks or mutates anything unexpected. It is
global config, so it must stay safe in every repo.
"""

import hashlib
import json
import subprocess
import sys
from pathlib import Path

TIMEOUT_S = 10


def _is_tracked(path: Path) -> bool:
  """True if `path` is tracked in its git repo."""
  try:
    proc = subprocess.run(
      ["git", "ls-files", "--error-unmatch", path.name],
      cwd=path.parent,
      capture_output=True,
      text=True,
      timeout=TIMEOUT_S,
    )
  except Exception:
    return False

  return proc.returncode == 0


def main() -> int:
  try:
    event = json.load(sys.stdin)
  except Exception:
    return 0

  file_path = (event.get("tool_input") or {}).get("file_path")
  if not file_path:
    return 0

  path = Path(file_path)
  if not path.is_file():
    return 0

  sumfile = path.with_name(path.name + ".md5")
  if not sumfile.is_file() or not _is_tracked(sumfile):
    return 0

  # Compute the new checksum in md5sum's text format: "<hex>  <name>\n".
  # md5 is for drift detection, not security (matches the md5sum baseline) —
  # usedforsecurity=False documents that and satisfies SAST (Bandit B324).
  try:
    digest = hashlib.md5(path.read_bytes(), usedforsecurity=False).hexdigest()
  except OSError:
    return 0

  line = f"{digest}  {path.name}\n"

  try:
    if sumfile.read_text(encoding="utf-8") == line:
      return 0     # already current — nothing to do
    sumfile.write_text(line, encoding="utf-8")
  except OSError:
    return 0

  message = (
    f"Auto-blessed {sumfile.name}: regenerated the md5 guard for "
    f"{path.name} (just edited). Stage {sumfile.name} alongside {path.name} "
    "so the checksum stays in lockstep with the file."
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
