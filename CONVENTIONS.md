# Coding Conventions

**Version:** v1.0.0

This document defines coding standards, style rules, and development
principles for this repository. It is repository-specific and overrides
the generic principles in `CLAUDE.md`.

**Precedence:** This file > `CLAUDE.md`

## General Development Principles

- Keep modules small and focused on a single responsibility.
- Follow DRY (Don't Repeat Yourself).
- Follow the Unix philosophy: do one thing, do it well.
- Use clear, descriptive, intent-revealing names throughout.
- Document complex logic inline; avoid obvious or redundant comments.
- Validate and test all AI-generated code before recommending it.
- **Executables:** fail fast. **Libraries:** surface errors by
  returning/raising, never by calling `exit`.
- Design for graceful degradation; report errors clearly to stderr.
- Optimize based on measurements; avoid premature optimization.

## Resource Validity

- Before recommending a tool, library, or pattern, verify it is actively
  maintained and reflects current security practices.
- Treat patterns from the pre-2010 era as presumed obsolete unless
  explicitly justified for historical or educational reasons.

## Code Style

### Shell Scripts

- Lint with `shellcheck` (no errors or warnings permitted).
- Format with `shfmt -i 2 -ci` (2-space indent, indent switch cases).
- Bash shebang: `#!/usr/bin/env bash`
- POSIX sh shebang: `#!/bin/sh`

### Documentation

- Wrap Markdown at 78 columns.
- Wrap code comments at 72 columns.
- Use GitHub-flavored Markdown.
- Use reference-style links for readability.

### Python

- Format with `black`.
- Sort imports with `isort`.
- Lint with `flake8`.
- Type hints where appropriate; check with `mypy`.

### Perl

- Format with `perltidy`.
- Lint with `perlcritic` (level 4 or above).

### PowerShell

- Follow PowerShell best practices.
- Use approved verbs for function names.
- Add comment-based help to all functions.

## Error Handling

### Shell Scripts (Executables)

- Use `set -euo pipefail` for strict error handling.
- Return meaningful exit codes: 0=success, 1=general error,
  2=usage error.
- Provide clear error messages to stderr.

### Shell Libraries (Sourced Files)

- Do NOT use `set -e`; it affects the sourcing shell.
- Surface errors by returning non-zero exit codes.
- Do NOT call `exit`; document error conditions and return codes.

## Commit Conventions

- Use Conventional Commits format for all commit messages.
- Keep the subject line under 72 characters.
- Wrap body at 72 columns.
- Reference issues where applicable: `Fixes #123`, `Relates to #456`.
