# Audit backlog

A **todo file** for **Claude-agent-config** work (`config/claude/` — rules,
skills, hooks, agent-config docs), kept separate from the dotfiles `TODO.md`
to avoid confusion. Includes both audit-process follow-ups and config tasks
migrated from `TODO.md`. **Routing:** a config task lands here; a dotfiles task
in `TODO.md`; a mixed task is split with a cross-reference unless its parts are
merely coupled (see `WORKFLOW.md` → *TODO routing*). Read when running
`/claude-audit`. Audit-only (not context-loaded). This file holds only
**actionable, will-do** work — *not* deferred or trigger-gated items:

- **Completed** items are recorded in [`decisions-log.md`](decisions-log.md)
  (the durable record) and **pruned from here once the PR that completes them
  goes green**.
- **Deferred / "not now"** decisions of our own go to
  [`ICEBOX.md`](ICEBOX.md) (revisit on a trigger or on request) — not here.
- **Mined external** candidates deferred `SKIP-until <trigger>` live on the
  [`mining-census.md`](mining-census.md) *Watch list*; mined-repo provenance
  is in [`idea-sources.md`](idea-sources.md) / `mining-census.md`.

## Skill ideas & future categories (not from mining)

- [ ] **`push-pr`: document "PR already open" resume path (2026-06-20)** —
  When `/push-pr` is invoked and the PR was already opened in a prior session,
  the skill has no explicit "pick up here" guidance. The agent must reason
  through which steps to skip (no new commit needed; PR exists → skip Step 3;
  jump to Step 1 QA + Step 4 CI-watch). A short note in Step 0 or Step 3 —
  e.g. "if the PR already exists, skip Step 3 and resume from Step 1 QA / Step
  4 CI-watch" — would remove the ambiguity for future sessions. Surfaced
  during PR #141 ship.

- [ ] **Rule eval / optimization (analogous to `skill-creator`)** —
  `skill-creator` measures whether a *skill* triggers on the right prompts
  and does its job (evals/benchmarks + a description-trigger optimizer).
  Investigate the same for *rules*: can we measure whether a rule is actually
  applied at the right moments, and optimize its wording/`paths:` so it fires
  when it should? Decide only **after** we have exercised skill-creator enough
  to judge the approach's worth (see the skill-creator decision in the
  Decisions log). May reuse skill-creator's harness rather than build new.
- [ ] **`resolve-issue` skill** — orchestrate `gh` issue resolution: fetch
  issue → **agent** investigates it against the codebase via the
  `debug-assistant` skill (root cause, "simple or not", proposed fix or a
  question) → decide → fix → open PR with `Closes #X` → merge. The
  investigation is an agent; **PR-open and merge stay gated** per `gh.md` ("no
  PR create/merge without explicit approval") unless a deliberately opted-in
  autonomous variant with guardrails (trivial-only, after CI green) is built.
  Tools/category: `gh`.
- [ ] **`categorize-issue` skill** — triage a `gh` issue: suggest
  labels/priority/estimate from codebase context and fold it into the repo's
  TODO triage queue (the `gh.md` *Issues & triage* workflow). Category: `gh`.
- [ ] **Future top-level categories.** Fold a new capability into an existing
  category (`code-style` / `testing` / `qa` / `gh` / `git`); open a new
  top-level category only when it genuinely doesn't fit. (`documentation` and
  `troubleshooting` were opened 2026-06-11 — see the decisions log.)

