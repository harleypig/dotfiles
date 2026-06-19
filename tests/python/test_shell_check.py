"""Tests for the shell-check PostToolUse hook.

Runs the hook as a subprocess (the way Claude Code invokes it) with a stubbed
`shellcheck` on PATH, so the tests are hermetic — no real shellcheck / docker
needed. See the hook under config/claude/hooks/shell-check.py.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "config" / "claude" / "hooks" / "shell-check.py"

# A shellcheck stub that reports one finding and exits non-zero.
STUB_FAIL = (
  "#!/usr/bin/env bash\n"
  'echo "In $1 line 2:"\n'
  'echo "SC2086 (info): Double quote to prevent globbing."\n'
  "exit 1\n"
)
# A shellcheck stub that finds nothing.
STUB_PASS = "#!/usr/bin/env bash\nexit 0\n"


def _stub_dir(tmp_path: Path, body: str) -> Path:
  d = tmp_path / "stubbin"
  d.mkdir(exist_ok=True)
  sc = d / "shellcheck"
  sc.write_text(body, encoding="utf-8")
  sc.chmod(0o755)
  return d


def _shell_file(proj: Path, name: str, content: str) -> Path:
  proj.mkdir(parents=True, exist_ok=True)
  f = proj / name
  f.write_text(content, encoding="utf-8")
  return f


def _run(file_path: str, cwd: str, path: str) -> dict:
  """Invoke the hook with a crafted event and a custom PATH (launched via the
  absolute interpreter, so PATH governs only the hook's shellcheck lookup).
  Return parsed JSON ({} when the hook stays silent)."""
  event = {
    "tool_name": "Write",
    "tool_input": {
      "file_path": file_path
    },
    "cwd": cwd,
  }
  res = subprocess.run(
    [sys.executable, str(HOOK)],
    input=json.dumps(event),
    capture_output=True,
    text=True,
    env={"PATH": path},
  )
  assert res.returncode == 0, res.stderr    # always fail-safe exit 0
  out = res.stdout.strip()
  return json.loads(out) if out else {}


def _context(out: dict) -> str:
  return out.get("hookSpecificOutput", {}).get("additionalContext", "")


def test_reports_findings_on_shell_file(tmp_path):
  proj = tmp_path / "proj"
  f = _shell_file(proj, "s.sh", "#!/usr/bin/env bash\necho $foo\n")
  path = str(_stub_dir(tmp_path, STUB_FAIL)) + os.pathsep + os.environ["PATH"]
  assert "SC2086" in _context(_run(str(f), str(proj), path))


def test_silent_when_clean(tmp_path):
  proj = tmp_path / "proj"
  f = _shell_file(proj, "s.sh", "#!/usr/bin/env bash\necho ok\n")
  path = str(_stub_dir(tmp_path, STUB_PASS)) + os.pathsep + os.environ["PATH"]
  assert _run(str(f), str(proj), path) == {}


def test_detects_shell_by_shebang(tmp_path):
  # Extension-less script with a shell shebang is still checked.
  proj = tmp_path / "proj"
  f = _shell_file(proj, "myscript", "#!/usr/bin/env bash\necho $x\n")
  path = str(_stub_dir(tmp_path, STUB_FAIL)) + os.pathsep + os.environ["PATH"]
  assert "SC2086" in _context(_run(str(f), str(proj), path))


def test_skips_non_shell_file(tmp_path):
  proj = tmp_path / "proj"
  f = _shell_file(proj, "notes.txt", "just text\n")
  # FAIL stub present but must never be invoked for a non-shell file.
  path = str(_stub_dir(tmp_path, STUB_FAIL)) + os.pathsep + os.environ["PATH"]
  assert _run(str(f), str(proj), path) == {}


def test_skips_python_shebang(tmp_path):
  proj = tmp_path / "proj"
  f = _shell_file(proj, "tool", "#!/usr/bin/env python3\nprint(1)\n")
  path = str(_stub_dir(tmp_path, STUB_FAIL)) + os.pathsep + os.environ["PATH"]
  assert _run(str(f), str(proj), path) == {}


def test_skips_file_outside_project(tmp_path):
  proj = tmp_path / "proj"
  proj.mkdir()
  f = _shell_file(
    tmp_path / "elsewhere", "s.sh", "#!/usr/bin/env bash\necho $foo\n"
  )
  path = str(_stub_dir(tmp_path, STUB_FAIL)) + os.pathsep + os.environ["PATH"]
  # File is not under cwd=proj -> skip before running shellcheck.
  assert _run(str(f), str(proj), path) == {}


def test_fail_open_when_shellcheck_absent(tmp_path):
  proj = tmp_path / "proj"
  f = _shell_file(proj, "s.sh", "#!/usr/bin/env bash\necho $foo\n")
  empty = tmp_path / "empty"
  empty.mkdir()
  # PATH lacks shellcheck entirely -> FileNotFoundError -> fail-open silent.
  assert _run(str(f), str(proj), str(empty)) == {}
