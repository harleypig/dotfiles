# Audit backlog

A **todo file** for **Claude-agent-config** work (`config/claude/` — rules,
skills, hooks, agent-config docs), kept separate from the dotfiles `TODO.md`
to avoid confusion. Includes both audit-process follow-ups and config tasks
migrated from `TODO.md`. **Routing:** a config task lands here; a dotfiles task
in `TODO.md`; a mixed task is split with a cross-reference unless its parts are
merely coupled (see `WORKFLOW.md` → *TODO routing*). Read when running
`/claude-audit`. Audit-only (not context-loaded). Completed items are
summarized in [`decisions-log.md`](decisions-log.md) and retained here for
continuity; mined-repo provenance in [`idea-sources.md`](idea-sources.md).

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

## Repo-config follow-ups (migrated from TODO.md, 2026-06-19)

These were tracked in the dotfiles `TODO.md` but are Claude-agent-config
work (rules, skills, plugins, agent-config docs) — moved here per the TODO
routing convention (see the header). Provenance preserved verbatim.

### 📊 Slim down the STRUCTURE.md mermaid diagram (HIGH PRIORITY / LOW IMPORTANCE — IN PROGRESS)

**Status:** in progress — pick-at-it. High priority (surface it when the repo
is touched) but low importance (nothing depends on it; purely a readability
nicety). Lives on branch `docs/structure-diagram`, no PR yet.

`config/claude/STRUCTURE.md` (added in ea9cdbd) renders the agent-config
relationships as a Mermaid flowchart, but the diagram is too big/wide to read
comfortably. Make it less sprawling without losing the relationships it maps.

- [ ] Reduce the diagram's width/sprawl — e.g. group related nodes into
  subgraphs, split into smaller diagrams per concern, prune low-value edges,
  or change layout direction — so it reads on a normal screen.
- [ ] Verify the rendered result in Brave, not the user's Chrome (Chrome
  blocks GitHub's mermaid sandbox).

### 🔎 CodeFactor & Snyk: Use Their Output? Rule/Skill? (MEDIUM PRIORITY)

Both run as PR checks (alongside `bats`), but we don't yet act on their
findings. Research how to actually use each and whether to formalize it.

- [ ] **CodeFactor**: what it analyzes, where findings surface (PR inline
  comments, the codefactor.io dashboard, the badge), how to configure it
  (`.codefactor.yml`), and how to triage/suppress. Decide if it earns a
  required status check.
- [ ] **Snyk** (`security/snyk`): what the check scans (deps / code / IaC?),
  where findings live (app.snyk.io, PR annotations), its auth/config, and how
  it overlaps with Dependabot and the existing security rules
  (`semgrep`/`trivy`/`osv-scanner`) plus the `security-scan` skill.
- [ ] Decide **per tool**: a `config/claude/rules/<tool>.md` (how to read and
  act on its output), a skill, folding into the existing `security-scan` skill
  / `qa.md` security dimension, or nothing — without duplicating what those
  already cover.
- [ ] If a tool adds no actionable value, consider disabling its check to cut
  PR-check noise; if it does, document the triage workflow.

### 🔭 Document the kept-branch-after-squash sync mechanic (LOW PRIORITY)

