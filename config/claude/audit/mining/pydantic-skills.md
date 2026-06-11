# Mining matrix — `pydantic/skills` (official)

Part of the mining census (`../mining-census.md` has the disposition key and
the cross-repo CANDIDATE backlog). MIT. Round 2026-06-11. 5 skills.
First-party (re-mine on releases).

| name | scope | disp. | reason |
|------|-------|-------|--------|
| building-pydantic-ai-agents, pydantic-ai-harness | niche | CANDIDATE-if-building-agents | the `pydantic_ai` agent framework — see the deferred `rules/pydantic-ai.md` backlog item |
| logfire-instrumentation, logfire-query, logfire-ui | niche | CANDIDATE-if-adopting-Logfire | observability platform — adopt if Logfire is used |

Note: these are the `pydantic_ai` **agent framework** + Logfire
observability — **not** pydantic-the-validation-library (covered by
`fastapi-patterns` /
`python.md`). Per ADR-0003 they'd be global skills, built the first time any
repo adopts pydantic-ai or Logfire.
