# Mining census

The index + explanations for repos mined for ideas during audits. The *Idea
sources* registry in [`idea-sources.md`](idea-sources.md) is the higher-level
index; this file
explains the method and links the **complete mapping** — every agent / command
/ hook / skill considered and why it was or wasn't adopted, in a **per-repo
matrix file** under `mining/`. Audit-only (not context-loaded).

**Why a full census:** an audit improves the *whole* dev environment, so good
*generic* tooling should spread to every repo. Charting only a curated
shortlist hides what was skipped and biases toward the current repo's stack.
Every mined repo gets its own complete matrix file.

## Disposition key

- **ADOPT** — clear, high-value, low-overlap; build it (as a skill per
  ADR-0001, or a rule/hook if that's the right kind).
- **CANDIDATE** — genuinely worth considering for the global setup; **the
  user decides**. Judged by value to *any* repo, not just the one being
  audited. An agent/command can be a CANDIDATE even though we'd reimplement it
  as a skill.
- **SKIP** (permanent) — already covered by our tooling, redundant, meta-infra,
  or already adopted. Won't resurface. Reason given.
- **SKIP-until `<trigger>`** (conditional) — legitimately skipped *now* because
  a precondition isn't met (a tool we don't use, a domain we're not in), but it
  **flips to CANDIDATE when the trigger fires** (usually "first use of X" —
  ADR-0003). The SKIP stands; the trigger keeps it findable. All `SKIP-until`
  items are collected in the **Watch list** below.

Disposition reflects **generic value to the whole environment**, then overlap
with existing built-ins / skills / rules, then the "layer the generic over the
specific" principle (`EXTENDING.md`).

## Watch list — `SKIP-until` triggers

When a trigger below becomes true (you start using the tool / enter the
domain), re-promote the item to CANDIDATE. Check this list when adopting any
new dependency or tool; the audit checks it each run.

| Trigger (first use of…) | Re-promotes |
|-------------------------|-------------|
| **Mermaid** (diagrams anywhere) | `claude-plugins` `diagram` → an arch/structure diagram step |
| **Logfire** (observability) | `pydantic/skills` `logfire-instrumentation`/`-query`/`-ui` |
| **`pydantic_ai`** (building LLM agents) | `pydantic/skills` `building-pydantic-ai-agents`, `pydantic-ai-harness`; the deferred `rules/pydantic-ai.md` |
| **External SSO** integration | `claude-tools` `multi-system-sso-authentication` |
| **GraphQL** | `claude-tools` `graphql-architect` (Tier-3) |
| **Payments** (Stripe/etc.) | `claude-tools` `payment-integration` (Tier-3) |
| **Linear** (the SaaS) | `claude-plugins` `linear` plugin (board/comment/cycle/issue-enricher) |
| **A new language** (Go/Rust/TS…) in a repo | the matching `claude-tools` language-expert agent (Tier-3) |
| **A browser UI / e2e need** (Playwright) | `claude-tools` `frontend-qa-tester` → the qa End-to-end (dim 8) tool |
| **Wanting a richer context gauge** (plain `X%` no longer enough) | `claude-hud` context progress-bar glyph → the Claude statusline |
| **A code-review lens `qa.md` lacks** (silent-failure / comment-rot / type-design) | `pr-review-toolkit` lenses → vendor as a skill, or fold into the qa code-style audit (drop rationale: decisions log 2026-06-10) |
| **A phased feature-dev flow wanted** (Explore→Plan→build in a repo) | `feature-dev` → vendor `/feature-dev` as a skill driving built-in Explore/Plan agents (drop rationale: decisions log 2026-06-10) |
| **A GH-Actions-injection guard needed** (beyond `github-actions.md` awareness) | a tiny path-only GH-Actions PreToolUse hook — likely unnecessary (drop rationale: decisions log 2026-06-10) |
| **Wanting session checkpoint/restore** (beyond `compact-snapshot`) | `ruvnet/ruflo` `.claude/helpers` context-persistence + PreCompact / SessionStart hooks — mine the *pattern*, not the runtime (eval: decisions log 2026-06-20) |
| **Running a service/infra with reliability needs** (SRE) | reliability/observability/IR cluster — chaos-engineering, SLO/error-budget, incident-commander, runbook + monitoring (4-repo signal); fills the acknowledged `qa.md` dim 10/11 gap (plugin-collection sweep, 2026-06-20) |
| **Building our own MCP server** | mcp-server-builder / mcp-developer skills (scaffold from an OpenAPI spec) — `mcp.md` covers consuming, not authoring (sweep 2026-06-20) |
| **Owning a public/external API contract** | `api-design-reviewer` / `openapi-expert` — REST linting + breaking-change detection (sweep 2026-06-20) |
| **Authorized pentest / CTF / security-research work** | security-domain agents — red/blue-team, pentest, RE, exploit, threat-modeling (`JoasASantos`, VoltAgent `penetration-tester`); our `security-scan` is defensive SAST/SCA (sweep 2026-06-20) |
| **Wanting context economy beyond removal + snapshot** | context-economy-by-*compression* — compress large tool outputs + MCP tool descriptions + memory files (`caveman`/`headroom`/`context-mode`); we do economy by removal (`claude-audit`) + snapshot (`compact-snapshot`) (sweep 2026-06-20) |

(Tier-3 "build on first use" items are already watch-like by definition; listed
here so there's one place to scan.)

## Adopting a CANDIDATE — fold into existing categories

When a CANDIDATE is built, **try to fit it into an existing top-level
category** rather than spawning a new one: `code-style`, `testing`, `qa`,
tools (`gh`,
`git`), etc. Most mined items map cleanly — `tech-debt`/`arch-review`/
`dependency-analyzer` → **qa**; `test-reviewer`/`test-suite` → **testing**;
`pytest-patterns`/`typing-patterns` → the language depth under **qa/testing**.
Don't force it — a genuinely new area (e.g. an `architecture`/`docs` family)
earns its own top-level category. The default is "extend a family," the
exception is "open a new one."

**Split a category that's outgrown itself.** Folding-in is the default, but a
category can grow **too big or too spread out** — so **each audit checks
whether any top-level category should split** into separate ones (e.g. a
bulging `qa` shedding `documentation` / `troubleshooting`, or a `tools`
grab-bag separating by tool). Splitting is the release valve that keeps
fold-in from creating a junk drawer.

**`qa` is the umbrella — work it last.** `qa` (and the `qa-check` skill)
aggregates the other categories — code-style, testing, security,
documentation, performance — plus its own pipeline discipline, even though
each of those stays its own category. So when **mining or otherwise
creating/modifying rules/skills**, build/adopt the category-specific pieces
**first** and touch `qa` **last** — then **wire them in**: `qa.md` names the
tool and `qa-check` composes it. Updating `qa` before its pieces exist
guarantees the wiring gap (a review skill that nothing calls).

---

## Round 2026-06-11 — FastAPI/SQLAlchemy/Python mining

Sources (all MIT; see *Idea sources* for SHAs/recency). **~158 items
charted.** Already actioned: the `fastapi-patterns` / `sqlalchemy-patterns`
skills and the `adr` skill; the rest of the CANDIDATEs are the backlog below.

Per-repo matrices:

- [`mining/claude-tools.md`](mining/claude-tools.md) — `rafaelkamimura/claude-tools` (93 items)
- [`mining/claude-plugins.md`](mining/claude-plugins.md) — `ruslan-korneev/claude-plugins` (4 plugins, 59 items)
- [`mining/pydantic-skills.md`](mining/pydantic-skills.md) — `pydantic/skills`, official (5)
- [`mining/fastapi.md`](mining/fastapi.md) — `fastapi/fastapi` official skill (1)

---

## Round 2026-06-20 — ykdojo/claude-code-tips

A 43-tip prose collection (hybrid — also a `dx` plugin + skills) by a
Claude-Code YouTuber; non-OSS license (ideas only). Matrix:
[`mining/claude-code-tips.md`](mining/claude-code-tips.md). **41/43 SKIP**
(covered by our more-developed tooling, personal interactive workflow, or
counter to our posture — disable-attribution,
`--dangerously-skip-permissions`).
**Two CANDIDATEs**, both on `BACKLOG.md`:

- **Audit the permission allow-list (the `cc-safe` idea, Tip 31)** — scan
  `settings.json` `permissions.allow` for risky auto-approved patterns
  (`sudo`, `rm -rf`, `chmod 777`, `curl | sh`, `git reset --hard`). Generic +
  security-positive; natural fold into **claude-audit** (it already inspects
  `settings.json`).
- **Input-box keybindings (Tip 36)** — exact bindings feeding the open
  *Keybinding cheat-sheet statusline line* item; secondary source, cross-check
  against official docs.

---

## Round 2026-06-20 — plugin/skill collection repos (11-repo sweep)

The *Mining queue* "big collection repos" item — 11 aggregator/marketplace
repos mined at once (fanned out to read-only census agents, net-new only).
Per-repo table + deduped theme analysis:
[`mining/plugin-collection-repos.md`](mining/plugin-collection-repos.md).
**Heavy duplication confirmed** (as the queue predicted); all 11 repos are
SKIP as adopt-sources. The value is the **cross-repo theme signal**:

- **One CANDIDATE → `BACKLOG.md`:** agent supply-chain / install-safety audit
  (scan an external skill/plugin before install; lint a repo for
  agent-readiness) — **pairs with the `cc-safe` permission-allow-list
  CANDIDATE** into one "harden the agent's attack surface" theme.
- **Five Watch-list triggers** added above: reliability/SRE, MCP-server
  building, API-contract review, security-domain agents,
  context-economy-by-compression. All build-on-first-use (ADR-0003).
- **Reconfirmed held:** the spec→plan→onboarding *workflow* cluster (future
  workflow/planning category); standard language/domain-expert agent sets
  (already charted via `claude-tools`).

---

## Open CANDIDATE backlog (triage)

Not built — surfaced for the user to choose. Adopt as skills (ADR-0001),
folding into an existing category where one fits (above) and splitting any
stack-flavored ones per the layering principle. Grouped by leverage:

**Tier 1 — strong generic, low overlap (best whole-environment wins).**
**DONE** (built as skills): the architecture/codebase cluster
(`dependency-analyzer`/`deps`, `arch-review`/`architecture-reviewer`,
`tech-debt`, `codebase-explorer`) → the **`arch-review`** skill
(`diagram`/Mermaid dropped — not used); `modernize` → the **`modernize`**
skill; `plan-reviewer` → the **`plan-review`** skill;
`write-documentation`/`documentation-architect` → the
**`write-documentation`** skill, which **opens the `documentation`
category** (the `rules/documentation.md` rule plus the skill);
`debug-assistant` → the **`debug-assistant`** skill, which **opens the
`troubleshooting` category** (a thin always-on `rules/troubleshooting.md`
plus the skill); `deps-update` → the **`deps-update`** skill (qa /
dependency-maintenance orbit — no new category). **Tier-1 is fully
adopted** — nothing remaining.

**Tier 2 — useful generic, some overlap.** **DONE** (built as qa-dimension
review skills, the arch-review family): `perf-check`/`performance-engineer` →
**`perf-review`**; `test-reviewer` → **`test-review`**;
`accessibility-specialist` → **`a11y-review`**; `pytest-patterns` →
**`pytest-patterns`** skill (testing depth) and `typing-patterns` →
**`typing-patterns`** skill (typing depth, paired with `python.md`).
`security-auditor` → **SKIP** (overlaps `security-scan` + `/security-review`).
The documentation-output item `api-documenter` → **ADOPTED** (folded into
`write-documentation`, above). **Remaining (not qa):** `ui-ux-designer`,
`handoff`, `standup`, `dev-docs-update`, `brainstorm` — workflow/UX items for
later categories; `handoff`/`standup`/`dev-docs-update` were **considered for
`documentation` and deliberately held out** as session-continuity workflow
(not product docs) — see *Category status*.

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

## Category status (so audits don't re-survey)

**Snapshot of the current repos/stacks — not "closed forever."** A **new
repo** (or a new language/framework in an existing one) **re-opens every
category** for re-evaluation against it — `code-style` most obviously (a new
language carries its own style conventions and formatter/linter), but **all**
of them. "Complete" here means "covered for what we build today." Pairs with
the global-re-eval principle (claude-audit skill) and the `SKIP-until` watch
list above.

- **`code-style`** — **complete as-is; nothing to adopt.** It is documented
  policy (`code-style.md`) + per-language formatters/linters (`ruff.md`,
  `shfmt`, …) + the qa *Code-style audit* dimension executed by `/code-review`
  and `/simplify`. Every mined code-style item (clean-code-patterns,
  code-refactor-master/code-architecture-reviewer, ruff-patterns,
  refactor-planner) is SKIP — covered. A skill adds nothing over the rule
  (and style is personal preference — a rule's job, not a skill's).
- **`qa`** — substantially built (the `*-review` family + python depth + the
  **`deps-update`** dependency-maintenance skill, wired into the Security/SCA
  dimension); the **umbrella, worked last**. Open: nothing required.
- **`testing`** — covered (`testing.md` + `bats-setup` + `test-review` +
  `pytest-patterns` + `qa-check` runs/coverage). Two deferred: **e2e** (qa dim
  8 has no tool — `frontend-qa-tester` is `SKIP-until` a browser-UI/Playwright
  need, watch list) and **Codecov** coverage upload (audit finding F, deferred
  — infra, not a skill).
- **`gh`/`git`** — covered by rules + skills; open ideas: `resolve-issue`,
  `categorize-issue` (audit backlog).
- **`documentation`** — **opened.** `documentation.md` (the doc bar + the
  "right form per audience" stance) + the **`write-documentation`** skill
  (authoring procedure) + `code-style.md` (writing mechanics) +
  `markdownlint.md` (lint) + the `adr` skill (decisions) + `qa.md` dim 13 (the
  pre-merge gate, which points here). Mined doc-output items folded in:
  `documentation-architect`, `api-documenter` → `write-documentation`. **Held
  as adjacent — not documentation:** `handoff`/`standup`/`dev-docs-update`
  (session-continuity workflow) and `dev-docs`/`read-specs`/
  `feature-specification` (spec → plan) belong to a future *workflow*/planning
  category, not product docs — folding them in would force unrelated concerns
  together ("don't force it").
- **`troubleshooting`** — **opened.** A **thin** always-on
  `rules/troubleshooting.md` (the debugging bar — reproduce-first,
  root-cause, regression-test — present every turn because a failure can
  surface on any turn) + the **`debug-assistant`** skill (the full
  scientific-method session, where the depth lives). Deliberately lighter
  than `testing.md`/`documentation.md`: the bar is always-on, the procedure
  is on-demand. **Not a qa dimension** — troubleshooting is the *diagnostic
  activity triggered when any check or behaviour fails*, a peer category, not
  a qa gate (so `qa.md` is unchanged). The **ops facet**
  (`devops-troubleshooter` — incident response on running infra) is held as
  build-on-first-use (ADR-0003). The planned `resolve-issue` skill composes
  `debug-assistant` as its investigation step.