- [ ] **UI/UX design skills (CLI / windowed / web), beyond `frontend-design`
  (2026-06-27).** `frontend-design` (vendored, Apache-2.0) covers **web** UI
  *visual design* only — its triggers are web components / pages / React /
  HTML-CSS, and it's aesthetics-focused, not UX (flows, information
  architecture, usability). UI/UX differs by **surface**; the major ones: a
  **CLI** (terminal output formatting, prompts, progress, color, TUI layout),
  a **windowed / desktop app** (native GUI), and a **web app** (covered by
  `frontend-design`). Evaluate whether to add design skills for the uncovered
  surfaces — likely a **CLI-design** skill (high value here: this repo is
  CLI-heavy) and a **desktop/windowed-design** skill — and whether a thin,
  surface-agnostic **UX layer** (design thinking / flows / usability) should
  sit over the surface-specific skills, per the two-layer model in
  `EXTENDING.md` *Layer the generic over the specific*. Keep `frontend-design`
  as the web instance; don't duplicate its coverage. Relates to `a11y-review`
  (accessibility *review*) and `qa.md` dim 7 (UI/UX & accessibility).

- [ ] **Learning about Claude — build understandable, layered docs
  (2026-06-27, broadened from "sub-agent research" 2026-07-02).** Recreate
  the Claude Code documentation in a form the user actually absorbs: a plain
  ELI5 layer over a conceptual model, plus practical usage that follows the
  three-tier generic→specific philosophy (`CLAUDE.md` *Configuration
  Migration*). `config/claude/docs/TOPIC.md.template` is the **template** for
  the shape (abstract → ELI5 + best-practices → overview / at-a-glance →
  major groups → optional bring-it-together → see-also → resources);
  `config/claude/docs/LOOPS-WORKFLOWS.md` is the first **worked instance**.
  Each doc lives in `config/claude/docs/`; the open question per topic is
  which graduate to a `rules/<x>.md` (agent behaviour) vs. stay a reference
  doc. The template is a **guide, not a cage** — a specific topic may bypass
  or bend it where the shape genuinely doesn't fit (note the deviation on
  that doc), and when the **template itself changes, re-audit the existing
  docs and reflow them** to the new shape. Topics to document next — each its
  own doc, same shape:
  - [ ] **Sub-agents.** How to *use* them well (delegate-vs-inline —
    `EXTENDING.md` *Agent* gives the principle, not a routine), how to
    *define* them (custom agent types, tool restrictions, system prompts),
    and **effort levels**: the Agent/Workflow tooling exposes an `effort`
    knob (low/medium/high/…) with no guidance on *which* a task warrants.
    Investigate estimating a task's effort and **auto-assigning** the right
    sub-agent (model tier + effort + agent type) from the description, and —
    the harder half — whether a sub-agent can **recognize a mis-guess and
    kick the task back** ("bigger/smaller than scoped; re-route") instead of
    grinding at the wrong level. This one's output may be a **rule and/or
    skill**, not just a doc (the original 2026-06-27 research item). Generic.
  - [ ] **Hooks.** Event-driven automation (`PreToolUse` / `PostToolUse` /
    `SessionStart` / task-lifecycle) — the reactive family the loops doc
    points at; the *understanding* doc over our existing hook rules/hooks.
  - [ ] **Channels** (research preview). External systems pushing events
    into a running session — the push counterpart to poll/timer loops.
  - [ ] **Permission modes & auto mode.** `acceptEdits` / `dontAsk` / `auto`
    / bypass and the `autoMode` classifier; how unattended work is gated.
    Consider **extracting the auto-mode section out of
    `LOOPS-WORKFLOWS.md`** into this dedicated modes doc once it exists (it
    lives in the loops section there only because it gates loops).
  - [ ] **Headless / programmatic.** `claude -p`, `--resume` / `--continue`,
    output formats, the Agent SDK — the surface for driving Claude from
    scripts / CI.
  - [ ] **Agent teams** (experimental). Peer-coordinating multi-agent work;
    the deep-dive the loops doc only summarizes.
  - [ ] **GitHub Actions integration.** GitHub-native triggers for Claude
    work; cross-reference the existing `rules/github-actions.md`.
  - [ ] **Observability.** `/tasks`, `/workflows`, `claude agents`, `/usage`
    — monitoring unattended work.
  - [x] **Reflect `config/claude/docs/` in `STRUCTURE.md`** (retrospective,
    PR #205). The new understandable-docs series and `TOPIC.md.template` are
    a structural addition to the agent config that the `STRUCTURE.md`
    reference map does not yet list; decide how the `docs/` tree is
    represented there and add it.
  Generic (global; docs under `config/claude/docs/`).

## Repo-config follow-ups (migrated from TODO.md, 2026-06-19)

These were tracked in the dotfiles `TODO.md` but are Claude-agent-config
work (rules, skills, plugins, agent-config docs) — moved here per the TODO
routing convention (see the header). Provenance preserved verbatim.

### 🧹 Three rule refinements from the QA linter-gates PR (harleydev #83) (LOW PRIORITY)

Surfaced while shipping harleydev PR #83 (enabling six phased pre-commit
linters — tflint, hadolint, shfmt, shellcheck, yamllint, markdownlint); small
doc-rule additions, not edits yet.

