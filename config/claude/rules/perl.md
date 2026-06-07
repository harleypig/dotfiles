---
paths:
  - "**/*.pl"
  - "**/*.pm"
  - "**/*.t"
---

# Perl Style

- Format with `perltidy`.
- Lint with `perlcritic --severity 4` (severity 4 = gentle; lower numbers
  are stricter, 1 = brutal).

## Agent Behavior

- After creating or modifying any Perl file matched by the paths above:
  1. Run `perltidy -b <file>` to format in place (`-b` backs up the
     original as `<file>.bak`; delete the backup after confirming).
  2. Run `perlcritic --severity 4 <file>` and fix all reported violations.
- **Prefer pre-commit** when the repo has it (see `pre-commit.md`):
  `pre-commit run --files <file>` to check, and `pre-commit run --config
  .pre-commit-config-fix.yaml --files <file>` to fix. Fall back to the direct
  invocation above only when pre-commit isn't configured or doesn't cover the
  file.
