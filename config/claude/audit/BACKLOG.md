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

## Audit dimensions / design

- [ ] **Prose-wrap check for agent-config Markdown (LOW — retrospective, PR
  #130).** The 78-col prose-wrap convention (`CONVENTIONS.md`) is enforced
  only by eye — markdownlint's `line_length` is set to 200 (tables/code),
  so 79–80-col prose slips through; this session hand-fixed several such lines
  (em-dashes also fool `awk length`, so the check must count *characters*).
  Consider a small pre-commit/meta check that flags >78-col **prose** lines in
  `config/claude/**` and `.claude/**` Markdown while exempting table rows,
  fenced code, frontmatter `description:`, and reference-link/URL lines.
  **Risk:** false positives on exactly those exemptions — evaluate whether a
  reliable check is even feasible before building; it may not be worth it.

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
- [ ] **Future top-level categories.** Fold a new capability into an existing
  category (`code-style` / `testing` / `qa` / `gh` / `git`); open a new
  top-level category only when it genuinely doesn't fit. (`documentation` and
  `troubleshooting` were opened 2026-06-11 — see the decisions log.)

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

### 🔎 CodeFactor & Snyk — evaluated & resolved (2026-06-19)

Evaluation done and the policy landed (the `security-scan` §4 escape hatch;
decision recorded in `.claude/QA.md`; see decisions-log 2026-06-19). One manual
action remains:

- [ ] **User action (web UI, not scriptable here):** uninstall the **Snyk**
  GitHub App from `harleypig/dotfiles` and remove the repo's projects from
  app.snyk.io, so the advisory `security/snyk` check stops posting.

### 🌐 Per-repo SaaS-scanner evaluation (escape hatch, 2026-06-19)

Spawned by the new `security-scan` §4 escape hatch (OSS-pinned default + a
per-repo exception when a hosted scanner's results are worthwhile). **Migrate
each to that repo's own `TODO.md` when next working it** — captured here so the
policy isn't created without a path to apply it.

- [ ] **pigify (FastAPI/Python):** assess **Snyk SCA** against the bar — a real
  Python dependency tree means curated vuln intel / reachability / fix-PRs may
  be worthwhile beyond osv-scanner + Dependabot. CodeFactor secondary (grade /
  badge). If adopted: record in pigify's `.claude/` QA doc, non-required first.
- [ ] **scripturestudy-app (Ruby/Gollum):** same assessment for the Ruby
  (bundler) dependency tree — Snyk supports Ruby; weigh worthwhile results vs.
  the OSS lane (osv-scanner covers `Gemfile.lock`).

### 🏅 Research credibility signals / badges worth adopting across public repos

A public badge (CI status, coverage, code-quality grade, security) is **social
proof** — it can nudge a visitor to take a repo more seriously. Research which
external signals/badges are worth adopting across my public repos, weighing the
per-repo cost (SaaS surface, version drift, the §4 bar) against the credibility
payoff. Feed results back into the `security-scan` §4 escape hatch and per-repo
QA docs.

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
  `perl.md`, `powershell.md`, `html.md`, `css.md`, `react.md`, `bats.md`, …)
  should **reference up** to `code-style.md` / `EXTENDING.md` (several don't
  yet); and audit **language-agnostic tool** rules for any link to a language
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

- [x] **Anthropic official plugins — text re-mine of `code-simplifier` +
  `commit-commands`. DONE (2026-06-20).** Read both from the local marketplace
  cache. **One fold:** `code-simplifier`'s "avoid nested ternaries / dense
  one-liners; clarity over brevity" — added to `code-style.md` *Prefer elif*
  (v1.7.0). **Everything else SKIP** — its stack-specifics (ES modules, React,
  arrow fns) violate our generic-layer-names-no-language rule; its
  auto-refine-on-every-edit mode contradicts our scope discipline (don't
  improve adjacent code). `commit-commands` (`commit`, `commit-push-pr`,
  `clean_gone`) all SKIP: `git.md` *Commit Messages* + `ship-pr` +
  `git-worktree-workflow` Op 7 are richer and safer (ours confirms each /
  skips dirty vs. the plugin's force-delete). Verdict recorded in
  decisions-log.
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
     through.
  2. **Pick + display.** Select the subset worth memorizing and render them as
     a compact reference on a new line beneath the current statusline. Verify
     the statusline `command` can emit multiple lines (newline in stdout) and
     that the cheat-sheet can be mode-aware (it already reads `.vim.mode` —
     the line could show NORMAL keys vs INSERT keys per the active mode).
     Target: `config/claude/bin/statusline.sh`. Keep it terse — a cheat-sheet,
     not a manual; weigh the vertical space it costs against its value.

### New rule/skill candidates

- [ ] **Gollum Wiki** rule (wiki engine).
- [ ] **Ruby** rule — especially as it relates to the Gollum wiki.
- [ ] **Essay Helper** skill — for the scripturestudy.org wiki ("LDS Scholar").