- [ ] **`pre-commit.md` (+ `shellcheck.md` / `shfmt.md`): document the
  non-exec extensionless-shell hook variant.** pre-commit's `identify` tags a
  file `shell` from a shebang only on an *executable* file, so non-executable
  extensionless shell (a `# shellcheck shell=bash` lib with no shebang, a
  sourced `service-config-loader`, non-exec event handlers) is silently
  ungated under a default `types: [shell]` shellcheck/shfmt hook. The fix is a
  second hook entry (`alias: *-sourced`, `types: [text]`) with a path-based
  `files:` regex — which had to be rediscovered from the dotfiles
  `.pre-commit-config.yaml` `&sourced_shell` anchor. Add a short note plus the
  two-hook snippet. Scope: **global**. Pointer: harleydev
  `.pre-commit-config.yaml` (shfmt-sourced / shellcheck-sourced hooks).
- [ ] **`pre-commit.md` (+ `hadolint.md` / `yamllint.md`): a docker-image or
  otherwise containerized hook can't see the global `~/.config`, so gate it
  with a repo-local config mirroring the baseline.** `hadolint-docker` runs in
  a container and never sees `~/.config/hadolint.yaml`; with no repo-local
  `.hadolint.yaml` it defaults to failure-threshold `info` (not the global
  `warning`) and loses the trusted-registries set. Same class of problem for
  the yamllint hook's relaxations. `hadolint.md` / `yamllint.md` note
  repo-local *precedence* but not this "you **must** mirror the baseline when
  gating via a containerized hook" step. Scope: **global**. Pointer: harleydev
  `.hadolint.yaml`, `.yamllint`.
- [ ] **`todo.md`: don't bake volatile counts into planning items.** A
  harleydev TODO item read "markdownlint: ~3715 issues across 61 files"; the
  real figure was 610 → 58 after `--fix` (a `.markdownlintrc` had landed since
  the estimate), and the stale count drove initial mis-planning until
  re-measured. Add guidance: state the task, not a snapshot metric; re-measure
  at execution time. Scope: **global** `rules/todo.md`. Pointer: harleydev
  `TODO.md` QA Tooling Setup (pre-PR state).

### 🔎 Prefer a tool's native in-file ignore over a pre-commit `exclude` (MEDIUM PRIORITY)

When a file — or a construct in it — trips a linter, **check the tool's own
docs for a scoped, in-file ignore before reaching for a pre-commit
`exclude:`** (or otherwise bypassing the whole file). Most linters make this
first-class: shellcheck `# shellcheck disable=SCxxxx  # reason`, markdownlint
`<!-- markdownlint-disable[-line|-next-line] MDxxx -->` (plus a
`capture`/`restore` pair to exempt a block), hadolint
`# hadolint ignore=DLxxxx`, yamllint `# yamllint disable-line rule:xxx` — and
others (each tool's exact directive lives in its docs / `rules/<tool>.md`, to
be grounded when worked). A native ignore is narrower (one rule, one
line/block — not the whole file), self-documenting (a reason at the point of
violation), and keeps the rest of the file linted; a pre-commit `exclude`
silently drops the file from that hook entirely. shellcheck makes the in-file
form obvious, but the markdownlint case (block `disable`/`enable`, and
`capture`/`restore`, around the terraform-docs markers) was not
top-of-mind and had to be looked up — which is why the step needs emphasizing.

