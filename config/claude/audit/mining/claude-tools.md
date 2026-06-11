# Mining matrix — `rafaelkamimura/claude-tools`

Part of the mining census (`../mining-census.md` has the disposition key and
the cross-repo CANDIDATE backlog). MIT. Round 2026-06-11. 93 items.

## commands (32)

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
| test-suite | generic | SKIP | runner + coverage = `qa-check` (Tests dim); missing-test gaps = `test-review` |
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

## agents (46)

| name | scope | disp. | reason |
|------|-------|-------|--------|
| plan-reviewer | generic | CANDIDATE | pre-implementation plan QA (before vs after code) — strong, novel |
| database-optimizer | generic | CANDIDATE | query/index/N+1 — SQLAlchemy half in sqlalchemy-patterns; generic lens novel |
| performance-engineer | generic | CANDIDATE | profiling/load/Core-Web-Vitals (broader than database-optimizer) |
| accessibility-specialist | generic | CANDIDATE | WCAG/ARIA/keyboard — novel a11y lens |
| security-auditor | generic | SKIP | overlaps `security-scan` skill + `/security-review`; deeper-audit lens not worth a separate skill now |
| documentation-architect | generic | CANDIDATE | comprehensive docs across stacks |
| api-documenter | generic | CANDIDATE | OpenAPI/SDK — layering: FastAPI auto-OpenAPI covers Python; generic remainder thin |
| backend-architect | generic | CANDIDATE | API/schema/caching design patterns |
| refactor-planner | generic | SKIP | refactoring plans + risk — now covered by `modernize` (large) + `/simplify` (small) + `arch-review`/`plan-review` |
| legacy-modernizer | generic | CANDIDATE | framework migration / monolith→services |
| test-automator | generic | SKIP | test strategy/pyramid = `testing.md` bar + `plan-review` + `test-review` |
| frontend-qa-tester | generic | SKIP-until browser-UI/e2e | the tool for qa.md's End-to-end dimension (no tool yet); Playwright/browser-specific — build on first browser-UI/e2e need (watch list) |
| ui-ux-designer | generic | CANDIDATE | design methodology (vs frontend-design's implementation) |
| devops-troubleshooter | generic | CANDIDATE | incident response / log analysis |
| web-research-specialist | generic | CANDIDATE | overlaps `/deep-research`; lower priority |
| ai-engineer | generic | CANDIDATE | LLM/RAG/agent patterns — relevant if building AI features |
| deployment-engineer, cloud-architect, data-engineer, ml-engineer | stack | CANDIDATE | infra/data/ML — build when first used (ADR-0003) |
| payment-integration, graphql-architect | stack | CANDIDATE | domain-specific but high-value when relevant |
| python-pro, typescript-expert, golang-pro, rust-pro | stack | CANDIDATE | language-expert personas — low priority, rules already encode per-lang policy |
| nextjs-app-router-developer, frontend-developer | stack | CANDIDATE | Next.js — overlaps `frontend-design`; low priority |
| code-architecture-reviewer, code-refactor-master, code-reviewer, debugger | generic | SKIP | overlap `/code-review`, `/simplify`, built-in Explore |
| data-scientist | stack | SKIP | BigQuery-locked |
| arbitrage-bot, blockchain-developer, crypto-analyst, crypto-risk-manager, crypto-trader, defi-strategist, quant-analyst (×7) | niche | SKIP | crypto/DeFi/quant-finance |
| directus-developer, drupal-developer, laravel-vue-developer, php-developer, game-developer, mobile-developer (×6) | niche | SKIP | framework/language not in the user's stack |

## skills (5) + hooks (5)

| name | type | scope | disp. | reason |
|------|------|-------|-------|--------|
| fastapi-clean-architecture | skill | generic | CANDIDATE | DDD/clean-arch layering — extends fastapi-patterns (weigh foreign idioms) |
| multi-system-sso-authentication | skill | stack | CANDIDATE | only if integrating external SSO |
| async-testing-expert | skill | generic | SKIP | testing.md + bats-setup; async patterns are testing.md's domain |
| skill-developer | skill | generic | SKIP | meta — skill-creator plugin covers it |
| brazilian-financial-integration | skill | niche | SKIP | BR fintech (boleto/PIX/CPF) |
| skill-activation-prompt(.ts/.sh), post-tool-use-tracker.sh, hooks.json, package.json (×5) | hook/config | generic | SKIP | meta-infra, Node/JS-hardcoded; not user-facing capabilities |
