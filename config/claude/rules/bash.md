---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "bin/**"
  - "lib/**"
  - "shell-startup"
  - "config/shell-startup/**"
---

# Bash / Shell Style

## Scripts (Executables)

- Shebang: `#!/usr/bin/env bash` for bash; `#!/bin/sh` for POSIX sh.
- Lint with `shellcheck` (no errors or warnings permitted).
- Format with `shfmt -i 2 -ci` (2-space indent, indent switch cases).
- Return meaningful exit codes: 0=success, 1=general error, 2=usage error.
- Provide clear error messages to stderr.
- Include a usage/help function.

## Libraries (Sourced Files)

- Do NOT use `set -e`; it affects the sourcing shell.
- Surface errors by returning non-zero exit codes.
- Do NOT call `exit`; document error conditions and return codes.