- [ ] **`pre-commit.md`: add the exclude-vs-native-ignore decision.** State
  the hierarchy: (1) fix the finding; (2) if the construct is intentional,
  use the tool's native in-file ignore with a reason at the site; (3) reserve
  a pre-commit `exclude:` for whole files that genuinely should not be linted
  (generated / vendored / binary / templated), documented. Emphasize: **read
  the tool's docs for a native ignore before excluding** (per the grounding
  convention — do not assume from memory). Cross-reference `code-style.md`
  *Marker comments* (the inline-disable philosophy); each tool's mechanism
  lives in its `rules/<tool>.md`. Scope: **global**. Pointer: the markdownlint
  block-ignore investigation (harleydev QA session).

### 🧹 Two rule refinements from the shell-startup-guard PR (#154) (LOW PRIORITY)

Surfaced while shipping PR #154; small doc-rule additions, not edits yet.

- [ ] **`pre-commit.md`: note that `--all-files` skips *untracked* files.**
  `pre-commit run --all-files` runs only over git-tracked files, so newly
  authored (not-yet-`git add`ed) files pass a green `--all-files` run yet still
  get caught by the commit hooks (which run on the staged set). In #154 this
  meant SC2016/yapf findings on new files surfaced only at commit time. Add a
  one-liner: to lint brand-new files before committing, stage them or pass
  `pre-commit run --files <paths>`.
- [ ] **`python.md`: non-cryptographic `hashlib` hashes pass
  `usedforsecurity=False`.** GitHub's default code scanning (Bandit) flags
  `hashlib.md5`/`sha1` as **B324** "weak hash for security". When the hash is
  for integrity/drift detection (not security), pass `usedforsecurity=False`
  (Python 3.9+) — it both documents intent and clears B324. #154 hit this on
  the `md5-guard.py` hook and its test. (Note this is GitHub *default* code
  scanning, separate from the repo's in-house SAST posture in `semgrep.md`.)

### 🧪 `bats.md`: recipe for testing non-sourceable shell (LOW PRIORITY)

Surfaced shipping PR #173 (dotfiles `source_funcs` helper). The
extract-and-eval pattern — awk a named function block out of a file that
isn't sourceable on its own (a shell-startup orchestrator, an
interactive-guarded lib), then `eval` it in isolation — now recurs across
four dotfiles test files and has been factored into a `source_funcs <file>
<fn>...` helper in `tests/helpers/common.bash`. That helper is dotfiles-local,
but the *technique* is repo-agnostic bats knowledge.

