# Claude Code Setup Audit

**Status:** living record — re-run periodically (see the TODO "Audit the
Claude Code Setup"). This file is tracked but **not** context-loaded (it is
not a rule), so it costs nothing per turn. Placement may be re-homed by a
later audit.

## How to run

1. **Measure** the baseline — `/context` for the live window breakdown, plus
   a read-only inventory agent (sizes of always-on rules, MCP tool counts,
   plugins). Run the inventory *via an agent* so the audit's own reading does
   not consume the context it is meant to protect.
2. **Classify** each artifact by load tier (always-on / on-demand / isolated).
3. **Recommend** by cost × (1 − relevance) — trim weight, never guardrails.
4. **Record** decisions below so the next run can compare against them.

## Baseline — 2026-06-10 (this repo)

Approx **~40–44k tokens/turn** loaded before any task content:

| Tier | Cost (~tokens) | Notes |
|------|---------------:|-------|
| MCP tool schemas (terraform ~44, serena ~33, context7 2) | ~17,000–20,500 | **largest single cost**; terraform/serena irrelevant to a Bash repo |
| Always-on rules (17 with no `paths:`) | ~17,900 | 9 are single-language and should be scoped |
| Memory (global CLAUDE.md + repo WORKFLOW/TESTS/CONVENTIONS) | ~5,800 | load-bearing |

27 rules (linters + `python`/`typescript`) are correctly deferred via `paths:`
frontmatter — the on-demand tier is working well.

## Findings & recommendations (status in Decisions log)

Ordered by leverage.

- [ ] **A. Drop unused MCP plugins — ~16–20k/turn (biggest win).**
  `terraform` (~44 tools) and `serena` (~33 tools) are enabled **user-level**
  in `settings.json` but unused in Bash/dotfiles work; their tool schemas load
  every turn. *User-level → affects all repos; verify no other repo needs
  them, or switch to per-project enablement.* `terraform` is the clear drop.
- [ ] **B. Path-scope 9 single-language always-on rules — ~3.7k/turn.**
  Verified always-on (no `paths:`), each single-stack: `java`, `vitest`,
  `vite`, `react`, `mantine`, `fastapi`, `sqlalchemy`, `alembic`, `html`. Add
  `paths:` frontmatter (per-language globs) as `python.md`/`typescript.md`
  already do. Safe, recoverable, no guardrail lost.
- [ ] **C. Scope `zap.md` (DAST, ~1.1k) to service repos.** Lower confidence —
  needs a call on which repos run DAST, or fold it into the security-scan
  skill instead of an always-on rule.
- [ ] **D. `TEMPLATE.md` (~220) is a scaffold, not a rule** — it loads
  always-on. Move it out of `rules/` (or exclude it) so it stops loading.
- [ ] **E. Plugin cleanup (description-tier clutter).** `commit-commands` is
  enabled twice (two marketplaces). `code-review` / `pr-review-toolkit` /
  `commit-commands` overlap the `ship-pr` skill + the `gh` rules.
  `ralph-loop`, `pydantic-ai`, `jdtls-lsp` appear unused. Cull duplicates /
  unused — *verify before dropping.*
- [ ] **F. External validation: add Codecov.** Tests run (bats + pytest) but
  no coverage is uploaded anywhere — the one measurable gap (`qa.md` Tests
  dimension). Add `codecov/codecov-action` + `codecov.yml`; pytest has
  `--cov`, bash needs `kcov`/`bashcov`. Skip Sonar / Codacy / DeepSource
  (duplicate CodeFactor). CodeFactor + Snyk already run app-side.

## Global changes (affect ALL repos — 2026-06-10)

Plugin enable/disable is user-global, so these touch every repo:

- **Disabled MCP-providing plugins `terraform` and `serena`** (unused here;
  ~16–20k tokens/turn of tool schemas). To use one in a specific repo, do
  **not** re-enable the global plugin — define the server once in `mymcp` and
  turn it on there with a local-scope switch (`claude mcp add terraform --
  mymcp terraform`) so it loads only in that repo. Known need:
  **terraform → harleydev**.
- **Removed the duplicate `commit-commands`** (was enabled from two
  marketplaces).

**Principle (now in `rules/mcp.md`):** plugins are global — enable one only
if it is a good global fit; otherwise register the MCP server per-repo or
vendor the feature. **Each repo needs its own audit** of what it enables.

## Idea sources (mined for ideas; re-check during audits)

