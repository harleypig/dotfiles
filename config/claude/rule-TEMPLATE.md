---
# List glob patterns for files this tool applies to.
# Omit the paths key entirely for tools that are not file-type-specific
# (e.g. git, gh).
paths:
  - "**/*.ext"  # replace .ext with actual extension(s)
---

# <Tool> Rules

**Version:** v1.0.0

## Invocation

```bash
<tool> <file>
```

Brief description of what the command does and when to use it.

## Configuration File

Where the config lives, how it is resolved, and any Docker wrapper notes.

## Sources

What this rule is grounded in (per `EXTENDING.md` *Grounding & sourcing*) —
the official docs / man page(s) it is built on, so it can be re-checked when
the tool changes. State "house convention — no external source" if none
applies.

- <official doc URL, or `man <tool>` / `<tool> --help` / `/usr/share/doc/<pkg>`>

## Agent Behavior

- After creating or modifying any file matched by the paths above:
  1. Step one.
  2. Step two.
- **Prefer pre-commit** when the repo has it (see `pre-commit.md`):
  `pre-commit run --files <file>` to check, and `pre-commit run --config
  .pre-commit-config-fix.yaml --files <file>` to fix. Fall back to the direct
  invocation above only when pre-commit isn't configured or doesn't cover the
  file.
