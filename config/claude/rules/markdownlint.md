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

Config lives at `dot-general/.markdownlintrc`, symlinked to
`~/.markdownlintrc`. Active rule overrides:

| Rule | Setting | Reason |
|------|---------|--------|
| MD004 | disabled | unordered list style not enforced |
| MD033 | disabled | inline HTML allowed |
| MD013 | `line_length: 200` | long lines permitted; hard wrap not required |

## Agent Behavior

- After creating or modifying any Markdown file matched by the paths above:
  1. Run `markdownlint <file>` and fix all reported issues.
- Wrap Markdown prose at 78 columns (per `CONVENTIONS.md`) unless a line
  contains a URL or code span that would break if wrapped.
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes.
