# Mining census

The index + explanations for repos mined for ideas during audits. The *Idea
sources* registry in `SETUP-AUDIT.md` is the higher-level index; this file
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

## Open CANDIDATE backlog (triage)

Not built — surfaced for the user to choose. Adopt as skills (ADR-0001),
folding into an existing category where one fits (above) and splitting any
stack-flavored ones per the layering principle. Grouped by leverage:

**Tier 1 — strong generic, low overlap (best whole-environment wins).**
**DONE** (built as skills): the architecture/codebase cluster
(`dependency-analyzer`/`deps`, `arch-review`/`architecture-reviewer`,
`tech-debt`, `codebase-explorer`) → the **`arch-review`** skill
(`diagram`/Mermaid dropped — not used); `modernize` → the **`modernize`**
skill; `plan-reviewer` → the **`plan-review`** skill. **Remaining:**
`debug-assistant` (→ a *troubleshooting* category), `deps-update`,
`write-documentation`/`documentation-architect` (→ a *documentation* category)
— see the *Skill ideas & future categories* in `SETUP-AUDIT.md`.

**Tier 2 — useful generic, some overlap.** **DONE** (built as qa-dimension
review skills, the arch-review family): `perf-check`/`performance-engineer` →
**`perf-review`**; `test-reviewer` → **`test-review`**;
`accessibility-specialist` → **`a11y-review`**; `pytest-patterns` →
**`pytest-patterns`** skill (testing depth) and `typing-patterns` →
**`typing-patterns`** skill (typing depth, paired with `python.md`).
`security-auditor` → **SKIP** (overlaps `security-scan` + `/security-review`).
**Remaining (not qa):** `ui-ux-designer`, `handoff`, `standup`,
`dev-docs-update`, `brainstorm` — workflow/UX items for later categories.

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