Repos we have mined for ideas. This registry is **broader** than any per-skill
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

The **full disposition census** of every item in these repos (every agent /
command / hook / skill considered, ADOPT/CANDIDATE/SKIP + reason) is in
`audit/mining-census.md`. The open CANDIDATE backlog lives there too. The
source-discovery method (official-first → stars+recency+health; the >1yr
staleness gate) and the full-census/generic-lens practice are documented in the
**claude-audit** skill (*Mining repos for ideas*).

## Audit backlog

Follow-up tasks for the audit itself — **audit-only**, read when running
`/claude-audit`, not dotfiles-repo work (kept here, not in the repo `TODO.md`,
so the two stay separate). Done items are retained for continuity; new
decisions are also summarized in the *Decisions log*.

### Audit dimensions / design

- [x] **Form: the audit is the `claude-audit` skill** (`/claude-audit`) —
  multi-step, runs its inventory *via an agent*, modifies global config via a
  dotfiles PR and sets up the local repo.
  (`claude-code-setup:claude-automation-recommender` can help gap-finding
  within a run.)
- [ ] **Cadence.** Run `claude-audit` on a cadence — a quick pass *often*
  (enabled plugins/MCP, obvious always-on bloat) and a deeper audit
  *periodically*. Wire it to a reminder / `/schedule`. Each detailed run
  records decisions here. Expect the **global** config to be re-evaluated from
  many repos — possibly several times a day; that repetition is by design (see
  the claude-audit skill, *Global is re-evaluated from every repo*).
- [ ] **Context-load tiering.** Classify every artifact by *when* it loads:
  always-on (every turn: global CLAUDE.md, unscoped rules, enabled MCP tool
  schemas — the expensive tier), on-demand (path-scoped rules, skills, deferred
  MCP tools), isolated (agents — ~free to the main thread). Highest-leverage
  lever: push always-on content down a tier.
- [ ] **Recategorize / split / merge.** For each artifact ask whether it is the
  right *kind*: a "rule" that is really a procedure → skill; one that must
  happen every time → hook; a bloated multi-tool rule → split per tool;
  duplicated content → dedupe to one canonical source.
- [ ] **Plugins / MCP dimension.** Inventory every enabled plugin (what it
  does/bundles, whether used); cull duplicates of the `gh` CLI / existing
  rules+skills and unused ones; remember plugins carry context cost. MCP
  servers here come *from* plugins (no hand-maintained `mcp.json`).
- [ ] **Build vs. adopt.** For each capability weigh a maintained plugin/skill
  against our own: adopt when good and lean (vendor-and-modify with a
  `SOURCE.md`); write our own when the plugin is bloated/over-scoped for the
  context it costs. Weigh context cost vs maintenance burden explicitly.
- [ ] **External validation (GitHub Apps).** Evaluate third-party App checks as
  outside quality signals: what is wired (CodeFactor, Snyk) vs candidates
  (Codecov for coverage, Codacy / SonarCloud) — what each adds, its noise/cost,
  whether it earns its place.
- [ ] **Plugin-aware proposals (behavior rule).** When proposing a new
  rule/skill, also check whether a plugin provides it or should be added.
  Extend `CLAUDE.md`'s *Missing or Conflicting Tool Rules* + *When to Propose a
  Skill* and the `rule-coverage.py` hook. Bias to surfacing in the moment.

### Plugin-audit follow-ups (from the 2026-06-10/-11 passes)

- [x] **Resolved the `pydantic-ai` name-conflation (2026-06-11).** Two things
  were conflated: (a) `pydantic_ai`, the **agent framework**
  (provider-prefixed model strings, `@agent.tool`, `TestModel`, Logfire), vs
  (b) **AI-assisted work on pydantic** validation models, what pigify-style
  FastAPI apps need. Split accordingly:
  - [x] **(b) pydantic-validation / FastAPI / SQLAlchemy patterns** — DONE.
    Built the global on-demand skills `fastapi-patterns` +
    `sqlalchemy-patterns` (adapted from the *Idea sources* repos), cross-linked
    from the slim `fastapi.md` / `sqlalchemy.md` / `alembic.md` rules.
  - [ ] **(a) `pydantic_ai` agent-framework rule** — deferred; write a
    path-scoped `rules/pydantic-ai.md` only **when actually building agents
    with `pydantic_ai`**. Source: `pydantic/skills` `building-pydantic-ai-agents`
    (+ Logfire). Idea-level until then.
