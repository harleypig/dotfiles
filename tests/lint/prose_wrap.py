#!/usr/bin/env python3

"""Flag Markdown *prose* lines wider than the 78-column wrap convention.

`CONVENTIONS.md` / `code-style.md` wrap Markdown prose at 78 columns, but
markdownlint's `line_length` is set to 200 (so long table rows and code lines
pass) — which lets 79-80-col prose slip through unnoticed. This check closes
that gap for the lines a formatter can't judge: it counts **characters** (not
bytes, so an em-dash — three UTF-8 bytes but one column — is not miscounted,
the exact trap that fools `awk length`) and reports any prose line over the
limit.

It exempts the constructs that legitimately exceed 78 and must not wrap:

- fenced code blocks (``` / ~~~),
- YAML frontmatter (the leading `---` … `---` block, e.g. a long
  `description:`),
- table rows (two or more `|`),
- reference-style link definitions (`[label]: url`),
- lines whose only overage is an unbreakable token — an inline-code span,
  a bare URL, or a `[text](url)` link target — measured by re-checking the
  length with those tokens collapsed.

File selection (which trees to scan, which to skip — vendored plugins, the
cached changelog, agent memory/plan dirs) is the pre-commit hook's job via
its `files:` / `exclude:` regex; this script checks whatever paths it is
given. Exits non-zero when any file has a violation, printing `path:line`.
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


def _collapse(line: str) -> str:
  """`line` with unbreakable tokens (links, inline code, URLs) reduced to a
  short stand-in, so its length reflects the wrappable prose only."""
  collapsed = MDLINK_RE.sub("x", line)
  collapsed = INLINE_CODE_RE.sub("x", collapsed)
  return URL_RE.sub("x", collapsed)


def violations(path: Path) -> list[tuple[int, int]]:
  """`(line_number, width)` for every overlong prose line in `path`."""
  hits: list[tuple[int, int]] = []
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

    if in_code or len(line) <= LIMIT:
      continue

    if line.count("|") >= 2 or REF_LINK_RE.match(line):
      continue

    if len(_collapse(line)) <= LIMIT:
      continue

    hits.append((num, len(line)))

  return hits


def main(argv: list[str]) -> int:
  found = False

  for arg in argv:
    path = Path(arg)

    try:
      hits = violations(path)
    except (OSError, UnicodeDecodeError):
      continue

    for (num, width) in hits:
      found = True
      print(f"{path}:{num}: prose line is {width} cols (limit {LIMIT})")

  return 1 if found else 0


if __name__ == "__main__":
  sys.exit(main(sys.argv[1:]))
