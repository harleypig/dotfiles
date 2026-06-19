# Idea sources

Repos mined for ideas during setup audits — re-check on each audit. Audit-only
(not context-loaded). The full per-item disposition census lives in
[`mining-census.md`](mining-census.md); the open CANDIDATE backlog in
[`BACKLOG.md`](BACKLOG.md); decisions in [`decisions-log.md`](decisions-log.md).

This registry is **broader** than any per-skill
`SOURCE.md`: it lists every repo we have looked to for inspiration, **whether
or not we reused its implementation**, so a future audit knows where to look
again. The two are distinct by design:

- **This registry** — "places worth picking the brains of." Idea-level. A repo
  appears here even if we liked a concept but wrote our own implementation.
- **Per-artifact `SOURCE.md`** — provenance for a *specific* skill/command.
  A repo is cited there **only when we reused implementation details** from it
  (so there is something concrete to track for upstream updates). Liked the
  idea but used none of the code → it stays here, not in a `SOURCE.md`.

| Repo | Mined for | License | Last mined | Reused impl? |
|------|-----------|---------|-----------|--------------|
| `ruslan-korneev/claude-plugins` | FastAPI/Pydantic DTO+repository+exception patterns; Alembic enum-handling; python `lint-explain`/`test-first`/`clean-review` commands; `tech-lead` ADR/arch-review/modernize commands | MIT | 2026-06-11 | Yes → fastapi-patterns, sqlalchemy-patterns |
| `fastapi/fastapi` (official `.agents/skills`) | FastAPI best-practice concepts (Annotated, return-type serialization, async-vs-sync); maintained with new versions, so re-mine on FastAPI upgrades | MIT | 2026-06-11 | No (concepts only) |
| `rafaelkamimura/claude-tools` | Layered-architecture ideas; candidate commands (`adr`, `tech-debt`, `debug-assistant`) and agents (`database-optimizer`, `api-documenter`) | MIT | 2026-06-11 | No (ideas only) |
| `pydantic/skills` (official) | Pydantic AI **agent-framework** + Logfire skills — relevant only if we adopt LLM agents or Logfire observability; not used today | MIT (check) | 2026-06-11 | No |
| `fabioc-aloha/spotify-skill` | Spotify Web API skill — endpoint/scope/error inventory, auto-refresh pattern, `ugc-image-upload`→401, cover-art + playlist strategies; refs are stale (pre-2024-11-27, no PKCE) so official docs win | Apache-2.0 | 2026-06-12 | Ideas → `spotify-audit` + `rules/spotify.md` (SOURCE.md) |

The **full disposition census** of every item in these repos (every agent /
command / hook / skill considered, ADOPT/CANDIDATE/SKIP + reason) is in
[`mining-census.md`](mining-census.md). The open CANDIDATE backlog lives there
too. The
source-discovery method (official-first → stars+recency+health; the >1yr
staleness gate) and the full-census/generic-lens practice are documented in the
**claude-audit** skill (*Mining repos for ideas*).
