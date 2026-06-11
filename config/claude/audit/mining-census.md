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
- **SKIP** — covered by existing tooling, niche/domain-locked, meta-infra, or
  already adopted. Reason given.

Disposition reflects **generic value to the whole environment**, then overlap
with existing built-ins / skills / rules, then the "layer the generic over the
specific" principle (`EXTENDING.md`).

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

**Tier 1 — strong generic, low overlap (best whole-environment wins):**
architecture/codebase analysis — `dependency-analyzer`/`deps` (coupling,
circular deps), `arch-review`/`architecture-reviewer`, `tech-debt` (debt
catalog), `codebase-explorer` — **DONE: consolidated into the `arch-review`
skill** (`diagram`/Mermaid dropped — not used). Remaining: `modernize` (legacy
roadmap), `plan-reviewer` (pre-implementation plan QA), `debug-assistant`,
`deps-update`, `write-documentation`/`documentation-architect`.

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
