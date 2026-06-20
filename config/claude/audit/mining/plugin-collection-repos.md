# Mining matrix — plugin/skill collection repos (2026-06-20 sweep)

Mined 2026-06-20 as the *Mining queue* "big collection repos" item — **11
aggregator/marketplace repos at once**, per the queue rule (*mine one at a
time, don't decide until all are mined; expect duplicates*). Fanned out to 11
read-only census agents, each reporting **net-new only** vs. our existing
tooling, then deduped here. Audit-only (not context-loaded).

## The 11 repos

Star counts are **as-reported by the census agents, unverified** (some look
inflated; stars are not load-bearing for the decision). Shape ≫ stars here.

| Repo | License | Stars | Shape | Net-new signal |
|------|---------|-------|-------|----------------|
| `ComposioHQ/awesome-claude-plugins` | MIT | ~1.8k | hybrid marketplace + catalog | a few *mechanisms*: context-mode, AgentLint, mcp-builder, skill-bus, event-sourced backlog |
| `jeremylongshore/claude-code-plugins-plus-skills` | MIT | ~2.4k | huge marketplace (432 plugins / 2.7k skills) | mostly domain bloat; novel: `validate-plugin` rubric gate, Forge (spec→skill), subagent file-artifact+JSON contract |
| `ccplugins/awesome-claude-code-plugins` | Apache-2.0 | ~847 | curated link-list | off-domain pointers only (n8n, mobile-ux, db-perf, compliance) |
| `alirezarezvani/claude-skills` | MIT | ~18.6k | huge hybrid (345 skills) | **reliability/ops cluster** + **skill-security-auditor** + prompt-governance + api-design-reviewer |
| `JuliusBrussee/caveman` | MIT | ~75k(?) | output-compression pkg | one idea: **context-economy-by-compression** |
| `sickn33/antigravity-awesome-skills` | MIT / CC-BY | ~41k(?) | 1,678-skill multi-tool monorepo | eval-ops, agent-memory, privacy/compliance, **obs/IR**, i18n, `agents-md` |
| `chopratejas/headroom` | Apache-2.0 | ~41k(?) | compression *product* | **nothing net-new** (one self-bootstrap SessionStart hook) |
| `VoltAgent/awesome-claude-code-subagents` | MIT | ~22k | 154 subagents | std agent set (already charted via `claude-tools`); net-new: chaos/pentest/ai-writing-audit/research/compliance |
| `Jeffallan/claude-skills` | MIT | ~10k | 66-skill marketplace | ML/LLM-ops + reliability + **discovery→spec→epic workflow** |
| `team-attention/plugins-for-claude-natives` (`clarify`) | MIT | ~804 | clarify = 3 skills (+ monorepo) | clarify duplicative; monorepo: agent-council, doubt, team-assemble orchestration |
| `JoasASantos/ClaudeAdvancedPlugins` | MIT | ~154 | 48 command-prompts (very young, 4 commits) | **security-domain** (red/blue-team, RE, pentest, exploit), gamedev, OS-internals |

**Verdict on the repos themselves:** all are SKIP as *sources to adopt from*
— curated link-lists, domain/SaaS marketplaces, or single-idea products. The
value is the **deduped theme signal** below, not any one repo.

## Deduped net-new themes (cross-repo signal)

A theme surfaced by **several independent repos** is the real find.
Disposition per theme:

| Theme | Surfaced by | Disp. | Reason |
|-------|-------------|-------|--------|
| **Agent supply-chain / install-safety** — scan a third-party skill/plugin for malicious code *before* install; lint a repo for agent-readiness (AgentLint) | alirezarezvani (`skill-security-auditor`), ComposioHQ (`AgentLint`) | **CANDIDATE** | **genuinely relevant** — we install external skills (this census!) with no pre-install scan; **pairs with the `cc-safe` permission-allow-list CANDIDATE** into one "harden the agent's own attack surface" theme. Backlog. |
| **Reliability / observability / incident-response (SRE)** — chaos-engineering, SLO/error-budget, incident-commander, runbook + monitoring | alirezarezvani, Jeffallan, VoltAgent, antigravity (**4 repos**) | **SKIP-until** running a service/infra with reliability needs | fills the **acknowledged** `qa.md` dim 10/11 gap (status-only today); build-on-first-use (ADR-0003) — we operate no services now. Watch list. |
| **Context-economy by *compression*** — compress large tool outputs + MCP tool descriptions + memory files | caveman, headroom, ComposioHQ (`context-mode`), jeremylongshore | **SKIP-until** wanting economy beyond removal+snapshot | a real lever we lack (we do economy-by-*removal* via `claude-audit` + by-*snapshot* via `compact-snapshot`), but the implementations are heavyweight products/gimmicks. Watch list. |
| **MCP server *building*** — scaffold an MCP server (often from an OpenAPI spec) | ComposioHQ, alirezarezvani, Jeffallan, VoltAgent (**4 repos**) | **SKIP-until** building our own MCP server | `mcp.md` covers *consuming*/adopt-vs-build; `mymcp` wraps existing servers. We author none today. Watch list. |
| **API-contract review** — REST linting + breaking-change detection | alirezarezvani (`api-design-reviewer`), ccplugins (`openapi-expert`) | **SKIP-until** owning a public/external API contract | we have `fastapi`/`sqlalchemy` *patterns*, not contract review. Watch list. |
| **Security-domain agents** — red/blue-team, pentest, RE, exploit, threat-modeling | JoasASantos, VoltAgent (`penetration-tester`), antigravity (api-fuzzing) | **SKIP-until** authorized pentest/CTF/security-research work | our `security-scan` is defensive SAST/SCA; these are domain-expert prompts, build-on-first-use. Watch list. |
| **Spec → plan → onboarding workflow** — requirements elicitation, spec-from-code, codebase onboarding tour, epic lifecycle commands | Jeffallan (Common Ground / Spec Miner / Feature Forge / epic-commands), alirezarezvani (code-tour) | **SKIP (held)** | already deliberately **held** as the future *workflow/planning* category (`mining-census.md` Category status — `handoff`/`read-specs`/`feature-specification`). Reconfirmed, not re-opened. |
| **Language/domain-expert agent sets** — the standard python/go/rust/ts/k8s/postgres/graphql experts | VoltAgent (cats 01-06), jeremylongshore, ccplugins | **SKIP** | already charted via `claude-tools` (Tier-3, build-on-first-use); no new info. |
| **Skill-quality scored gate** — `validate-plugin` 100-pt rubric, `prompt-governance` | jeremylongshore, alirezarezvani | **SKIP (fold)** | route to existing `skill-creator` dogfood + "Rule eval/optimization" backlog items — don't spawn a new one (skill-creator's eval is the known-broken piece on CC 2.1.x). |
| **Adversarial self-critique** — The Fool (5 devil's-advocate modes), `doubt` (re-validate own answer), agent-council (multi-model vote) | Jeffallan, team-attention | **SKIP** | covered by `plan-review` + the adversarial-verify pattern in the Workflow harness guidance; the framings add no procedure. |
| **Multi-agent orchestration** — maestro/team-assemble, file-artifact+strict-JSON subagent contract | ComposioHQ, jeremylongshore, antigravity, team-attention | **SKIP** | the **Workflow** tool (deterministic orchestration + `schema` output contract) already gives us this; the "emit evidence artifact + validated JSON" is exactly the schema pattern. |
| **Token/cost telemetry** — caveman-stats, Manifest, aws-cost-saver | caveman, ComposioHQ | **SKIP** | statusline already surfaces rate-limit usage; deeper accounting is niche. |
| **Agent-memory kits / `AGENTS.md` authoring** | jeremylongshore, antigravity | **SKIP** | covered by our file-based auto-memory + `compact-snapshot`; we use `CLAUDE.md`, and `AGENTS.md` interop isn't a need today. |

## Outcome

The 11-repo sweep confirms the queue's premise (**heavy duplication**) and
yields, after dedup, **one actionable CANDIDATE** plus several trigger-gated
Watch entries and reconfirmed holds:

- **CANDIDATE (backlog): agent supply-chain / install-safety audit.** Scan an
  external skill/plugin for malicious code *before* install, and/or lint a
  repo for agent-readiness — recurring across two repos and **directly
  relevant** (we adopt external skills with no gate). **Pairs with the
  existing `cc-safe` permission-allow-list CANDIDATE** (from the
  `claude-code-tips` mine) into a single "harden the agent's own attack
  surface" theme — both fold naturally into `claude-audit` / `security-scan`.

- **Watch list (SKIP-until):** reliability/observability/SRE tooling (4-repo
  signal, fills the `qa.md` dim 10/11 gap on first service we operate);
  context-economy-by-compression; MCP-server building; API-contract review;
  security-domain agents (on authorized security work). All build-on-first-use
  per ADR-0003.

- **Reconfirmed held:** the spec→plan→onboarding *workflow* cluster stays held
  as the future workflow/planning category; the standard
  language/domain-expert agent sets stay SKIP-until-first-use (already charted
  via `claude-tools`).

**Reused impl:** none (ideas only). No single repo is worth promoting to
`idea-sources.md` as an implementation source; the sweep is registered there
as one grouped entry pointing here.
