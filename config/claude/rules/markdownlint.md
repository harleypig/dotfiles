---
paths:
  - "**/*.md"
---

# markdownlint Rules

**Version:** v1.1.0

## Invocation

```bash
markdownlint <file>
```

No errors are permitted. Fix all reported issues before committing.

## Configuration File

**Discovery order** (first match wins within each tier):

1. Project-level (current directory only): `.markdownlint.jsonc`,
   `.markdownlint.json`, `.markdownlint.yaml`, `.markdownlint.yml`
2. `.markdownlintrc` — searched from current directory up to filesystem
   root, then: `~/.markdownlintrc`, `~/.markdownlint/config`,
   `~/.config/markdownlint`, `~/.config/markdownlint/config`, `/etc/…`

**Note:** markdownlint hardcodes `~/.config/markdownlint` — it does NOT
read `$XDG_CONFIG_HOME`. This only works automatically when `$XDG_CONFIG_HOME`
is the default `~/.config`.

**This repo:** uses a **repo-local `.markdownlint.json`** at the repo root —
authoritative for this repo and auto-discovered by the pre-commit
`markdownlint` / `markdownlint-fix` hooks (it wins over `~/.markdownlintrc`
per the discovery order above). The legacy global `dot-general/.markdownlintrc`
(symlinked to `~/.markdownlintrc`) is being retired in favour of per-repo
configs (see `TODO.md`). Active rule overrides:

| Rule | Setting | Reason |
|------|---------|--------|
| MD004 | disabled | unordered list style not enforced |
| MD033 | disabled | inline HTML allowed |
| MD041 | disabled | a file may open with an import (`@WORKFLOW.md`) or a badge, not an h1 |
| MD060 | disabled | table-column-style (pipe alignment) is cosmetic churn |
| MD024 | `siblings_only: true` | duplicate headings allowed under different parents |
| MD013 | `line_length: 200`, `tables: false`, `code_blocks: false` | don't flag long table rows / code lines; CONVENTIONS.md still requires 78-col prose wrap |

## Agent Behavior

- After creating or modifying any Markdown file matched by the paths above:
  1. Run `markdownlint <file>` and fix all reported issues.
- Wrap Markdown prose at 78 columns (per `CONVENTIONS.md`) unless a line
  contains a URL or code span that would break if wrapped.
- **Prefer pre-commit** when the repo has it (see `pre-commit.md`):
  `pre-commit run --files <file>` to check, and `pre-commit run --config
  .pre-commit-config-fix.yaml --files <file>` to fix. Fall back to the direct
  invocation above only when pre-commit isn't configured or doesn't cover the
  file.
