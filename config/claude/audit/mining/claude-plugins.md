# Mining matrix — `ruslan-korneev/claude-plugins`

Part of the mining census (`../mining-census.md` has the disposition key and
the cross-repo CANDIDATE backlog). MIT. Round 2026-06-11. 4 plugins, 59 items.

## tech-lead plugin (16 cmd, 9 agent, 4 skill)

The architecture/codebase-analysis cluster is the strongest generic find.

| name | type | scope | disp. | reason |
|------|------|-------|-------|--------|
| deps | cmd | generic | CANDIDATE | module dependency analysis + coupling metrics (Ca/Ce/I), circular deps |
| dependency-analyzer | agent | generic | CANDIDATE | same, deeper — instability scoring, layer violations |
| arch-review | cmd | generic | CANDIDATE | architecture audit (layers, DI, anti-patterns) — deeper than `/review` |
| architecture-reviewer | agent | generic | CANDIDATE | Opus-grade architecture audit (10-point) |
| diagram | cmd | generic | CANDIDATE | Mermaid architecture diagrams (component/ER/sequence/deploy) |
| modernize | cmd | generic | CANDIDATE | legacy assessment + Strangler-Fig roadmap |
| codebase-explorer | agent | generic | CANDIDATE | fast project-structure discovery (feeds planning) |
| codebase-analyzer | agent | generic | CANDIDATE | extract entities/endpoints/services from existing code |
| planning-agent | agent | generic | CANDIDATE | deep planning w/ memory anchors (overlaps built-in Plan) |
| feature-designer | agent | generic | CANDIDATE | greenfield BR/US/AC design |
| design | cmd | generic | CANDIDATE | interactive architecture design + scaffold |
| feature-specification | skill | generic | CANDIDATE | structured spec format (BR/US/AC) |
| architecture-patterns | skill | stack | CANDIDATE | FastAPI/SQLAlchemy system patterns — overlaps our skills |
| dev, execute, execution-agent, tdd-workflow | cmd/agent/skill | generic | CANDIDATE-low | TDD orchestration — overlaps built-in Plan + manual TDD |
| adr | cmd | generic | SKIP | **adopted** as the `adr` skill |
| review, code-review (skill), code-reviewer, quick-reviewer | cmd/skill/agent | generic | SKIP | overlap `/code-review`, `/review`, `/simplify` |
| features:init/add/status/graph/analyze/design (×6) | cmd | niche | SKIP | feature-spec-workflow scaffolding (adopt only with that workflow) |

## python plugin (10 cmd, 4 skill, 1 agent, 1 hook)

| name | type | scope | disp. | reason |
|------|------|-------|-------|--------|
| pytest-patterns | skill | generic | CANDIDATE | production pytest/TDD depth — could enrich like fastapi-patterns did |
| typing-patterns | skill | generic | CANDIDATE | Python typing depth (no `type: ignore`) — augments python.md |
| test-reviewer | agent | generic | CANDIDATE | coverage + test-quality (AAA/naming) analysis |
| lint:explain, typecheck:explain | cmd | generic | SKIP | no-suppression policy already in ruff.md + python.md; explain = normal agent capability |
| test:first | cmd | generic | SKIP | testing.md bar; TDD on request |
| clean:review, clean-code-patterns | cmd/skill | generic | SKIP | code-style.md + qa.md Code-style audit + `/simplify` |
| lint, lint:config, typecheck, ruff-patterns | cmd/skill | generic | SKIP | ruff.md + python.md + qa-check pipeline |
| test:fixture, test:mock | cmd | generic | SKIP | low-level helpers; testing.md covers |
| hooks.json (ruff/mypy on edit) | hook | generic | SKIP | conflicts with "auto-fixers run once" (pre-commit) — already declined |

## fastapi plugin (5 cmd, 2 skill, 1 agent)

| name | type | scope | disp. | reason |
|------|------|-------|-------|--------|
| fastapi:module | cmd | stack | CANDIDATE | full-module generator — speed over fastapi-patterns prose |
| fastapi:endpoint | cmd | stack | CANDIDATE | endpoint+service+test scaffolder |
| fastapi:migrate:create | cmd | stack | CANDIDATE | Alembic create w/ enum-downgrade auto-fix |
| fastapi:migrate:check / migration-reviewer | cmd/agent | stack | CANDIDATE | pre-apply migration review — automates the sqlalchemy-patterns checklist |
| fastapi:dto | cmd | stack | SKIP | DTO patterns in fastapi-patterns |
| fastapi-patterns, alembic-patterns | skill | stack | SKIP | adopted / covered by alembic.md |

## linear plugin (4 cmd, 1 skill, 1 agent)

| name | scope | disp. | reason |
|------|-------|-------|--------|
| board, comment, cycle, delete, linear-api, issue-enricher (×6) | niche | SKIP | Linear SaaS integration — only if the user adopts Linear |