- [ ] **`bats.md`: add a short "testing non-independently-sourceable shell"
  recipe.** Document the extract-and-eval approach (awk/`sed` the function
  block, `eval` it under test), the two gotchas a future implementer hits —
  bats aborts a test on any non-zero intermediate command, so completion /
  early-out returns need `|| true` when asserting state; and a function that
  is a guard-strip or needs a non-function var stays bespoke (outside a
  by-name helper's scope) — and point at the dotfiles `source_funcs` helper as
  a reference implementation. Scope: **global** `rules/bats.md`. Ground any
  added claim in the bats docs per the grounding convention.

### 🪝 branch-protection hook: exempt gitignored paths (LOW PRIORITY)

*(Moved from the dotfiles `TODO.md` 2026-06-26 during a TODO reorg — it is
purely a `config/claude/hooks/` change with no dotfiles coupling, so it belongs
in this agent-config queue per the routing convention.)*

**Pain (PR #118 retrospective):** writing an auto-memory note — under the
gitignored `config/claude/projects/*/memory/` dir, a path that can *never*
land in a commit — was blocked by the edit-time `branch-protection.py`
`PreToolUse` hook because `master` was checked out, forcing an unnecessary
throwaway branch just to satisfy the guard. A write that cannot be committed
cannot violate branch protection, so this is a false-positive in a
forcing-function hook (the memory system is meant to be written directly at
any time).

- [ ] **Artifact:** update the existing hook
  `config/claude/hooks/branch-protection.py` (global; symlinked to
  `~/.claude/hooks/`) to **allow** an `Edit`/`Write`/`MultiEdit` whose target
  path is gitignored (e.g. `git check-ignore -q <path>`), since such a write
  can't reach a commit on the protected branch. Keep failing safe (any error →
  allow). Scope: **global** dotfiles agent-config. Confirm it doesn't weaken
  the guard for tracked files.

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

### 🌐 Per-repo SaaS-scanner evaluation (escape hatch, 2026-06-19)

Spawned by the new `security-scan` §4 escape hatch (OSS-pinned default + a
per-repo exception when a hosted scanner's results are worthwhile). **Migrate
each to that repo's own `TODO.md` when next working it** — captured here so the
policy isn't created without a path to apply it.

- [ ] **pigify (FastAPI/Python):** assess **Snyk SCA** against the bar — a
  real Python dependency tree means curated vuln intel / reachability /
  fix-PRs may be worthwhile beyond osv-scanner + Dependabot. CodeFactor
  secondary (grade / badge). If adopted: record in pigify's `.claude/` QA doc,
  non-required first.
- [ ] **scripturestudy-app (Ruby/Gollum):** same assessment for the Ruby
  (bundler) dependency tree — Snyk supports Ruby; weigh worthwhile results vs.
  the OSS lane (osv-scanner covers `Gemfile.lock`).

### 🏅 Research credibility signals / badges worth adopting across public repos

A public badge (CI status, coverage, code-quality grade, security) is **social
proof** — it can nudge a visitor to take a repo more seriously. Research which
external signals/badges are worth adopting across my public repos, weighing
the per-repo cost (SaaS surface, version drift, the §4 bar) against the
credibility payoff. Feed results back into the `security-scan` §4 escape hatch
and per-repo QA docs.

- [ ] Enumerate candidate signals/badges (CI status, Codecov/coverage,
  CodeFactor / Code Climate grade, Snyk / known-vulns, OpenSSF Scorecard,
  license, release/version, …) and what each signals to a visitor.
- [ ] Decide which earn their surface per repo type (app vs library vs
  dotfiles) and which are pure vanity. Record the shortlist + rationale.

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

- [ ] **Conformance sweep for the language/tool layering** (follow-up to the
  codification above). Bring existing artifacts into line with `EXTENDING.md`
  *The language & tool stacks*: each language rule (`typescript.md`,
  `powershell.md`, `html.md`, `css.md`, `react.md`, `bats.md`, …) should
  **reference up** to `code-style.md` / `EXTENDING.md` (several don't yet —
  `perl.md` now does, done 2026-06-20); and audit **language-agnostic tool**
  rules for any link to a language
  *file* (replace with a by-name "applies to <lang>" applicability).
  **Keep the framework distinction:** a single-language framework/library —
  `fastapi.md`, `sqlalchemy.md`, `react.md`, and their `*-patterns` skills —
  is language-axis and **may** reference its language rule; do **not** strip
  those. Mechanical but multi-file; the `claude-audit` framework check now
  flags real violations only.

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

## Mining queue

Mine one repo at a time; **don't decide until all are mined** (expect
duplicates / similar setups). Chart each in
[`mining-census.md`](mining-census.md) and promote useful sources to
[`idea-sources.md`](idea-sources.md).

- [ ] **Claude Code official documentation** (first-party source — ranks
  *highest* in the source-discovery method). Much is how-to-use-Claude that
  won't fit our config, but the **config surface is mineable**: hooks (events,
  matchers, exit codes), `settings.json` (permissions, env, statusline,
  model), slash commands, the skills/plugins spec, MCP config, statusline JSON
  fields, output styles, memory/`CLAUDE.md` semantics. Mine the
  config-relevant sections; SKIP the interactive how-to. Captured 2026-06-20
  at the user's request (the "steel sieve" — point here if it resurfaces).
  <https://docs.claude.com/en/docs/claude-code>

