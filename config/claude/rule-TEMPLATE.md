---
# Declare the load tier — a conformance guard (test_rule_frontmatter.bats)
# enforces that this block has one or the other, so a rule can't silently
# join the expensive always-on tier by omission:
#  - Path-scoped (on-demand): keep `paths:` with the globs this rule applies
#    to.
#  - Always-on (every turn): for a rule not tied to a file type (e.g. git,
#    gh), DELETE the `paths:` key and replace it with a documenting
#    `# No paths — <why>` comment. Do NOT leave the block empty.
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
