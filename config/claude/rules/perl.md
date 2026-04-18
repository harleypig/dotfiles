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
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes.
