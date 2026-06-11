# ADR-0001: Skills over custom commands for invokable procedures

- **Status:** Accepted
- **Date:** 2026-06-11

## Context

Claude Code offers two ways to package a named, on-demand procedure the user
triggers explicitly: a **skill** (invoked by name, e.g. `/claude-audit`, runs
in the main context) and a **custom slash command** (a `commands/` file). The
global config has so far used skills exclusively — `commands/` does not exist.
Mining community repos surfaced several `/command`-shaped capabilities (ADR
scaffolding, lint-explain, migrate-check), forcing the question of whether to
introduce the first custom command and a `commands/` dir.

## Decision

We will package invokable procedures as **skills**, not custom commands.
Skills are invoked the same way (`/name`), so nothing is lost ergonomically.
A new capability that would otherwise be a slash command becomes a skill (ADR
itself is adopted as the `adr` skill, per this decision).

## Alternatives considered

### Adopt custom commands (the upstream form) — rejected

Most mined items ship as `/command` files, so adopting them verbatim is less
work up front. Rejected because it splits invokable procedures across two
mechanisms with no functional gain: skills already trigger by name, run in the
main context, and carry richer description-based auto-triggering. A second
mechanism is surface to maintain and reason about for no benefit.

### One mechanism, but make it commands instead of skills — rejected

Could standardize on commands and migrate skills. Rejected: skills are the
established, working choice here (qa-check, ship-pr, git-worktree-workflow,
…), support agent-spawning and description-triggering, and the user prefers
them. Migrating would be churn against the grain.

## Consequences

- `config/claude/commands/` stays absent; new named procedures are skills.
- Mined `/command` ideas are re-homed as skills (or rules), adapted to house
  idiom rather than vendored — see ADR-0002.
- Not absolute: a genuinely command-shaped need (trivial, argument-driven, no
  procedure) could still justify introducing `commands/` later — that would be
  a new ADR superseding this one, not a silent exception.
