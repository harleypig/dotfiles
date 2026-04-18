---
paths:
  - "**/*.md"
---

# markdownlint Rules

**Version:** v1.0.0

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

**This repo:** config lives at `dot-general/.markdownlintrc`, managed via
dotlinks (symlinked to `~/.markdownlintrc`). `dot-general/` holds dotfiles
that live directly under `$HOME`. A repo-level `.markdownlint.json` would
take priority if one is added. Active rule overrides:

| Rule | Setting | Reason |
|------|---------|--------|
| MD004 | disabled | unordered list style not enforced |
| MD033 | disabled | inline HTML allowed |
| MD013 | `line_length: 200` | linter won't flag lines under 200; CONVENTIONS.md still requires 78-col prose wrap |

## Agent Behavior

- After creating or modifying any Markdown file matched by the paths above:
  1. Run `markdownlint <file>` and fix all reported issues.
- Wrap Markdown prose at 78 columns (per `CONVENTIONS.md`) unless a line
  contains a URL or code span that would break if wrapped.
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes.