Retrospective follow-up (PR #117). When a batch branch is **kept** after a
squash-merge to continue working, syncing it with `git merge master` carries
the already-merged commits forward as redundant history that pollutes the next
PR's commit list — PR #117 needed a `git rebase --onto master <merge>` cleanup
before its commit list was tidy.

- [ ] Document the clean mechanic in `git.md` (or the ship-pr / batch
  workflow): after a squash-merge with the branch kept, sync via
  `git reset --hard origin/master` (the batch is already in master) or
  `git rebase --onto`, **not** `git merge master`. (Already captured in the
  batch-todos working memory; promote to a rule note so it isn't memory-only.)

### 🧭 Audit Project .claude/ Dirs for Promotable Rules/Skills (MEDIUM PRIORITY)

Review every repo under `$PROJECTS_DIR` and decide, per the three-tier model
in `CLAUDE.md`, whether anything repo-local in its `.claude/` should be
promoted to the global config (`config/claude/rules/` or `.../skills/`).

- [ ] Enumerate projects with a `.claude/`:
  `find "$PROJECTS_DIR" -maxdepth 2 -name .claude -type d`.
- [ ] For each, compare its `rules/`, `skills/`, and CONVENTIONS/WORKFLOW/
  TESTS against the global set; flag anything language- or repo-agnostic
  (tier 1/2) that's repo-local or duplicated.
- [ ] Promote tier-1/2 items to global `config/claude/rules/<name>.md` or
  `config/claude/skills/`; leave truly repo-specific bits in place.
- [ ] Consolidate drift: the same rule copied (and diverging) across repos
  should become one global source that repos reference.
- [ ] Note any project that lacks a `.claude/` but should have one.

### 🧪 Dogfood skill-creator on the retrospective skill (LOW PRIORITY)

Retrospective follow-up (from the PR that added the `retrospective` skill):
`EXTENDING.md` now says to use **skill-creator** when authoring a skill, but
`retrospective` predated that rule.

**Blocked on the trigger eval:** dogfooding skill-creator on `ship-pr` showed
`run_eval.py` returns **0% regardless** on CC 2.1.x (upstream issue #2003 + a
command-vs-`Skill` detection gap — see `config/claude/audit/decisions-log.md`).
So the automated
triggering eval won't help here until upstream fixes it.

**Reconfirmed (PR #115):** the *modify-an-existing-skill* path is unusable too
— extending `test-review` was done by hand because skill-creator's
improve/optimize loop depends on the same broken `run_eval`. So skill-creator
helps with neither new-skill eval nor existing-skill edits on CC 2.1.x; treat
it as conceptual guidance only until #2003 is fixed.

- [ ] When upstream fixes #2003 (or we vendor + patch `run_eval`), run the
  trigger eval + description optimizer on `retrospective`.
- [ ] Meanwhile, do a **manual** triggering judgment + instruction-review of
  `retrospective` (the value skill-creator delivers that isn't blocked).

### 🔌 skill-creator plugin upgrade + marketplace path-corruption (MEDIUM PRIORITY)

Surfaced while dogfooding skill-creator (see
`config/claude/audit/decisions-log.md`).

- [ ] **Fix the marketplace path-corruption.** CC 2.1.181 rejects the
  `claude-plugins-official` marketplace because its recorded `installLocation`
  is the `~/.claude/...` **symlink** path, not the real
  `config/claude/plugins/marketplaces/...` path (the `~/.claude → config/claude`
  symlink). It blocks `claude plugin marketplace update` / `plugin update`.
  Sanctioned fix: `claude plugin marketplace remove claude-plugins-official`
  then re-add — **global** (re-pulls all that marketplace's plugins; may shift
  versions), so do it deliberately. Affects *all* plugin management, not just
  skill-creator.
- [ ] **Then upgrade `skill-creator`** to current upstream — its
  `improve_description.py` dropped the `anthropic` SDK / API-key requirement
  (now `claude -p`-based, 2026-04-23). Note: `run_eval.py` is unchanged
  upstream, so the upgrade does **not** fix the broken trigger eval (still
  gated on #2003).

### 🧠 Claude Rules Files (MEDIUM PRIORITY)

Rules files in `config/claude/rules/` (global, `~/.claude/rules/`) tell the
agent how to use each tool. Already have, among others: bash, perl,
powershell, pre-commit, python, shellcheck, shfmt, yamllint, markdownlint,
yapf, git, gh, bats, docker (plus `.editorconfig` coverage for shfmt).

- [ ] Remaining rules to author:
  - [ ] new project setup — rule covering the general checklist for
    initializing a project (git init, pre-commit, .claude/ scaffold,
    DEVELOPER.md, TODO.md, etc.); evaluate splitting language-specific
    bootstrapping steps (e.g. NeoForge MDK, Poetry, npm init) into the
    relevant per-language rules file rather than bloating the general rule.
    Points to consider from experience:
    - Investigate actual storage/file formats before designing around them;
      official docs may describe outdated formats (e.g. JourneyMap switched
      from per-waypoint JSON to a binary DAT in 6.x without updating docs)
    - Check whether related/foreign repos are already cloned as siblings
      before suggesting clone locations (../reponame convention)
    - Defer .claude/ scaffold until project-specific conventions emerge;
      Phase 0 setup rarely produces enough repo-specific content to justify it
    - Editor config belongs in the editor's own config repo, not the project;
      DEVELOPER.md should note the maintainer's editor but not prescribe setup
    - When adding language support to an editor config, verify that
      indentation and formatting settings match the chosen formatter's output
      rather than blindly following language community conventions (e.g.
      google-java-format uses 2-space, not the traditional 4-space Java style)
    - New project setup frequently exposes gaps in existing global config
      (missing docs, redundant settings, stale paths); capture these as
      follow-up items in the relevant repo's TODO rather than blocking setup
    - DEVELOPER.md should cover the full build/test workflow including
      platform-specific quirks (e.g. build in WSL2, test in Windows Minecraft)
    - Pin pre-commit hook versions to current stable at time of setup;
      note that versions need periodic review as hooks release updates
    - Document the rationale for non-obvious decisions (e.g. why 2-space
      Java indent) so future sessions don't relitigate them
  - [ ] commitizen — rule and/or skill for conventional commit message
    formatting; evaluate whether a rule (policy + invocation) is sufficient
    or whether the multi-step workflow warrants a skill
  - [ ] git tagging — rule and/or skill for version tag conventions (semver
    vs calver, signed vs unsigned, when to tag vs branch, how tags relate
    to release branches); likely a rule unless the tagging+push+release
    sequence is complex enough to warrant a skill
  - [ ] changelog generation — rule and/or skill for producing changelogs
    from git history on version changes; evaluate tools (git-cliff,
    conventional-changelog, keep-a-changelog manual pattern) and whether
    changelog generation should be part of a broader release skill alongside
    tagging and commitizen
  - [ ] Any other tools discovered during pre-commit or CI work
- [ ] Add a "best practices" rules/skills layer. The current
  `rules/code-style.md` may be better recast as a general best-practices
  document with language-specific subdocuments — i.e. a shared core that
  per-language rules files extend. Decide structure: one general
  best-practices doc + per-language extensions, vs. keeping `code-style.md`
  as the shared base that the language rules reference.
- [ ] When creating/modifying a rule or skill, check known sources for an
  existing implementation to adapt (vendor with a `SOURCE.md` and audit to
  fit) rather than authoring from scratch:
  - GitHub (search repos/topics)
  - <https://github.com/VoltAgent/awesome-agent-skills>
  - <https://officialskills.sh/>
  - other locations as discovered
  Ties into the vendored file/skill update checker (see Configuration
  Enhancements → Dependency Management).

### 🤖 Claude Code -> local OpenWebUI offload (HIGH IMPORTANCE, LOW PRIORITY)

**Importance: high** (cost, privacy, and actually leveraging the dedicated
AI box, `beaker`). **Priority: low** (exploratory; depends on beaker's GPU
stack being finished and on finding the right integration point).

Idea: route the simpler, high-volume Claude Code subtasks to a locally
hosted model served from my own OpenWebUI/Ollama on `beaker` (see
`bin/openwebui`, `bin/ollama`), keeping the heavy reasoning on Claude.
Start with cheap, well-bounded work — qa-check triage, running and
evaluating test output, summaries — then generalize.

- [ ] Find the integration surface. Claude Code's main loop is
  Anthropic-only, so investigate the realistic hook points:
  - a **hook** (`PostToolUse`, etc.) that shells out to a local-LLM
    script for a specific check;
  - a **subagent** or **MCP server** that wraps the local endpoint;
  - the **Claude Agent SDK** for a custom delegating agent.
- [ ] Pick the API: OpenWebUI exposes an OpenAI-compatible endpoint;
  Ollama serves its own API on `:11434`. Decide which to target.
- [ ] Choose local model(s) sized for beaker's RTX 4080 (~12 GB VRAM) and
  capable enough for the offloaded tier (code-aware small/mid models).
- [ ] Define the task split: what is safe to delegate (triage, test-output
  evaluation, summarization) vs. what stays on Claude.
- [ ] Evaluate quality / cost / latency on real tasks before adopting; keep
  a fallback to Claude when the local model is unsure.
- [ ] Depends on: beaker GPU setup (driver + NVIDIA Container Toolkit) and
  ollama/openwebui running.

## tmptodo intake (2026-06-19)

Captured from a scratch `tmptodo.txt` and routed here per the TODO-routing
convention — every item proved to be Claude-agent-config work. Guiding
principle the user attached: keep rules/skills small and focused, breaking a
topic into sub-areas (e.g. api-testing vs optimization vs refactor) when that
helps.

### Mining queue

Mine one repo at a time; **don't decide until all are mined** (expect
duplicates / similar setups). Chart each in
[`mining-census.md`](mining-census.md) and promote useful sources to
[`idea-sources.md`](idea-sources.md). None below are mined yet.

- [ ] **Anthropic official plugins — text re-mine of `code-simplifier` +
  `commit-commands`.** Both were dropped at *capability* level (decisions log
  2026-06-10) **without** a text-level review, and both have our equivalents
  (`/simplify`; the git rules + `ship-pr` / `git-worktree-workflow`). Review
  their actual prompt/command text for wording / sectioning worth folding into
  ours. The other three (`pr-review-toolkit`, `feature-dev`,
  `security-guidance`) were already content-reviewed — their extractable bits
  are the vendor-when-needed items under *Plugin-audit follow-ups*; not
  re-opened.
  - <https://github.com/anthropics/claude-plugins-official/tree/main/plugins/code-simplifier>
  - <https://github.com/anthropics/claude-plugins-official/tree/main/plugins/commit-commands>
- [ ] **Plugin/skill collection repos (big — one at a time).**
  - <https://github.com/ComposioHQ/awesome-claude-plugins>
  - <https://github.com/jeremylongshore/claude-code-plugins-plus-skills>
  - <https://github.com/ccplugins/awesome-claude-code-plugins>
  - <https://github.com/alirezarezvani/claude-skills>
  - <https://github.com/JuliusBrussee/caveman>
  - <https://github.com/sickn33/antigravity-awesome-skills>
  - <https://github.com/chopratejas/headroom>
  - <https://github.com/VoltAgent/awesome-claude-code-subagents>
  - <https://github.com/Jeffallan/claude-skills>
  - <https://github.com/team-attention/plugins-for-claude-natives/tree/main/plugins/clarify>
  - <https://github.com/JoasASantos/ClaudeAdvancedPlugins>
- [ ] **`ykdojo/claude-code-tips`** — a tips collection (not skills); codify any
  into a rule/skill. <https://github.com/ykdojo/claude-code-tips>
- [ ] **`ruvnet/ruflo`** — evaluate whether worth exploring (not a
  plugin/skill). <https://github.com/ruvnet/ruflo>

### Skill-format standard: agentskills.io

- [ ] Investigate whether <https://agentskills.io> is a real/emerging standard
  (does Anthropic or another AI vendor back it?). If meaningful, align our
  skills' format to it.

### Claude statusline enhancements (claude-hud candidates)

Done 2026-06-19 (fixed + regression-tested; see the decisions log): the display
bug (leading empty field + a field-shift from the empty `.vim.mode` column —
root-caused to the whitespace-`IFS`/`@tsv` parse, now joined on the unit
separator so absent fields are safe), the context-% prominence, the
**reasoning-effort `[level]`** indicator (`.effort.level`), the
**rate-limit usage segment** (`5h:`/`7d:` `used_percentage` riding inside the
context segment, colored by the shared pct ramp; hidden for non-subscribers),
and the **vim-mode segment** (`.vim.mode` rendered ourselves with
`hideVimModeIndicator: true` — NORMAL is bright-yellow-on-red, INSERT/others
standard; leads the line). `jarrodwatts/claude-hud` was mined — full matrix in
[`mining/claude-hud.md`](mining/claude-hud.md). Remaining candidates:

- [ ] **Investigate `statusLine.subagentStatusLine`** (surfaced 2026-06-19
  while confirming the PR-badge can't be hidden). It's a `statusLine` sub-field
  that *formats* subagent rows. **Decide if it's worth using by answering one
  thing: does it OVERRIDE the native subagent line or ADD to it?** If it
  **overrides** (replaces the native row format), great — it's the one native
  below-prompt element we *can* take control of, so we could restyle the
  subagent display our way. If it only **adds** a custom row alongside the
  native one, it would **duplicate** output — not what we want, so skip.
  Ground the answer in the docs + a quick trial (fire a background subagent and
  watch the row) before wiring anything.
- [ ] **Heavier candidates** (transcript-driven — defer): the tools/agents
  lines and todos `(2/5)`. *(2026-06-19: project path, session duration, output
  speed, and token totals were skipped by the user; the context progress-bar
  glyph is `SKIP-until` on the census watch list — revisit if the plain `X%`
  stops being enough.)*

**`ICEBOX:` cannot hide the native below-prompt indicator lines** — the
**auto-accept / permission-mode** indicator (`⏵⏵ auto mode on`), the
**running-subagent / task** line, and the **`· PR #N`** badge have **no
off-switch** (settings, env, or flag) as of 2026-06-19 — verified against the
Claude Code docs and by re-examining `claude-hud` (which sets no suppression
key, can't even read the permission mode, and only stacks a transcript-parsed
agents line *on top of* the native one). The only documented `statusLine` hide
field is `hideVimModeIndicator`; the full set of `statusLine` sub-fields is
`type` / `command` / `padding` / `refreshInterval` / `hideVimModeIndicator` /
`subagentStatusLine` (the last **formats** subagent rows — it does **not** hide
the native line). Consequence: reconstructing any of these (PR#, permission
mode, agents) in our own statusline would only **duplicate** the un-hideable
native badge, so it isn't worth it — the permission mode and PR# are both in
the data (permission mode in the **transcript** `permission-mode`/`mode`
entries; `.pr.number` in the **stdin** JSON), they just can't replace the
native display. Open upstream requests: anthropics/claude-code **#27916**,
**#48246**. Revisit if either lands a hide option; until then, only the vim
indicator was controllable (and is done).

### Claude Code compaction control (moved from TODO.md)

Can we steer *when* and *how* Claude Code compacts context? Two
`claude-code-guide` lookups on 2026-06-19 conflicted on the central question
below, so it needs settling against current official docs (not memory) before
acting.

- [ ] **Verify the `# Compact instructions` CLAUDE.md feature.** One lookup
  asserted a special heading in CLAUDE.md steers what compaction preserves; a
  second, more thorough search of `code.claude.com/docs` found **no documented
  heading-matching feature** of that name. Settle which is true. If real → add
  the block to global `config/claude/CLAUDE.md`. If not → it's only ordinary
  guidance text the model happens to see (CLAUDE.md is in context during
  compaction; project-root CLAUDE.md is re-injected from disk after), with no
  dedicated engine — don't oversell it.
- [ ] **Evaluate a `SessionStart`/`compact` hook** as the documented, reliable
  lever for "make X survive compaction": its stdout is injected into context
  after a compaction. Decide whether it's worth wiring for this setup.

Confirmed (not in question): there is **no** config to change the auto-compact
*threshold*; `autoCompactEnabled: false` (or `DISABLE_AUTO_COMPACT=1`) disables
it entirely; the statusline script is the only programmatic read of context
fullness (`context_window.used_percentage` etc. — hooks can't read it); and
`/compact` cannot be triggered programmatically (user-only). The statusline
already color-codes context %, so the current workflow is manual `/compact`
(see "Statusline Coordination").

### New rule/skill candidates

- [ ] **Gollum Wiki** rule (wiki engine).
- [ ] **Ruby** rule — especially as it relates to the Gollum wiki.
- [ ] **Essay Helper** skill — for the scripturestudy.org wiki ("LDS Scholar").
