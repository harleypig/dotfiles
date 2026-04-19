---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "bin/**"
  - "lib/**"
  - "shell-startup"
  - "config/shell-startup/**"
  - "config/claude/bin/**"
---

# Bash / Shell Style

## Scripts (Executables)

- Shebang: `#!/usr/bin/env bash` for bash; `#!/bin/sh` for POSIX sh.
- Use `set -euo pipefail` near the top (fail fast on errors, unset
  variables, and pipe failures).
- Lint with `shellcheck` (no errors or warnings permitted).
- Format with `shfmt` (see `shfmt.md` for flags and invocation).
- Return meaningful exit codes: 0=success, 1=general error, 2=usage error.
- Provide clear error messages to stderr.
- Include a usage/help function.

## Libraries (Sourced Files)

- Do NOT use `set -e` or `set -euo pipefail`; it affects the sourcing shell.
- Surface errors by returning non-zero exit codes.
- Do NOT call `exit`; document error conditions and return codes.

## Agent Behavior

- After creating or modifying any shell file matched by the paths above,
  follow the pipeline defined in `shfmt.md` (format) then `shellcheck.md`
  (lint).
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes.
