# Coding Conventions

**Version:** v1.2.0

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
- Wrap code comments at 78 columns.
- Use GitHub-flavored Markdown.
- Use reference-style links for readability.

## Commit Conventions

- Use Conventional Commits format for all commit messages.
- Keep the subject line under 72 characters.
- Wrap body at 72 columns.
- Reference issues where applicable: `Fixes #123`, `Relates to #456`.

## Quality Assurance

This repo's QA map — the concrete tools, commands, and a per-dimension
status for every dimension in the global QA pipeline (the dotagents repo's
`rules/qa.md`) — lives in [`QA.md`](QA.md). The **qa-check** skill reads it.

## Shell-startup Module Placement

`config/shell-startup/` modules are sourced by `shell-startup` for **both**
interactive and non-interactive login shells — there is no global
interactivity guard, so any bare `export` lands in every shell, and each
module must self-guard its interactive-only content with
`[[ $- == *i* ]] || return 0`. (The user-facing module list lives in
[`README.md`](../README.md) *Modular Configuration*.)

Place a tool's setup by this rubric — the "env-vs-bin split":

- **1–2 settings** → `010-general` or `app_env_vars`; don't spawn a module.
- **More than that** → its own module.
- **Tool-only, on-demand env** — vars a *rarely-run* tool needs that would
  otherwise be exported into every shell → a `bin/` wrapper that sets the env
  and `exec`s the tool (`set env; exec <tool> "$@"`), **not** shell-startup.
- **Genuine interactive-shell features** — aliases, shell functions, prompt
  wiring, completion sourcing, keybindings, `less`/`git` interactive wiring —
  **stay in the environment** (a module or `010-general`). A wrapper can't
  provide these, and a `PATH`/env value a tool needs when invoked *indirectly*
  (as a git editor, from cron, by another tool) must live here too, not in a
  wrapper.

Hygiene within a module:

- `unset` module-scope temp vars — and `unset -f` setup-only functions —
  at the end, so startup leaves no scratch in the shell.
- Don't `export -f` a function unless a **child process** genuinely needs it;
  `export -f` pushes it into every child's environment.
- **Vendor** a tool's completion to `config/completions/<tool>` and source
  that, rather than `source <(<tool> completion bash)` which forks the tool on
  every shell — and gate the sourcing behind the `[[ $- == *i* ]]` guard.
