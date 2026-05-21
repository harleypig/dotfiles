# HTML Rules

**Version:** v1.0.0

## Parsing HTML — prefer html2text

Before writing custom HTML parsing code (Python `html.parser`, BeautifulSoup,
bash scraping with `grep`/`sed`, ad-hoc `python3 -c` scripts, etc.), try
`html2text` first. It converts HTML to plain text or Markdown in one command
and handles tag stripping, link extraction, and encoding without any code.

Two variants are available on this system:

### System html2text (C-based, v1.3.2a)

```bash
html2text <file>
html2text <url>
curl -s <url> | html2text
```

Plain ASCII output. Good for quickly reading rendered HTML or stripping tags.
Understands `-style compact` / `-style pretty` and `-width <n>`.

### Python html2text (v2024.2.26, produces Markdown)

```bash
python3 -m html2text <file>
curl -s <url> | python3 -m html2text
```

Produces Markdown-structured output (headings, bold, links as `[text](url)`).
Better when you need to preserve document structure or feed output to further
Markdown processing. Supports `--ignore-links`, `--ignore-images`,
`--body-width 0` (no wrapping), and many others; run with `--help` to see all.

## When to use each

| Need | Tool |
|------|------|
| Strip tags, get plain text | system `html2text` |
| Preserve structure (headings, links) | `python3 -m html2text` |
| Extract specific elements (tables, lists) | `python3 -m html2text`, then parse Markdown |
| Complex scraping / DOM traversal | BeautifulSoup — but ask first |

## Agent Behavior

- Before writing any HTML-parsing code, check whether `html2text` or
  `python3 -m html2text` can satisfy the need in a one-liner.
- Use `python3 -m html2text --body-width 0` when piping output to further
  tools so lines are not artificially wrapped.
- Fall back to BeautifulSoup or a custom parser only when the task
  genuinely requires DOM traversal or structured data extraction that
  text/Markdown output cannot provide. Surface this decision to the user.
