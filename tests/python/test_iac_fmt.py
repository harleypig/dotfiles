"""Tests for the iac-fmt PostToolUse hook.

Runs the hook as a subprocess (the way Claude Code invokes it) with a stubbed
`terraform` / `packer` on PATH, so the tests are hermetic — no real
terraform/packer/docker needed. See config/claude/hooks/iac-fmt.py.
"""

import json
import os
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
HOOK = REPO_ROOT / "config" / "claude" / "hooks" / "iac-fmt.py"

# `terraform`/`packer fmt` print the reformatted filename and exit 0.
STUB_REFORMAT = (
  "#!/usr/bin/env bash\n"
  'if [ "$1" = fmt ]; then echo "$2"; fi\n'
  "exit 0\n"
)
# fmt hits an unparseable file: writes to stderr and exits non-zero.
STUB_FMT_ERROR = (
  "#!/usr/bin/env bash\n"
  'if [ "$1" = fmt ]; then echo "Error: unclosed block" >&2; exit 1; fi\n'
  "exit 0\n"
)
# fmt is clean (no output); any other subcommand (validate) also succeeds.
STUB_CLEAN = "#!/usr/bin/env bash\nexit 0\n"
# fmt clean, but validate (anything that is not `fmt`) fails.
STUB_VALIDATE_FAIL = (
  "#!/usr/bin/env bash\n"
  'if [ "$1" = fmt ]; then exit 0; fi\n'
  'echo "Error: invalid configuration" >&2\n'
  "exit 1\n"
)


def _stub(tmp_path, tool, body):
  d = tmp_path / ("stub_" + tool)
  d.mkdir(exist_ok=True)
  f = d / tool
  f.write_text(body, encoding="utf-8")
  f.chmod(0o755)
  return d


def _iac_file(proj, name, content="x = 1\n"):
  proj.mkdir(parents=True, exist_ok=True)
  f = proj / name
  f.write_text(content, encoding="utf-8")
  return f


def _run(file_path, cwd, path):
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


def _context(out):
  return out.get("hookSpecificOutput", {}).get("additionalContext", "")


def _path(stub_dir):
  return str(stub_dir) + os.pathsep + os.environ["PATH"]


def test_terraform_reformat_is_reported(tmp_path):
  proj = tmp_path / "proj"
  f = _iac_file(proj, "main.tf")
  ctx = _context(
    _run(
      str(f), str(proj), _path(_stub(tmp_path, "terraform", STUB_REFORMAT))
    )
  )
  assert "Reformatted" in ctx


def test_terraform_fmt_error_is_reported(tmp_path):
  proj = tmp_path / "proj"
  f = _iac_file(proj, "main.tf")
  ctx = _context(
    _run(
      str(f), str(proj), _path(_stub(tmp_path, "terraform", STUB_FMT_ERROR))
    )
  )
  assert "could not format" in ctx
  assert "unclosed block" in ctx


def test_terraform_clean_is_silent(tmp_path):
  proj = tmp_path / "proj"
  f = _iac_file(proj, "main.tf")
  # No .terraform/ -> validate is skipped; clean fmt -> no message.
  assert _run(
    str(f), str(proj), _path(_stub(tmp_path, "terraform", STUB_CLEAN))
  ) == {}


def test_terraform_validate_runs_when_initialized(tmp_path):
  proj = tmp_path / "proj"
  f = _iac_file(proj, "main.tf")
  # mark the dir initialized so validate runs
  (proj / ".terraform").mkdir()
  ctx = _context(
    _run(
      str(f), str(proj),
      _path(_stub(tmp_path, "terraform", STUB_VALIDATE_FAIL))
    )
  )
  assert "terraform validate" in ctx


def test_packer_reformat_is_reported(tmp_path):
  proj = tmp_path / "proj"
  f = _iac_file(proj, "build.pkr.hcl")
  ctx = _context(
    _run(str(f), str(proj), _path(_stub(tmp_path, "packer", STUB_REFORMAT)))
  )
  assert "Reformatted" in ctx


def test_skips_non_iac_file(tmp_path):
  proj = tmp_path / "proj"
  f = _iac_file(proj, "notes.txt")
  # Stub present but must never be invoked for a non-IaC file.
  assert _run(
    str(f), str(proj), _path(_stub(tmp_path, "terraform", STUB_REFORMAT))
  ) == {}


def test_fail_open_when_tool_absent(tmp_path):
  proj = tmp_path / "proj"
  f = _iac_file(proj, "main.tf")
  # PATH without a terraform stub -> tool missing -> silent fail-open.
  empty = tmp_path / "empty"
  empty.mkdir()
  assert _run(str(f), str(proj), str(empty)) == {}
