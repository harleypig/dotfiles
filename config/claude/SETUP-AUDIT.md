# Claude Code Setup Audit

**Status:** index for the Claude Code setup-audit records. This file is tracked
but **not** context-loaded (it is not a rule), so it costs nothing per turn.

The audit keeps the agent's configuration lean (context economy) and each
artifact in the right place and right form, across the global config
(`config/claude/`) and each repo it runs from.

## Methodology

The audit *procedure* is the **`claude-audit`** skill
([`skills/claude-audit/SKILL.md`](skills/claude-audit/SKILL.md)) — the
canonical, runnable methodology: measure via a read-only inventory agent →
classify by load tier → recommend by cost × (1 − relevance) → confirm → record.
Run it with `/claude-audit`. (This file no longer carries a separate "How to
run" — the skill owns the procedure; this is only the record's index.)

## The record

The living record lives in sibling files under [`audit/`](audit/):

- [`decisions-log.md`](audit/decisions-log.md) — chronological decisions (the
  "why"), append-only.
- [`BACKLOG.md`](audit/BACKLOG.md) — open audit follow-ups; a todo file,
  separate from the repo's own `TODO.md`.
- [`idea-sources.md`](audit/idea-sources.md) — repos mined for ideas.
- [`mining-census.md`](audit/mining-census.md) — full per-item
  ADOPT/CANDIDATE/SKIP disposition of mined repos.

## Baseline — 2026-06-19

The always-on (per-turn) tier is lean; the leverage findings from the
2026-06-10 baseline (drop unused MCP plugins, path-scope single-language
rules) are all resolved — see [`audit/decisions-log.md`](audit/decisions-log.md).

| Tier | State |
|------|-------|
| Always-on rules | 8 unscoped: the 7 cross-cutting (`code-style`, `documentation`, `gh`, `git`, `qa`, `testing`, `troubleshooting`) plus `claude-code-auth` (a conversational-trigger guardrail with no file glob — kept always-on by design). `trufflehog` was scoped to `.github/workflows/**` (2026-06-19). 43 rules are `paths:`-scoped (on-demand, incl. `new-project` added 2026-06-19). |
| MCP tool schemas | context7 only, via `mymcp` at user scope. terraform / serena dropped (2026-06-10). |
| Plugins | 1 enabled (`skill-creator`); all other marketplace plugins disabled. |
| Hooks | 5 bespoke (`branch-protection`, `merge-finalization`, `rule-coverage`, `shell-check`, `compact-snapshot`). |
| Always-on memory | global `CLAUDE.md` + the repo's `.claude/` (WORKFLOW / CONVENTIONS / TESTS). |
