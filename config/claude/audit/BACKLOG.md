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

- [ ] **Repo-orientation documentation skill (explain & index a complex repo
  for evaluators, learners, and refreshers).** A skill/rule/agent for
  **orientation** docs — *not* the code/task/README docs (those are fine as
  they are) — that explain *what a complex repo is about*: the main dotfiles
  repo and, **separately**, the `config/claude/` config. Multi-file (as many
  as make sense), with a layered shape:
  - **Elevator pitch**
  - **Bird's-eye view**
  - **General overview / ELI5**
  - then **structure-dependent** detail per the repo's own layout;
  - plus a cross-cutting **quick-lookup / reverse index** — recover a feature
    by *what it does* when you know it exists but can't recall what you named
    it.

  The author "thinks differently and has a hard time explaining himself," so
  the skill is deliberately **question-driven** — ask lots of clarifying
  questions to draw the mental model out. **Start by documenting
  `config/claude/` while building the skill** (dogfood it into existence).
  Reuses the layered shape of the **understandable-docs** series
  (`config/claude/docs/TOPIC.md.template`) — cross-reference, don't duplicate;
  the difference is *audience* — this serves **three**: an outside
  **evaluator** (what is this?), a **learner** (understand it), and a
  **refresher / quick-lookup** for someone already experienced with the repo
  (the reverse index by intent above, for infrequently-used parts you know
  exist but can't name). Generic (global).
- [ ] **Should top-level orchestrator skills be agents?** Skills that are
  *mainly composed of other skills* — `qa-check`, `resolve-task`,
  `github-tasks`, `push-pr` — may fit better as **sub-agents** (own context,
  delegation) than as skills. Evaluate the skill-vs-agent line for these
  orchestrators against `EXTENDING.md` *Choosing between them* / *Agent*.
  (Raised alongside the repo-orientation-doc idea above.)
- [ ] **Hook: hard-enforce `resolve-task` autonomous scoping** (retrospective,
  PR #255). The autonomous variant's trivial-only / do-now / reproduced gate
  is currently **judgment** (the skill's task-type classifier) backed by
  push-pr's merge guardrails. Consider a `PreToolUse` hook that
  deterministically blocks
  an *autonomous* merge when the task isn't trivial/small or CI isn't green —
  the forcing-function backstop to the skill's soft gate (cf.
  `merge-finalization.py`). Weigh the value against the existing guardrails
  before building. Scope: global (`config/claude/hooks/`).
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
  - [ ] **Sub-agents — the auto-routing rule/skill.** The *doc* half landed
    2026-07-09: `SUBAGENTS.md` covers using them (delegate-vs-inline,
    when-not-to) and defining them (custom types, tool restrictions), and
    `MODELS-AND-EFFORT.md` covers the `effort` knob and the model×effort
    selection heuristic. What remains is the **rule and/or skill** the
    original 2026-06-27 research item called for: estimating a task's effort
    from its description and **auto-assigning** the right sub-agent (model
    tier + effort + agent type), and — the harder half — whether a sub-agent
    can **recognize a mis-guess and kick the task back** ("bigger/smaller
    than scoped; re-route") instead of grinding at the wrong level. Generic.
  - [ ] **Channels** (research preview). External systems pushing events
    into a running session — the push counterpart to poll/timer loops.
  - [ ] **Agent teams** (experimental). Peer-coordinating multi-agent work;
    the deep-dive the loops doc only summarizes.
  Two further threads under this umbrella — link/idea triage that feeds the
  docs above (the saved-link triage itself is done — see the changelog and
  `decisions-log.md`; these are the deferred spin-offs):
  - [ ] **Context-engineering thread (R. Lance Martin, X).** The saved link
    <https://x.com/RLanceMartin/status/2027450018513490419> can't be fetched
    (X paywalls unauthenticated reads), so its content is unverified. Paste
    the thread text, then decide: a resource link in
    `AGENT-NATIVE-ENGINEERING.md`, or seed a standalone `CONTEXT-ENGINEERING.md`
    (the write / select / compress / isolate taxonomy maps onto this config's
    memory files, path-scoped rules, and subagent result-relay). Generic.
  - [ ] **Evaluate claude-science as a template for other knowledge
    domains.** Can its structure be reused to build the same kind of layered
    knowledge/research artifact for other subjects — religious studies,
    researching aspects of a task, etc.? Assess and decide whether it yields
    a doc, a skill, or nothing. Link:
    <https://claude.com/product/claude-science>
  Generic (global; docs under `config/claude/docs/`).

## Non-Claude infra reference links (parked from the link triage, 2026-07-09)

Surfaced by the *Learning about Claude* link triage but **not** Claude-agent
config — infrastructure tooling references with no home in this repo's docs.
Parked here (cross-repo) rather than dropped; route each to the relevant
infra/IaC repo when one exists, per the TODO-routing convention.

- [ ] **Linode image-build / host-provisioning tooling** (group). Three
  saved refs for a future Linode infra / image-build repo — not for the
  global `terraform.md` / `packer.md` (single-provider utilities, not generic
  guidance). Route there when such a repo exists, else drop:
  - <https://github.com/linode/terraform-provider-sshhostkeycache> — caches an
    SSH host key across `plan`/`apply` to avoid repeated `ssh-keyscan`.
  - <https://github.com/linode/packer-plugin-linode> — official Packer plugin
    to build custom Linode images.
  - <https://developer.hashicorp.com/packer/integrations/linode/linode/latest/components/builder/linode>
    — the authoritative builder-component reference for that plugin.
- [ ] **`terraform-provider-github` — GitHub-resources-as-IaC.** Manages
  repos, teams, branch protections, **rulesets**, Actions secrets, etc. as
  Terraform. Secondary relevance to *this* repo: it is the IaC alternative to
  the manual `gh api` + `protect-master-solo.json` master-ruleset management
  (see `WORKFLOW.md`) — a design tradeoff, not a rule fact, so revisit only if
  ruleset management outgrows the manual approach, or route to a future IaC
  repo. Link: <https://github.com/integrations/terraform-provider-github>.

## Repo-config follow-ups (migrated from TODO.md, 2026-06-19)

These were tracked in the dotfiles `TODO.md` but are Claude-agent-config
work (rules, skills, plugins, agent-config docs) — moved here per the TODO
routing convention (see the header). Provenance preserved verbatim.

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

- [ ] **Relative-link integrity lint for the docs series** (retrospective,
  PR #258). markdownlint (MD053) checks that reference labels are
  defined-and-used, but nothing checks that a **relative** link target —
  `[x](STEERING.md)`, `[y](../rules/qa.md)` — actually resolves on disk, so a
  see-also pointing at a not-yet-written sibling doc passes lint yet 404s. The
  `config/claude/docs/` series cross-references heavily (PR #258 added six
  interlinked docs and needed a hand-rolled existence check), so a broken
  relative link is easy to ship. Add a small pre-commit check (its own hook,
  or an extension of the `agent-config markdown hygiene` hook) that resolves
  every relative markdown link and link-definition target and fails on a miss.
  Global (config/claude).

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

- [ ] **Ruleset storage + propagation convention** (from the `dotagents`
  extraction, 2026-07-16). `private_dotfiles/github-rulesets/` holds reusable
  ruleset **templates** a consuming repo copies and modifies; a repo's
  **applied** ruleset JSON must not pollute that template space. Decide and
  codify a canonical home for a repo's own applied ruleset — candidate
  `.github/rulesets/<name>.json` (GitHub allows inert, non-actionable files in
  `.github/`; it only special-cases known paths, and rulesets-as-code is not a
  native GitHub feature, so the JSON is just a source of truth applied via the
  API), alternative `docs/`. Record it in **`rules/github-rulesets.md`** (with
  a pointer from `gh.md`, and in the `push-pr` / `github-tasks` skills that
  create/apply rulesets): templates -> `private_dotfiles/github-rulesets/`,
  applied per-repo ruleset -> the repo's own `.github/rulesets/`. Then
  relocate dotfiles' own `protect-master-solo.json` out of the template space
  and update the re-apply command in `WORKFLOW.md`. `dotagents` already stores
  its applied ruleset at `.github/rulesets/protect-master.json` (the first
  instance). Global (config/claude). See memory `ruleset-storage-location`.
  - [ ] **Reconstruct a ruleset from an existing GitHub ruleset (propagation
    subtask).** Check whether `gh api repos/{owner}/{repo}/rulesets/{id}`
    output round-trips — strip the read-only fields (`id`, `created_at`,
    `updated_at`, `_links`, `node_id`, `source`, `source_type`) and re-`POST`
    it to another repo — so an applied ruleset can be **cloned to other
    repos** from a known-good one instead of hand-maintaining template JSON.
    If it round-trips cleanly, fold a "clone ruleset from <repo>" step into
    `github-rulesets.md` / the `github-tasks` skill.
