# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source; the implementation is our own (house style, the
derive-from-source procedure, the documentation.md composition).

## Idea sources (NOT tracked)

Recorded in `../../audit/mining/claude-tools.md`:

- `rafaelkamimura/claude-tools` `write-documentation` — multi-format doc
  generation (API / architecture / DB). MIT.
- `rafaelkamimura/claude-tools` `documentation-architect` agent —
  comprehensive docs across stacks. MIT.
- `rafaelkamimura/claude-tools` `api-documenter` agent — OpenAPI/SDK docs;
  folded in as the API-doc **mode**, not a separate skill. MIT.

## Local design decisions

- **Consolidated** three mined items (a command + two agents) into one skill
  — they are facets of one job, authoring docs (Rule of Three).
- **Serves `documentation.md`** (the bar + form stance) rather than restating
  policy — the skill is the *how*, the rule is the *what/why* (DRY).
- **Derive-from-source, not from memory** — read the real signatures/schemas
  so docs are accurate; for stacks that generate docs (FastAPI auto-OpenAPI)
  point at the generated artifact + `fastapi-patterns` (layering principle).
- **Boundaries drawn** — ADRs go to the `adr` skill; session/handoff/standup
  notes and spec→plan are explicitly *not* this skill (different concerns).
- Positioned as the Tier-1 build that **opens the `documentation` category**.