## Claude statusline enhancements (claude-hud candidates)

Done 2026-06-19 (fixed + regression-tested; see the decisions log): the
display bug (leading empty field + a field-shift from the empty `.vim.mode`
column — root-caused to the whitespace-`IFS`/`@tsv` parse, now joined on the
unit separator so absent fields are safe), the context-% prominence, the
**reasoning-effort `[level]`** indicator (`.effort.level`), the **rate-limit
usage segment** (`5h:`/`7d:` `used_percentage` riding inside the context
segment, colored by the shared pct ramp; hidden for non-subscribers), and the
**vim-mode segment** (`.vim.mode` rendered ourselves with
`hideVimModeIndicator: true` — NORMAL is bright-yellow-on-red, INSERT/others
standard; leads the line). `jarrodwatts/claude-hud` was mined — full matrix in
[`mining/claude-hud.md`](mining/claude-hud.md). Remaining candidates:

- [ ] **Investigate `statusLine.subagentStatusLine`** (surfaced 2026-06-19
  while confirming the PR-badge can't be hidden). It's a `statusLine`
  sub-field that *formats* subagent rows. **Decide if it's worth using by
  answering one thing: does it OVERRIDE the native subagent line or ADD to
  it?** If it **overrides** (replaces the native row format), great — it's the
  one native below-prompt element we *can* take control of, so we could
  restyle the subagent display our way. If it only **adds** a custom row
  alongside the native one, it would **duplicate** output — not what we want,
  so skip. Ground the answer in the docs + a quick trial (fire a background
  subagent and watch the row) before wiring anything.
- [ ] **Keybinding cheat-sheet statusline line** (research → build). The user
  wants a second statusline line *below* the current one that displays the
  prompt-input shortcuts worth memorizing. Two parts:
  1. **Research the keys.** This setup runs `editorMode: vim`
     (`settings.json`), so the prompt has both modes. Enumerate, grounded in
     the **Claude Code docs** (via the `claude-code-guide` agent — demand
     exact doc references per the *delegated-research over-claim* guard above,
     don't trust memory): the useful **INSERT-mode `Ctrl`/`Alt` bindings**
     (e.g. reverse-search, word-delete/word-move, line edits, history) and
     the supported **NORMAL-mode (vim) keys/motions**. Note which are real
     Claude Code bindings vs. terminal/readline defaults that merely pass
     through. **Secondary cross-check source** (mined 2026-06-20):
     `claude-code-tips` Tip 36 lists `Ctrl+A/E` (line start/end),
     `Alt+←/→` (word nav), `Ctrl+W/U/K` (word/line deletes), `Ctrl+G`
     (open `$EDITOR`), `` ` ``+Enter (newline), paste-image — Mac-leaning and
     **not authoritative**, so verify each against the official docs per the
     over-claim guard above; useful as a starter checklist only.
  2. **Pick + display.** Select the subset worth memorizing and render them as
     a compact reference on a new line beneath the current statusline. Verify
     the statusline `command` can emit multiple lines (newline in stdout) and
     that the cheat-sheet can be mode-aware (it already reads `.vim.mode` —
     the line could show NORMAL keys vs INSERT keys per the active mode).
     Target: `config/claude/bin/statusline.sh`. Keep it terse — a cheat-sheet,
     not a manual; weigh the vertical space it costs against its value.

## New rule/skill candidates

These three are **trigger-gated** — build-on-first-use when you next work a
`gollum` / non-code "writing" repo. They are activated by the
[`mining-census.md`](mining-census.md) Watch-list trigger *"A `gollum` wiki
repo … or any non-code writing/prose repo"*, which also calls for a dedicated
**writing rule** grounded in the related mined resources (`claude-code-tips`
Tips 16/25/17/26).

- [ ] **Gollum Wiki** rule (wiki engine).
- [ ] **Ruby** rule — especially as it relates to the Gollum wiki.
- [ ] **Essay Helper** skill — for the scripturestudy.org wiki ("LDS
  Scholar").

- [ ] **Workflow-authoring skill (`author-workflow` or similar)**
  (retrospective, harleydev session 2026-07-06 — user asked whether a global
  workflow rule/skill would help). The **decision layer** already exists —
  `config/claude/docs/LOOPS-WORKFLOWS.md` covers loop-vs-workflow, good-fit
  criteria, "prove iteration one by hand," the serial-spine caveat — and the
  Workflow **tool description** is a full, always-in-context API reference
  (pipeline/parallel/schemas/phases/quality-patterns). What is **missing is
  the authoring *procedure* + this-setup conventions**: what actually gets
  applied each time a workflow is authored (several times that session —
  provider comparison, endpoint diff, the resource/data-source spec audit),
  living nowhere persistent. Decided form: a **skill** (a procedure with
  decisions that *fires* when the user opts in, not a passive rule/doc). Keep
  it **thin — link `LOOPS-WORKFLOWS.md` for concepts, do not restate the tool
  description**; its whole value is the delta below.
  - **Opt-in gate as step 0.** Author a workflow only on an explicit "use a
    workflow" / ultracode / named-workflow / skill-directed invocation;
    otherwise use plain subagents or ask. (In the tool description already;
    the skill makes it the first procedure step.)
  - **Authoring gotchas that actually bite** (none in `LOOPS-WORKFLOWS.md`):
    (1) **subagents run from the *session* cwd, not the target repo → pass
    absolute paths** in every prompt (a cross-repo session — cwd harleydev,
    target terraform-provider-mxroute — silently reads the wrong tree with
    relative paths); (2) `Date.now()` / `Math.random()` / argless `new Date()`
    throw — stamp times after the run, vary by index; (3) **save the script
    to the session scratchpad**, iterate via `scriptPath`, resume via
    `resumeFromRunId`; (4) **workflows return data; do file mutations
    (TODO.md, docs) in the main thread** — parallel agents can't co-write one
    file; (5) **structured returns via `schema`** (validated at the tool
    layer) beat parsing free text; (6) **pipeline() by default**, a barrier
    only on a genuine cross-item dependency.
  - **Forcing steps:** assess fit (the `LOOPS-WORKFLOWS.md` bar) → **prove
    iteration one by hand** → pilot on 2–3 → scale → **adversarially verify
    each finding** (the guard that would have caught this session's
    hallucinated "stale spec / 32-71-ops" claim; default-reject unless spec
    and code prove it).
  - **Home/build:** a global skill under `config/claude/skills/`, authored
    with **skill-creator** (`EXTENDING.md`). On build, **update
    `STRUCTURE.md`** and cross-link from `LOOPS-WORKFLOWS.md` (*Workflows*)
    and, where relevant, `terraform-provider-patterns` (its fan-out section
    is a worked example). Distinct from the **understandable-docs** series
    above (those are conceptual reference; this is a runnable procedure).
    Generic (global).

- [ ] **`terraform-provider-patterns`: add tfplugindocs *guides* coverage
  (LOW — retrospective, terraform-provider-mxroute PR #43).** The skill's
  *Docs — tfplugindocs* section covers resources / data-sources / import
  examples but is **silent on guides**: authoring
  `templates/guides/*.md.tmpl`, the guide frontmatter (`page_title`
  **required** — it sets the nav label; `subcategory` optional), rendering to
  `docs/guides/*.md` via `tfplugindocs generate`, and nav ordering (guides
  without a subcategory sort before those with one; guides render above
  resources/data-sources/functions). Authoring
  two provider guides in that PR needed a WebFetch of the HashiCorp Registry
  *provider docs* page to confirm the frontmatter, because neither the skill
  nor context7 covered it. Add a short *guides* note to the skill's
  tfplugindocs section (the Registry "docs" URL is already in its *Sources*),
  so the next guide author skips the lookup. Generic (global).
