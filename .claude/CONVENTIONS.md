# Coding Conventions

**Version:** v1.0.0

This document defines coding standards, style rules, and development
principles for this repository. It is repository-specific and overrides
the generic principles in `CLAUDE.md`.

**Precedence:** This file > `CLAUDE.md`

## General Development Principles

*The Pragmatic Programmer* (Hunt & Thomas) provides a comprehensive set
of development principles; apply its guidance broadly where applicable.
The principles below are a working subset relevant to this repository.

- Keep modules small and focused on a single responsibility.
- Follow DRY (Don't Repeat Yourself).
- Follow the Unix philosophy: do one thing, do it well.
- Use clear, descriptive, intent-revealing names throughout.
- Document complex logic inline; avoid obvious or redundant comments.
- **Executables:** fail fast. **Libraries:** surface errors by
  returning/raising, never by calling `exit`.
- Design for graceful degradation; report errors clearly to stderr.
- Optimize based on measurements; avoid premature optimization.

## Documentation Style

- Wrap Markdown at 78 columns.
- Wrap code comments at 72 columns.
- Use GitHub-flavored Markdown.
- Use reference-style links for readability.

## Commit Conventions

- Use Conventional Commits format for all commit messages.
- Keep the subject line under 72 characters.
- Wrap body at 72 columns.
- Reference issues where applicable: `Fixes #123`, `Relates to #456`.
