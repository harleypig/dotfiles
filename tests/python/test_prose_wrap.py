"""Tests for the prose-wrap check (tests/lint/prose_wrap.py).

Runs the checker as a subprocess against throwaway Markdown files, covering
the overlong-prose detection and each exemption. See the script for the
convention it enforces.
"""

import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SCRIPT = REPO_ROOT / "tests" / "lint" / "prose_wrap.py"


def _run(path: Path) -> subprocess.CompletedProcess:
  return subprocess.run(
    [sys.executable, str(SCRIPT), str(path)],
    capture_output=True,
    text=True,
  )


def _md(tmp_path: Path, body: str) -> Path:
  f = tmp_path / "doc.md"
  f.write_text(body, encoding="utf-8")
  return f


def test_clean_file_passes(tmp_path):
  res = _run(_md(tmp_path, "A short prose line well under the limit.\n"))
  assert res.returncode == 0
  assert res.stdout == ""


def test_overlong_prose_flagged(tmp_path):
  res = _run(_md(tmp_path, "word " * 20 + "\n"))      # 100 cols
  assert res.returncode == 1
  assert "doc.md:1:" in res.stdout


def test_char_count_not_byte_count(tmp_path):
  # 78 characters where several are em-dashes (3 UTF-8 bytes each). A
  # byte-counting check would call this overlong; a character-counting one
  # must not. Regression guard for the em-dash trap the check exists to avoid.
  line = "x" * 74 + "—" * 4  # 78 characters, 74 + 4*3 = 86 bytes
  assert len(line) == 78
  res = _run(_md(tmp_path, line + "\n"))
  assert res.returncode == 0, res.stdout


def test_table_row_exempt(tmp_path):
  row = "| " + "col | " * 20 + "\n"    # long, but a table row
  res = _run(_md(tmp_path, row))
  assert res.returncode == 0, res.stdout


def test_fenced_code_exempt(tmp_path):
  body = "```\n" + "x" * 120 + "\n```\n"
  res = _run(_md(tmp_path, body))
  assert res.returncode == 0, res.stdout


def test_frontmatter_exempt(tmp_path):
  body = "---\ndescription: " + "d" * 120 + "\n---\n\nBody.\n"
  res = _run(_md(tmp_path, body))
  assert res.returncode == 0, res.stdout


def test_reference_link_exempt(tmp_path):
  body = "[ref]: https://example.com/" + "a" * 100 + "\n"
  res = _run(_md(tmp_path, body))
  assert res.returncode == 0, res.stdout


def test_url_only_overage_exempt(tmp_path):
  # Prose short, but a long bare URL pushes past the limit — unbreakable.
  body = "See the docs at https://example.com/" + "path/" * 20 + "\n"
  res = _run(_md(tmp_path, body))
  assert res.returncode == 0, res.stdout


def test_prose_overage_with_short_url_flagged(tmp_path):
  # A genuinely overlong prose line is still flagged even when it contains a
  # (short) link — collapsing the link leaves the prose over the limit.
  body = "This is a deliberately long prose sentence that runs well past " \
         "the wrap limit and also mentions [a link](x) inline here too.\n"
  res = _run(_md(tmp_path, body))
  assert res.returncode == 1
  assert "doc.md:1:" in res.stdout
