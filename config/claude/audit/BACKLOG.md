# Audit backlog

Open follow-up tasks for the audit itself — **a todo file** (this repo's own
`TODO.md` tracks dotfiles work; this tracks audit work, kept separate to avoid
confusion). Read when running `/claude-audit`. Audit-only (not context-loaded).
Completed items are summarized in [`decisions-log.md`](decisions-log.md);
mined-repo provenance in [`idea-sources.md`](idea-sources.md). Completed items
are retained here for continuity.

## Always-on rule scoping

- [ ] **Evaluate `claude-code-auth.md` and `trufflehog.md` for path-scoping
  (2026-06-19 audit).** These two are the only single-purpose rules still
  always-on (no `paths:`) after the 2026-06-10 scoping pass — 9 always-on
  total, of which 7 are genuinely cross-cutting (`code-style`,
  `documentation`, `gh`, `git`, `qa`, `testing`, `troubleshooting`).
  `trufflehog.md` (PR-time secret scanning) could scope to
  `.github/workflows/**`; `claude-code-auth.md` is niche but has no natural
  file glob (it is about the agent's own auth, not repo files) — may be a
  legitimate always-on, or fold its essence elsewhere. Decide per rule; low
  cost (~166 lines combined), low urgency.

## Audit dimensions / design

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

## Plugin-audit follow-ups (from the 2026-06-10/-11 passes)

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
- [x] **Decided: dropped `ralph-loop`** (2026-06-18) — not trialed; built-in
  `/loop` covers autonomous iteration. See Decisions log. ICEBOX preserves the
  exit-blocking technique as a revisit, *via `/loop`* rather than new
  machinery.
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

## Skill ideas & future categories (not from mining)

- [ ] **Rule eval / optimization (analogous to `skill-creator`)** — `skill-
  creator` measures whether a *skill* triggers on the right prompts and does
  its job (evals/benchmarks + a description-trigger optimizer). Investigate the
  same for *rules*: can we measure whether a rule is actually applied at the
  right moments, and optimize its wording/`paths:` so it fires when it should?
  Decide only **after** we have exercised skill-creator enough to judge the
  approach's worth (see the skill-creator decision in the Decisions log). May
  reuse skill-creator's harness rather than build new.
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
