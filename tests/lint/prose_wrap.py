#!/usr/bin/env python3

"""Lint agent-config Markdown for two wrap-related defects.

1. **Overlong prose.** `CONVENTIONS.md` / `code-style.md` wrap Markdown prose
   at 78 columns, but markdownlint's `line_length` is set to 200 (so long
   table rows and code lines pass) — which lets 79-80-col prose slip through.
   This counts **characters** (not bytes, so an em-dash — three UTF-8 bytes
   but one column — is not miscounted, the trap that fools `awk length`) and
   flags any prose line over the limit. It exempts what legitimately exceeds
   78 and must not wrap: fenced code, YAML frontmatter, table rows (two or
   more `|`), reference-link definitions, ATX headings, and lines whose only
   overage is an unbreakable inline-code / URL / `[text](url)` token.

2. **Code spans broken mid-identifier.** An inline-code span split across a
   line break rejoins with an errant internal space (an identifier arriving as
   two space-separated words) — a rendering bug the 78-col reflow surfaces on
   one line. Flag a code span that has a single internal space right after a
   `-` / `_` / `/` / `.` in an otherwise space-free token. To document the bug
   itself, put the broken example inside a fenced code block, which this check
   skips.

File selection (which trees to scan, which to skip — vendored plugins, the
cached changelog, agent memory/plan dirs) is the pre-commit hook's job via its
`files:` / `exclude:` regex; this script checks whatever paths it is given.
Exits non-zero when any file has a defect, printing `path:line: message`.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

LIMIT = 78

# A reference-style link definition: `[label]: https://…`.
REF_LINK_RE = re.compile(r"^\s*\[[^\]]+\]:\s+\S")

# Unbreakable tokens that legitimately push a line past the limit. Collapsing
# them to a single stand-in tells whether the *prose* alone is overlong.
MDLINK_RE = re.compile(r"\[[^\]]*\]\([^)]*\)")   # [text](url)
INLINE_CODE_RE = re.compile(r"`[^`]+`")          # `code`
URL_RE = re.compile(r"<?https?://\S+>?")         # bare or <bracketed> URL

FENCE_RE = re.compile(r"^\s*(?:```|~~~)")

# An ATX heading (`## …`) is a single structural line that cannot soft-wrap,
# so it is exempt like a table or code line — shortening it means changing the
# heading text, which is a content edit, not a reformat.
HEADING_RE = re.compile(r"^\s*#{1,6}\s")

# A code span with one internal space right after `-_/.` in an otherwise
# space-free token — the signature of an identifier/path broken across a line
# and rejoined (e.g. `foo-` + `bar` → `foo- bar`). Multi-word command spans
# (`git log --oneline`) don't match: the space isn't glued to punctuation.
BROKEN_SPAN_RE = re.compile(r"`[^ `]+[-_/.] [A-Za-z][^ `]*`")


def _collapse(line: str) -> str:
  """`line` with unbreakable tokens (links, inline code, URLs) reduced to a
  short stand-in, so its length reflects the wrappable prose only."""
  collapsed = MDLINK_RE.sub("x", line)
  collapsed = INLINE_CODE_RE.sub("x", collapsed)
  return URL_RE.sub("x", collapsed)


def violations(path: Path) -> list[tuple[int, str]]:
  """`(line_number, message)` for every defect in `path`."""
  hits: list[tuple[int, str]] = []
  in_code = False
  in_front = False

  for num, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
    stripped = line.strip()

    # Frontmatter: a `---` fence pair opening the file.
    if num == 1 and stripped == "---":
      in_front = True
      continue

    if in_front:
      if stripped == "---":
        in_front = False
      continue

    if FENCE_RE.match(line):
      in_code = not in_code
      continue

    if in_code:
      continue

    # Code-span break — checked on every non-code line, regardless of length.
    if BROKEN_SPAN_RE.search(line):
      hits.append((
        num, "code span has an errant internal space "
        "(identifier broken across a line?)"
      ))

    if len(line) <= LIMIT:
      continue

    if line.count("|") >= 2 or REF_LINK_RE.match(line):
      continue

    if HEADING_RE.match(line):
      continue

    if len(_collapse(line)) <= LIMIT:
      continue

    hits.append((num, f"prose line is {len(line)} cols (limit {LIMIT})"))

  return hits


def main(argv: list[str]) -> int:
  found = False

  for arg in argv:
    path = Path(arg)

    try:
      hits = violations(path)
    except (OSError, UnicodeDecodeError):
      continue

    for (num, message) in hits:
      found = True
      print(f"{path}:{num}: {message}")

  return 1 if found else 0


if __name__ == "__main__":
  sys.exit(main(sys.argv[1:]))