- [x] **Mined the idea-source repos for non-skill borrowings (2026-06-11).**
  Verdict: **8 of 9 already covered — only ADR was additive** (a good signal
  the config is in shape). Applied the "layer the generic over the specific"
  lens (`EXTENDING.md`); decisions in ADR-0001/0002.
  - [x] `lint-explain` / `typecheck-explain` — **SKIP**; the no-suppression
    policy already lives in `ruff.md` (Suppression: justified per-code `# noqa`)
    + `python.md` (`# type: ignore` with reason). Interactive "explain" is
    normal agent capability.
  - [x] `test-first` (TDD red-phase) / `clean-review` — **SKIP**; `testing.md`
    sets the test bar; `code-style.md` + `qa.md` Code-style audit + `/simplify`
    cover smells/SOLID.
  - [x] `tech-lead` `adr` — **ADOPTED** as the generic `adr` skill (house
    Nygard template; skills-over-commands per ADR-0001). Idea-level only — not
    cited as a tracked source.
  - [x] `fastapi` `migration-reviewer` / `migrate-check` — **SKIP**; the whole
    checklist is already prose in `alembic.md` ("always review the
    autogenerated script") + the `sqlalchemy-patterns` skill.
  - [x] `claude-tools` `database-optimizer` / `api-documenter` — **SKIP** (the
    layering demonstrator): SQLAlchemy half in `sqlalchemy-patterns`, generic
    "measure-first" in `qa.md`; FastAPI auto-OpenAPI via the `response_model`
    rule covers api-docs. Looked, correctly declined to vendor the agents.
- [x] **`git-worktree-workflow` reconcile-gone-branches** — guarded bulk-remove
  of `[gone]` branches + worktrees (confirm each, skip dirty, no blanket
  `--force` / `fetch --prune`). Done — Operation 7 (skill v1.1.0).
- [ ] **Trial `ralph-loop`** (autonomous completion loop, distinct from
  `/loop`). Unbounded — set a max-iteration cap, respect CLAUDE.md autonomy
  boundaries.
- [x] **Evaluated `pr-review-toolkit`, `feature-dev`, `security-guidance`** —
  all dropped (redundant with built-ins / `qa.md` / `security-scan`). Vendor
  bits surfaced by the repo that needs them — don't build proactively:
  - [ ] vendor the unique pr-review lenses (silent-failure, comment-rot,
    type-design) when a repo's review needs them — or fold into `qa.md`'s
    code-style audit.
  - [ ] vendor `/feature-dev` as a **skill** driving built-in Explore/Plan
    agents when a repo wants the phased flow.
  - [ ] add a tiny path-only GH-Actions-injection hook only if a repo needs it
    (likely unnecessary — `github-actions.md` covers awareness).

### Skill ideas & future categories (not from mining)

- [ ] **`resolve-issue` skill** — orchestrate `gh` issue resolution: fetch
  issue → **agent** investigates it against the codebase via the
  `debug-assistant` skill (root cause, "simple or not", proposed fix or a
  question) → decide → fix → open PR with
  `Closes #X` → merge. The investigation is an agent; **PR-open and merge stay
  gated** per `gh.md` ("no PR create/merge without explicit approval") unless a
  deliberately opted-in autonomous variant with guardrails (trivial-only, after
  CI green) is built. Tools/category: `gh`.
- [ ] **`categorize-issue` skill** — triage a `gh` issue: suggest
  labels/priority/estimate from codebase context and fold it into the repo's
  TODO triage queue (the `gh.md` *Issues & triage* workflow). Category: `gh`.
- [ ] **Future top-level categories** (per the "fold into existing categories,
  new one only if it doesn't fit" guidance):
  - [x] **`documentation`** — **opened** 2026-06-11: `rules/documentation.md`
    (the doc bar + form stance) + the `write-documentation` skill. Doc tooling
    (`markdownlint.md`) and the `adr` skill compose in. See *Decisions log*.
  - [x] **`troubleshooting`** — **opened** 2026-06-11: a *thin* always-on
    `rules/troubleshooting.md` (the debugging bar) + the `debug-assistant`
    skill (the procedure). Not a qa dimension — a peer category. See
    *Decisions log*.

## Decisions log

- 2026-06-11 — **Built `deps-update`; Tier-1 cluster done.** The proactive,
  human-driven dependency-currency sweep — inventory outdated → triage by
  risk/security-urgency → read changelogs → apply in safe batches →
  compat-gate each batch with `qa-check` (red batch → `debug-assistant` to
  isolate the offending bump). Folded into the **qa /
  dependency-maintenance orbit** — **no new category, no new rule** — and
  wired into `qa.md`'s Security/SCA dimension. Deliberately scoped to the gap
  the existing tools leave:
  `dependabot.md` (automated, scheduled, one-PR-per-bump bot) and
  `security-scan` (vuln/CVE-driven) are *reactive*; `deps-update` is the
  *considered, on-demand* counterpart (majors one at a time, changelog-read,
  no blindly widened ranges). Generic over ecosystem (commands from
  `poetry.md`, …). This was the **last Tier-1 mined item** — the cluster
  (`arch-review`, `modernize`, `plan-review`, `write-documentation`,
  `debug-assistant`, `deps-update`) is now fully adopted. Idea-level
  (ADR-0002). Landed via dotfiles PR.
- 2026-06-11 — **Opened the `troubleshooting` category (thin always-on).**
  Added a **deliberately thin** always-on `rules/troubleshooting.md` carrying
  only the debugging *bar* (reproduce-first, root-cause-not-symptom,
  regression-test-per-fix) plus a pointer — kept always-on, unlike a
  path-scoped rule, because a failure can surface on **any** turn (a bug
  report, a red test, surprising behaviour mid-build), so the guardrail must
  be present whenever it's needed; kept thin (the depth is in the skill) to
  respect the always-on-tier anti-bloat guardrail. Built the Tier-1
  **`debug-assistant`** skill (the scientific-method session: reproduce →
  capture evidence → isolate by bisection → one hypothesis at a time → fix the
  root cause → regression-test → verify with `qa-check`). **Not wired into
  `qa.md`** — troubleshooting is the diagnostic activity triggered *when* a
  check or behaviour fails, a peer category, not a qa gate dimension. The
  **ops facet** (`devops-troubleshooter`) stays build-on-first-use (ADR-0003);
  the planned `resolve-issue` skill will compose `debug-assistant`. This
  **completes the Tier-1 cluster** (only `deps-update` remains). Idea-level
  adaptation (ADR-0002). Landed via dotfiles PR.
- 2026-06-11 — **Opened the `documentation` category.** Added an always-on
  `rules/documentation.md` (the doc **bar** + the "right form per audience"
  **stance**), modeled on `testing.md`, as the canonical home for what had
  been scattered: `code-style.md` keeps the writing *mechanics*,
  `markdownlint.md` the *linter*, `qa.md` dim 13 the *pipeline gate* — dim 13
  now **points to** `documentation.md` for the bar instead of restating the
  audience list (qa wired last, per the umbrella rule). Built the Tier-1
  **`write-documentation`** skill (the authoring *how*), consolidating three
  mined items — `write-documentation` + `documentation-architect` +
  `api-documenter` (folded as the API-doc mode; FastAPI auto-OpenAPI layered
  to `fastapi-patterns`). **Deliberately held out** of the category as
  adjacent-but-different: `handoff`/`standup`/`dev-docs-update` (session
  continuity) and `dev-docs`/`read-specs`/`feature-specification` (spec→plan)
  — a future *workflow*/planning category, not product docs. Idea-level
  adaptation (ADR-0002): no upstream code reused, `SOURCE.md` records the
  census ideas. Landed via dotfiles PR.
- 2026-06-10 — **A (MCP plugins): done globally.** terraform + serena
  disabled (user-level); re-enable per-repo via project/local MCP
  registration. terraform needed in harleydev.
- 2026-06-10 — **B (path-scope 9 rules): done.** java, vitest, vite, react,
  mantine, fastapi, sqlalchemy, alembic, html now `paths:`-scoped.
- 2026-06-10 — **C (zap.md): done.** scoped to compose/Dockerfile globs
  (approximate; could later fold into the security-scan skill).
- 2026-06-10 — **D (TEMPLATE.md): done.** moved to
  `config/claude/rule-TEMPLATE.md`, out of the rules auto-load.
- 2026-06-10 — **E (plugins): partial.** duplicate commit-commands removed;
  borderline plugins (code-review, pr-review-toolkit, ralph-loop,
  pydantic-ai, jdtls-lsp) left enabled **until their repos are audited**
  (global-impact caveat — they may be needed elsewhere; revisit per-repo).
- 2026-06-10 — **F (Codecov): deferred** by request.
- 2026-06-10 — **Plugin audit (global-fit pass; supersedes E above).**
  Dropped (redundant with built-ins / not a good global fit): `code-review` &
  `code-simplifier` (built-in `/review`, `/simplify` cover them; the latter
  was also JS-only and misfit this repo), `commit-commands` (`ship-pr` +
  `git-worktree-workflow` are stronger, and its `/commit*` violate the staging
  rules), `jdtls-lsp` and `pydantic-ai` (niche). Kept: the authoring triad
  (skill-creator / claude-md-management / hookify), context7,
  claude-code-setup, `ralph-loop` (to trial — distinct from `/loop`), and
  `pr-review-toolkit` / `feature-dev` / `security-guidance` (decide-later).
  Follow-ups in `TODO.md`.
- 2026-06-10 — **Plugin audit, round 2 (the three decide-later): all dropped.**
  `pr-review-toolkit` (6 always-on agents; redundant with built-in `/review`,
  `/code-review`, `/simplify` + `qa.md`), `feature-dev` (agents dup
  Explore/Plan; the value was the command's orchestration), and
  `security-guidance` (a **blocking** PreToolUse hook matching JS/TS/py
  substrings — false-positives on Bash, references non-existent files;
  `security-scan` / `semgrep` / `/security-review` already cover it).
  `enabledPlugins` now 6: context7, the authoring triad, claude-code-setup,
  ralph-loop. Vendor bits left as surface-when-needed TODOs.
- 2026-06-11 — **pigify-triggered: pydantic/FastAPI/SQLAlchemy pattern
  skills.** Resolved the earlier `pydantic-ai` name-conflation (the agent
  framework vs AI-assisted pydantic work). Mined four repos (see *Idea
  sources*) and **adapted** — not vendored — two global on-demand skills:
  `fastapi-patterns` and `sqlalchemy-patterns`, rendered in the native-`Depends`
  house idiom, each cross-linked from the slim path-scoped rules
  (`fastapi.md`/`sqlalchemy.md`/`alembic.md`) so the always-on tier stays lean.
  Established the **provenance policy**: per-artifact `SOURCE.md` cites a repo
  only when implementation detail was reused; idea-only sources go in the *Idea
  sources* registry. **No edit-time hook** (conflicts with "auto-fixers run
  once"); instead each skill has a troubleshooting step pointing at `qa-check`.
  Landed via dotfiles PR.
- 2026-06-11 — **Mined the shortlist; adopted ADR, skipped the rest.** 8 of 9
  candidate agents/commands were already covered (see *Audit backlog*); only
  ADR was additive. Added a generic `adr` skill (Nygard template, house style)
  and a second ADR area for this subsystem at `config/claude/adr/` — distinct
  from the running *Decisions log* (granularity boundary documented in the
  skill). Two decisions of record formalized by **dogfooding** ADR:
  **ADR-0001** (skills over custom commands) and **ADR-0002** (adapt-not-vendor;
  `SOURCE.md` only on implementation reuse). The dotfiles-system `docs/adr/`
  area is out of audit scope — created when its first decision arises. Landed
  via dotfiles PR.
- 2026-06-11 — **Full mining census + discovery method (corrective).** The
  earlier mining evaluated a pre-filtered shortlist of 9 and under-weighted
  generic, whole-environment value. Corrected: charted **all ~158 items** across
  the four repos into `audit/mining-census.md` (ADOPT/CANDIDATE/SKIP + reason),
  and documented two practices in the claude-audit skill — **source discovery**
  (official-first → stars+recency+maintenance-health; >1yr staleness gate,
  re-evaluate not discard) and **full-census + generic-lens mining** (enumerate
  the whole surface, judge by value to *any* repo, treat an agent/command as a
  candidate even when reimplemented as a skill). Surfaced a tiered CANDIDATE
  backlog (strongest: the architecture/codebase-analysis cluster). Landed via
  dotfiles PR.
- 2026-06-11 — **Placement refinement (ADR-0003).** Guidance for anything
  *foreign to the current repo* (a third-party library, or our own code in a
  different repo) is **global and front-loaded** — authored as a global
  skill/rule the first time any repo uses it, even for single-repo use, rather
  than repo-local or deferred. Corrected the mining census Tier-3 mislabel
  ("per-repo need" → global/build-on-first-use) and documented the principle in
  `EXTENDING.md`. Reconciles with the Rule of Three (which guards *our own*
  code, not stable external libraries).
