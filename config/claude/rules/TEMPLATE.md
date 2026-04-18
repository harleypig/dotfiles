---
# List glob patterns for files this tool applies to.
# Omit the paths key entirely for tools that are not file-type-specific
# (e.g. git, gh).
paths:
  - "**/*.ext"
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

## Agent Behavior

- After creating or modifying any file matched by the paths above:
  1. Step one.
  2. Step two.
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes.
