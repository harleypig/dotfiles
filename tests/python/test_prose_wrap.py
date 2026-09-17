"""Tests for the markdown-hygiene check (tests/lint/prose_wrap.py).

Runs the checker as a subprocess against throwaway Markdown files, covering
both the overlong-prose detection (with each exemption) and the
broken-code-span detection, plus the `--fix` reflow mode. See the script for
the conventions it enforces.
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


def _run_fix(path: Path) -> subprocess.CompletedProcess:
  return subprocess.run(
    [sys.executable, str(SCRIPT), "--fix",
     str(path)],
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


def test_heading_exempt(tmp_path):
  # A long ATX heading cannot soft-wrap, so it is exempt (shortening it would
  # change the heading text — a content edit, not a reformat).
  res = _run(_md(tmp_path, "### " + "word " * 20 + "\n"))
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


def test_broken_code_span_flagged(tmp_path):
  # An identifier broken across a line rejoins with an errant space.
  res = _run(_md(tmp_path, "The file `config/hooks/ compact.py` moved.\n"))
  assert res.returncode == 1
  assert "errant internal space" in res.stdout


def test_command_span_not_flagged(tmp_path):
  # Multi-word command spans have spaces not glued to punctuation — fine.
  ok = "Run `git log --oneline`, then `rm -rf build/` and `claude -p`.\n"
  res = _run(_md(tmp_path, ok))
  assert res.returncode == 0, res.stdout


def test_wrapped_multiword_span_not_flagged(tmp_path):
  # A long command span legitimately wrapped across lines renders with a
  # space, but the space isn't glued to punctuation — not a broken identifier.
  body = (
    "Example: `/goal get the score to 90 or\n"
    "above, stop after 5 tries`.\n"
  )
  res = _run(_md(tmp_path, body))
  assert res.returncode == 0, res.stdout


def test_broken_span_inside_fence_ignored(tmp_path):
  # Documenting the bug: the broken example lives in a fenced block, skipped.
  body = "How it looks:\n\n```\n`foo/ bar`\n```\n\nDon't do that.\n"
  res = _run(_md(tmp_path, body))
  assert res.returncode == 0, res.stdout


# --fix mode -----------------------------------------------------------


def test_fix_rewraps_overlong_paragraph_under_limit(tmp_path):
  # A single overlong prose paragraph, well past the 78-column limit.
  body = (
    "This is a deliberately long prose paragraph that runs well past the "
    "78-column wrap limit on one physical line, on purpose, so the fixer "
    "has real work to do reflowing it back down to size before anyone "
    "commits it as-is.\n"
  )
  path = _md(tmp_path, body)
  original_words = body.split()

  res = _run_fix(path)
  assert res.returncode == 0, res.stderr

  fixed = path.read_text(encoding="utf-8")
  fixed_lines = fixed.splitlines()

  assert len(fixed_lines) > 1               # it was actually reflowed
  assert all(len(line) <= 78 for line in fixed_lines)
  assert fixed.split() == original_words    # same words, same order

  # The fixer's own output is now clean under the checker.
  check = _run(path)
  assert check.returncode == 0, check.stdout


def test_fix_resolves_cascading_overflow(tmp_path):
  # The friction the issue names: a hand-wrapped paragraph where every line
  # runs past the limit, the exact shape one moved word cascades into.
  body = ("x" * 70 + " word " * 4 + "\n" + "y" * 70 + " word " * 4 + "\n")
  path = _md(tmp_path, body)

  res = _run_fix(path)
  assert res.returncode == 0, res.stderr

  fixed_lines = path.read_text(encoding="utf-8").splitlines()
  assert all(len(line) <= 78 for line in fixed_lines)


def test_fix_leaves_fenced_code_untouched(tmp_path):
  body = "```\n" + "x" * 120 + "\n```\n"
  path = _md(tmp_path, body)
  res = _run_fix(path)
  assert res.returncode == 0, res.stderr
  assert path.read_text(encoding="utf-8") == body


def test_fix_leaves_heading_untouched(tmp_path):
  body = "### " + "word " * 20 + "\n"
  path = _md(tmp_path, body)
  res = _run_fix(path)
  assert res.returncode == 0, res.stderr
  assert path.read_text(encoding="utf-8") == body


def test_fix_leaves_table_row_untouched(tmp_path):
  body = "| " + "col | " * 20 + "\n"
  path = _md(tmp_path, body)
  res = _run_fix(path)
  assert res.returncode == 0, res.stderr
  assert path.read_text(encoding="utf-8") == body


def test_fix_leaves_list_item_untouched(tmp_path):
  # A long list item is left for hand-fixing; reflowing bullet text risks
  # mangling list structure (the issue's own "weigh against").
  body = "- " + "word " * 20 + "\n"
  path = _md(tmp_path, body)
  res = _run_fix(path)
  assert res.returncode == 0, res.stderr
  assert path.read_text(encoding="utf-8") == body


def test_fix_never_splits_inline_code_span(tmp_path):
  # A multi-word inline-code span inside an overlong paragraph must stay on
  # one line after reflow — splitting it would introduce the exact
  # errant-internal-space defect check 2 exists to catch.
  span = "`git log --oneline --graph --decorate --all`"
  body = (
    f"Run the tool with a long invocation like {span} to walk the full "
    "history laid out end to end in one pass, front to back.\n"
  )
  path = _md(tmp_path, body)

  res = _run_fix(path)
  assert res.returncode == 0, res.stderr

  fixed = path.read_text(encoding="utf-8")
  assert span in fixed

  check = _run(path)
  assert "errant internal space" not in check.stdout


def test_fix_is_idempotent(tmp_path):
  body = "word " * 30 + "\n"
  path = _md(tmp_path, body)

  assert _run_fix(path).returncode == 0
  first = path.read_text(encoding="utf-8")

  assert _run_fix(path).returncode == 0
  second = path.read_text(encoding="utf-8")

  assert first == second
