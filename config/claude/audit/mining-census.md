# Mining census

Full disposition tables for every repo mined for ideas during audits. The
*Idea sources* registry in `SETUP-AUDIT.md` is the index; this file is the
**complete mapping** — every agent / command / hook / skill considered and why
it was or wasn't adopted. Audit-only (not context-loaded).

**Why a full census:** an audit improves the *whole* dev environment, so good
*generic* tooling should spread to every repo. Charting only a curated
shortlist hides what was skipped and biases toward the current repo's stack.
Each mined repo gets a complete table here.

## Disposition key

- **ADOPT** — clear, high-value, low-overlap; build it (as a skill per
  ADR-0001, or a rule/hook if that's the right kind).
- **CANDIDATE** — genuinely worth considering for the global setup; **the
  user decides**. Judged by value to *any* repo, not just the one being
  audited. An agent/command can be a CANDIDATE even though we'd reimplement it
  as a skill.
- **SKIP** — covered by existing tooling, niche/domain-locked, meta-infra, or
  already adopted. Reason given.

Disposition reflects **generic value to the whole environment**, then overlap
with existing built-ins / skills / rules, then the "layer the generic over the
specific" principle (`EXTENDING.md`).

---

## Round 2026-06-11 — FastAPI/SQLAlchemy/Python mining

Sources (all MIT; see *Idea sources* for SHAs/recency): `rafaelkamimura/
claude-tools`, `ruslan-korneev/claude-plugins`, `pydantic/skills`,
`fastapi/fastapi`. **~158 items charted.** Already actioned this round: the
`fastapi-patterns` / `sqlalchemy-patterns` skills and the `adr` skill; the
rest of the CANDIDATEs are an open backlog (triage at the end).

### claude-tools — commands (32)

| name | scope | disp. | reason |
|------|-------|-------|--------|
| brainstorm | generic | CANDIDATE | deep requirements ideation; pairs with built-in Plan |
| bslist | generic | CANDIDATE | list/resume past brainstorm sessions |
| debug-assistant | generic | CANDIDATE | structured debugging harness (stack-trace → repro → fix) |
| deps-update | generic | CANDIDATE | dependency auditor w/ compat testing + changelog |
| dev-docs | generic | CANDIDATE | spec → implementation plan + checklist |
| dev-docs-update | generic | CANDIDATE | capture session state before context-limit reset |
| env-sync | generic | CANDIDATE | .env sync/validation/secret rotation (security-sensitive) |
| handoff | generic | CANDIDATE | task-transfer / onboarding doc generation |
| perf-check | generic | CANDIDATE | profiling (CPU/mem/DB/API) — multi-language |
| read-specs | generic | CANDIDATE | spec → tasks + flow diagrams |
| standup | generic | CANDIDATE | standup notes from git history + todos |
| task-init | generic | CANDIDATE | multi-phase task orchestration (overlaps Plan) |
| tech-debt | generic | CANDIDATE | catalog debt/TODOs/complexity, prioritize by ROI |
| test-suite | generic | CANDIDATE | test runner + coverage delta + missing-test gen (overlaps qa-check) |
| write-documentation | generic | CANDIDATE | multi-format doc generation (API/arch/DB) |
| deploy | stack | CANDIDATE | deployment orchestration — infra/repo-specific |
| rollback | stack | CANDIDATE | recovery/rollback orchestration — infra-specific |
| commit | generic | SKIP | overlaps git/gh rules + ship-pr; msg-gen fights the staging rules |
| mr-draft | stack | SKIP | PR-description gen; overlaps ship-pr + gh PR format; PT-BR |
| review-code | generic | SKIP | built-in `/code-review` + `/simplify` |
| security-scan | generic | SKIP | `security-scan` skill |
| create-skill | generic | SKIP | `skill-creator` plugin |
| sync-config | generic | SKIP | meta — this dotfiles repo + chezmoi already do config-as-code |
| todo-worktree | generic | SKIP | `git-worktree-workflow` skill |
| close/fetch/update-azure-task (×3) | niche | SKIP | Azure DevOps-locked |
| generate-interview, interview-analysis-template, interview-context-storage, pdf-to-markdown, screen-resume (×5) | niche | SKIP | HR/recruitment — not dev tooling |

### claude-tools — agents (46)

| name | scope | disp. | reason |
|------|-------|-------|--------|
| plan-reviewer | generic | CANDIDATE | pre-implementation plan QA (before vs after code) — strong, novel |
| dependency-analyzer-style (see tech-lead) | generic | — | (its analog is in tech-lead; see below) |
| database-optimizer | generic | CANDIDATE | query/index/N+1 — SQLAlchemy half in sqlalchemy-patterns; generic lens novel |
| performance-engineer | generic | CANDIDATE | profiling/load/Core-Web-Vitals (broader than database-optimizer) |
| accessibility-specialist | generic | CANDIDATE | WCAG/ARIA/keyboard — novel a11y lens |
| security-auditor | generic | CANDIDATE | deeper OWASP/auth/crypto audit (vs `/security-review`) |
| documentation-architect | generic | CANDIDATE | comprehensive docs across stacks |
| api-documenter | generic | CANDIDATE | OpenAPI/SDK — layering: FastAPI auto-OpenAPI covers Python; generic remainder thin |
| backend-architect | generic | CANDIDATE | API/schema/caching design patterns |
| refactor-planner | generic | CANDIDATE | refactoring plans + risk (planning vs execution) |
| legacy-modernizer | generic | CANDIDATE | framework migration / monolith→services |
| test-automator | generic | CANDIDATE | test strategy/pyramid planning |
| frontend-qa-tester | generic | CANDIDATE | Playwright-driven manual QA + bug reports |
| ui-ux-designer | generic | CANDIDATE | design methodology (vs frontend-design's implementation) |
| devops-troubleshooter | generic | CANDIDATE | incident response / log analysis |
| web-research-specialist | generic | CANDIDATE | overlaps `/deep-research`; lower priority |
| ai-engineer | generic | CANDIDATE | LLM/RAG/agent patterns — relevant if building AI features |
| deployment-engineer, cloud-architect, data-engineer, ml-engineer | stack | CANDIDATE | infra/data/ML — per-repo need |
| payment-integration, graphql-architect | stack | CANDIDATE | domain-specific but high-value when relevant |
| python-pro, typescript-expert, golang-pro, rust-pro | stack | CANDIDATE | language-expert personas — low priority, rules already encode per-lang policy |
| nextjs-app-router-developer, frontend-developer | stack | CANDIDATE | Next.js — overlaps `frontend-design`; low priority |
| code-architecture-reviewer, code-refactor-master, code-reviewer, debugger | generic | SKIP | overlap `/code-review`, `/simplify`, built-in Explore |
| data-scientist | stack | SKIP | BigQuery-locked |
| arbitrage-bot, blockchain-developer, crypto-analyst, crypto-risk-manager, crypto-trader, defi-strategist, quant-analyst (×7) | niche | SKIP | crypto/DeFi/quant-finance |
| directus-developer, drupal-developer, laravel-vue-developer, php-developer, game-developer, mobile-developer (×6) | niche | SKIP | framework/language not in the user's stack |

### claude-tools — skills (5) + hooks (5)

| name | type | scope | disp. | reason |
|------|------|-------|-------|--------|
| fastapi-clean-architecture | skill | generic | CANDIDATE | DDD/clean-arch layering — extends fastapi-patterns (weigh foreign idioms) |
| multi-system-sso-authentication | skill | stack | CANDIDATE | only if integrating external SSO |
| async-testing-expert | skill | generic | SKIP | testing.md + bats-setup; async patterns are testing.md's domain |
| skill-developer | skill | generic | SKIP | meta — skill-creator plugin covers it |
| brazilian-financial-integration | skill | niche | SKIP | BR fintech (boleto/PIX/CPF) |
| skill-activation-prompt(.ts/.sh), post-tool-use-tracker.sh, hooks.json, package.json (×5) | hook/config | generic | SKIP | meta-infra, Node/JS-hardcoded; not user-facing capabilities |

### claude-plugins — tech-lead plugin (16 cmd, 9 agent, 4 skill)

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

### claude-plugins — python plugin (10 cmd, 4 skill, 1 agent, 1 hook)

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

### claude-plugins — fastapi plugin (5 cmd, 2 skill, 1 agent)

| name | type | scope | disp. | reason |
|------|------|-------|-------|--------|
| fastapi:module | cmd | stack | CANDIDATE | full-module generator — speed over fastapi-patterns prose |
| fastapi:endpoint | cmd | stack | CANDIDATE | endpoint+service+test scaffolder |
| fastapi:migrate:create | cmd | stack | CANDIDATE | Alembic create w/ enum-downgrade auto-fix |
| fastapi:migrate:check / migration-reviewer | cmd/agent | stack | CANDIDATE | pre-apply migration review — automates the sqlalchemy-patterns checklist |
| fastapi:dto | cmd | stack | SKIP | DTO patterns in fastapi-patterns |
| fastapi-patterns, alembic-patterns | skill | stack | SKIP | adopted / covered by alembic.md |

### claude-plugins — linear plugin (4 cmd, 1 skill, 1 agent)

| name | scope | disp. | reason |
|------|-------|-------|--------|
| board, comment, cycle, delete, linear-api, issue-enricher (×6) | niche | SKIP | Linear SaaS integration — only if the user adopts Linear |

### pydantic/skills (5) + fastapi official (1)

| name | scope | disp. | reason |
|------|-------|-------|--------|
| building-pydantic-ai-agents, pydantic-ai-harness | niche | CANDIDATE-if-building-agents | the `pydantic_ai` agent framework — see the deferred `rules/pydantic-ai.md` backlog item |
| logfire-instrumentation, logfire-query, logfire-ui | niche | CANDIDATE-if-adopting-Logfire | observability platform — adopt if Logfire is used |
| fastapi (official) | stack | SKIP | covered by fastapi.md + fastapi-patterns; **re-mine on FastAPI version bumps** |

---

## Open CANDIDATE backlog (triage)

Not built — surfaced for the user to choose. Adopt as skills (ADR-0001),
splitting any stack-flavored ones per the layering principle. Grouped by
leverage:

**Tier 1 — strong generic, low overlap (best whole-environment wins):**
architecture/codebase analysis — `dependency-analyzer`/`deps` (coupling,
circular deps), `arch-review`/`architecture-reviewer`, `diagram` (Mermaid),
`modernize` (legacy roadmap), `codebase-explorer`; `plan-reviewer`
(pre-implementation plan QA); `tech-debt` (debt catalog); `debug-assistant`;
`deps-update`; `write-documentation`/`documentation-architect`.

**Tier 2 — useful generic, some overlap:**
`perf-check`/`performance-engineer`,
`test-reviewer`, `pytest-patterns`/`typing-patterns` (Python depth, like
fastapi-patterns), `accessibility-specialist`, `security-auditor`,
`ui-ux-designer`, `handoff`, `standup`, `dev-docs-update`, `brainstorm`.

**Tier 3 — external libraries/frameworks/tools: global, built on first use.**
These are all guidance about something *foreign to the repo*, so per ADR-0003
they live in the **global** generic layer (not repo-local), and the only
question is *when* to build — answer: the first time any repo uses the
library/tool, front-loaded, not deferred. Items: language-expert agents
(python/go/rust/ts), `graphql-architect`, `payment-integration`,
`ai-engineer`, `data-engineer`/`ml-engineer`,
`deploy`/`rollback`/`deployment-engineer`/
`devops-troubleshooter`/`cloud-architect`, the FastAPI scaffolders
(`module`/`endpoint`/`migrate-*`), pydantic-ai + Logfire skills.
