# Audit decisions log

Chronological record of Claude Code setup-audit decisions (newest first) — the
durable "why" behind each change. Append-only: a superseded decision is
annotated, not rewritten. Audit-only (not context-loaded); written by the
**claude-audit** skill. Sibling records: [`BACKLOG.md`](BACKLOG.md) (open
items) and [`idea-sources.md`](idea-sources.md) (mined repos).

- 2026-06-19 — **Added the reasoning-effort indicator; root-caused the parse;
  corrected the `.vim.mode` story.** Verified against the official statusline
  docs (claude-code-guide) that **`.effort.level`** (low/medium/high/xhigh/max,
  absent when the model lacks effort) is a real field — added it to
  `statusline.sh`, rendered `[level]` only when present. While there, fixed the
  **root cause** of the earlier field-shift rather than just its symptom: the
  `@tsv` + whitespace-`IFS` `read` collapsed empty/leading fields; switched to
  `join("")` + `IFS=$'\x1f'` (non-whitespace), so an absent field stays in
  place — effort and future fields are now safe in any position. Two
  **corrections** the verification surfaced: (a) **`.vim.mode` IS documented**
  (NORMAL/INSERT, present when CC vim mode is on; the user uses it) — the prior
  commit's "not in the JSON" was wrong; the field was still broken as written
  (emitted only the empty label) and caused the shift, so its removal was
  functionally right but the *reason* was not. Restoring it correctly is now a
  user-decision BACKLOG item. (b) **`rate_limits` IS present** (5h + 7-day
  `used_percentage`, subscriber-only) — the rate-limit segment's gate is
  satisfied; left as the top remaining candidate. Marked git ahead/behind
  **SKIP** (already in `git-status`, user doesn't surface it). Extended
  `test_statusline.bats` to 8 tests (effort present/absent). Folded into the
  statusline PR.
- 2026-06-19 — **Worked a backlog item: fixed the Claude statusline + mined
  `claude-hud`.** First use of the *Working the backlog* step. (1) **Fixed
  `config/claude/bin/statusline.sh`:** the reported "leading empty field" was
  the surface of a deeper bug — the dead `mode` field (`.vim.mode`, absent from
  Claude Code's statusline JSON) emitted an empty leading `@tsv` column, and
  `read` with a whitespace `IFS` collapsed the leading tab and **shifted every
  field by one** (model→mode, ctx→model, …). Removed the `mode` field
  (eliminates both the stray `|` and the shift), added empty-part filtering for
  robustness, and made context % escalate harder (cyan → bright-yellow ≥60% →
  white-on-red alarm ≥80%, since compaction is manual). Added
  `tests/shell/test_statusline.bats` (6 tests) — the regression test **caught
  the field-shift** the cosmetic fix alone would have missed. (2) **Mined
  `jarrodwatts/claude-hud`** (MIT, active, ~25k★) for statusline ideas via a
  read-only agent: it's a transcript-enriching TS plugin (wrong form to vendor).
  Recorded the full disposition in `mining/claude-hud.md` and a row in
  `idea-sources.md`; the top ideas (rate-limit/usage segment, git ahead/behind,
  effort indicator) are all **gated** on JSON-field verification or the shared
  `git-status`, so captured as `BACKLOG` candidates rather than added
  speculatively. Pruned the done statusline item from `BACKLOG`. Landed via
  dotfiles PR.
- 2026-06-19 — **Routed a scratch `tmptodo.txt` into `BACKLOG.md` (first live
  test of the routing convention).** Every item proved to be Claude-agent-config
  work — nothing for the dotfiles `TODO.md` — so the whole file routed to
  `BACKLOG.md` under a "tmptodo intake" section: a mining queue (11 collection
  repos + `claude-code-tips` + `ruflo`), an agentskills.io standard check, an
  urgent Claude-statusline display fix, and new rule/skill candidates (Gollum
  wiki, Ruby, an essay-helper skill). For the 5 Anthropic official plugins the
  user asked to *re-mine for text*: checked the decisions log — `pr-review-
  toolkit` / `feature-dev` / `security-guidance` were already content-reviewed
  (their bits are the vendor-when-needed items), so only `code-simplifier` +
  `commit-commands` (dropped at capability level, no text review, and both with
  our own equivalents) were queued for a text re-mine. Also **moved the
  `Research: Claude Code compaction control` item from `TODO.md`** here (it's
  config/claude, and its context-% theme overlaps the statusline fix); left the
  coordination *Statusline Coordination / Task 1* in `TODO.md` (coupled) with a
  cross-ref. Deleted the consumed `tmptodo.txt`. Landed via dotfiles PR.
- 2026-06-19 — **Established TODO routing; migrated Claude-config items from the
  repo `TODO.md`; made `claude-audit` work the backlog.** Defined the
  convention — a follow-up about the Claude agent config (`config/claude/`)
  goes in this `BACKLOG.md`; a dotfiles task in the repo `TODO.md`; a mixed task
  is split with a cross-ref unless its parts are merely coupled — and homed it
  in `WORKFLOW.md` → *TODO routing* (repo-scoped, so it costs no global
  always-on tokens) with reciprocal header pointers in both files. Reviewed the
  ~37-section `TODO.md` and **moved 8 Claude-config sections** here (STRUCTURE.md
  diagram, kept-branch sync mechanic, `.claude/`-promotion audit, skill-creator
  retrospective dogfood, skill-creator upgrade, Claude Rules Files, CodeFactor/
  Snyk rule-or-skill, OpenWebUI offload) under "Repo-config follow-ups". Left
  coupled items in `TODO.md` with scope notes (Extract-`config/claude` =
  packaging; Perl agent-config subsection; Claude statusline = 1 of 4 surfaces;
  the pre-commit-skill + markdownlint-rule sub-items). Chose to **extend
  `claude-audit`** with a "Working the backlog" step (pick → kind/scope →
  implement → ship-pr → prune+record) rather than spawn a `claude-backlog`
  skill — reuses the audit's context and PR machinery; revisit a dedicated
  skill only if the activity proves frequent/distinct (Rule of Three). Folded
  into the same PR as the `SETUP-AUDIT.md` restructure. Landed via dotfiles PR.
- 2026-06-19 — **Restructured `SETUP-AUDIT.md` into an index + split record
  (user-requested revamp).** The file had accreted into a 575-line mix of stale
  point-in-time snapshots, methodology duplicated from the `claude-audit` skill,
  and the living record. Verified the live config is healthy first (41 rules
  `paths:`-scoped, 9 always-on; 1 plugin enabled; context7 via `mymcp`; 4 hooks
  — no drops needed). Then: **methodology → the skill** (it is canonical;
  removed "How to run", left a pointer — skills own procedures, ADR-0001);
  **dropped** the stale Baseline / resolved Findings A–F / Global-changes
  (already in this log); and **split the three record sections into sibling
  files** under `audit/` — `decisions-log.md`, `BACKLOG.md` (named to avoid
  confusion with the repo `TODO.md`; treated as a todo file), `idea-sources.md`
  (joining `mining-census.md`). `SETUP-AUDIT.md` is now a 43-line index
  (status + methodology pointer + current baseline + record links). Updated all
  referrers (the skill, `EXTENDING.md`, `mining-census.md`, repo `TODO.md`).
  New finding logged in `BACKLOG.md`: review `claude-code-auth.md` /
  `trufflehog.md` (the 2 niche always-on rules) for path-scoping. Landed via
  dotfiles PR.
- 2026-06-18 — **Dogfooded `skill-creator` on `ship-pr`; its trigger eval is
  broken on CC 2.1.181 (updates the "keep + put to work" entry below).** Ran
  `run_eval.py` against ship-pr's `description` with a 20-query should/
  should-not set. **Uniform 0% trigger rate in BOTH configs** — installed skill
  present, *and* (per upstream issue #2003's Option-2 workaround) with the
  installed skill moved aside so only the temp registration remained. Two root
  causes: (1) **issue #2003** (anthropics/claude-plugins-official) — `run_eval`
  registers a UUID-named temp copy and checks for that UUID name, but a
  co-installed real skill is invoked instead (its name lacks the UUID) → 0%;
  (2) **deeper, isolated by our hidden rerun** — `run_eval` writes a **command**
  to `.claude/commands/` but detects a **`Skill`** tool-use, and on CC 2.1.181
  that command is never invoked as a `Skill`, so it reads 0% *even with no
  competing skill*. So #2003's hide-workaround does **not** fix it for us —
  there is currently **no usable triggering eval here**, and the
  `improve_description`/`run_loop` loop is moot (it depends on `run_eval`).
  `run_eval.py` is **byte-identical to upstream `main`** (diffed) — unfixed
  upstream; #2003 is OPEN. We commented our repro on #2003. **Verdict (revises
  the entry below):** keep skill-creator's `SKILL.md` as *conceptual* guidance
  — and note its **instruction-review pass produced two real `ship-pr` fixes**
  (the genuine value this round) — but treat its **automated eval/optimize
  machinery as non-functional on CC 2.1.x**; use **manual triggering judgment**
  until upstream fixes #2003. **Plugin upgrade deferred** (would only modernize
  the moot improve-loop): blocked by a **marketplace path-corruption** — the
  `~/.claude` → `config/claude` symlink makes CC 2.1.181 reject the recorded
  marketplace `installLocation` (not the real dotfiles path); the sanctioned
  fix is a global marketplace remove + re-add. Both tracked in `TODO.md`.
  Landed via dotfiles PR.
- 2026-06-18 — **Kept `skill-creator` (the one plugin worth keeping) and put
  it to work.** Unlike the four dropped plugins, skill-creator is **not
  redundant** — it is a skill-authoring + **evaluation** harness (analyzer /
  comparator / grader agents; `run_eval` / `aggregate_benchmark` /
  `improve_description` / `package_skill` / `quick_validate` scripts; an
  eval-viewer) whose quantitative skill evals and **description-trigger
  optimization** are a capability we otherwise lack. It is Anthropic-official
  (low supply-chain risk, stays current), so we **keep it enabled** rather than
  vendor + restyle ~8 third-party Python scripts for a tool not yet exercised.
  To stop it sitting idle, it is now **wired into our workflow**: the
  `claude-audit` skill names it as the standing tool for the skills dimension
  (measure triggering/behaviour, not eyeball the frontmatter), and
  `EXTENDING.md` instructs using it when **authoring/iterating any skill**
  (draft → eval → description-optimize). The sooner it is used, the sooner we
  learn whether to leave it as a plugin, **vendor** it, borrow its ideas, or
  drop it. **Follow-up logged** (audit backlog): investigate an analogous
  **rule eval / optimization** capability (possibly reusing skill-creator's
  harness). Landed via dotfiles PR.
- 2026-06-18 — **Dropped the `ralph-loop` plugin (built-in `/loop` covers
  it).** ralph-loop implements the "Ralph Wiggum" technique: a **Stop hook**
  that blocks Claude's exit and re-feeds the same prompt until a completion
  promise, an autonomous "keep going until DONE" loop, plus `/ralph-loop` /
  `/cancel-ralph` / `/help` commands. Dropped because the built-in **`/loop`**
  skill already does self-paced autonomous iteration (omit the interval) plus
  scheduled re-firing (ScheduleWakeup); ralph-loop's distinctive
  exit-blocking-until-promise mechanism is also the riskiest part — unbounded
  by default and in tension with `CLAUDE.md`'s autonomy boundaries — and it
  was never trialed. Disabled via `enabledPlugins`; cache +
  `installed_plugins.json` are gitignored local state; the stale "Trial
  ralph-loop" audit-backlog item is resolved to this decision.
  `ICEBOX:` if an autonomous **completion loop** / **exit-blocking "until
  DONE" loop** (ralph / Ralph Wiggum technique) is ever wanted, **extend the
  existing `/loop` command** (self-pacing + a completion check + a
  max-iteration cap) rather than build new but similar machinery — incorporate
  `/loop`, don't reinvent it.
- 2026-06-18 — **Dropped the `hookify` plugin (kept our bespoke-hook model).**
  hookify is a ~847-LOC vendored Python rule engine + four generic hook entry
  points that evaluate declarative markdown rules
  (`.claude/hookify.<name>.local.md`) to warn/block on bash/file/stop/prompt
  events, plus a `conversation-analyzer` agent and a `writing-rules` skill. It
  is a different hook model from ours (bespoke, single-purpose Python per hook:
  `merge-finalization.py`, `rule-coverage.py`, `branch-protection.py`).
  Dropped because: (a) the "own **and version**" goal cuts against it — its
  rules are gitignored, per-machine `*.local.md`, whereas our committed hooks
  are versioned; (b) none of our real hooks fit its pattern model (each needs
  custom logic — reading `.pre-commit-config.yaml`, scanning TODO, tracking
  deps); (c) owning 847 LOC that can block every tool event is a real
  maintenance + **security** surface for trivial guards we have never needed;
  (d) the conversation-analyzer "mine pain → propose a guard" angle is now
  covered by the new `retrospective` skill. Disabled via `enabledPlugins`;
  cache + `installed_plugins.json` are gitignored local state.
  `ICEBOX:` revisit a **declarative hook / guard-rule engine** — hookify-style
  pattern-based block/warn guard rules, low-friction declarative hooks without
  bespoke Python — **only if** we start writing many trivial pattern-guards
  and the Rule of Three kicks in. Until then, write a bespoke hook (cf.
  `branch-protection.py`). Landed via dotfiles PR.
- 2026-06-18 — **Dropped the `claude-md-management` plugin; built the
  `retrospective` skill from its idea.** The plugin's `claude-md-improver`
  (audit/edit CLAUDE.md against a rubric) and `revise-claude-md` (append
  session learnings to CLAUDE.md) are redundant with, and structurally
  mismatched to, our setup: it is CLAUDE.md-centric, whereas our repo context
  is split across `.claude/CLAUDE.md` → WORKFLOW/CONVENTIONS/TESTS/QA (quality
  + currency governed by `documentation.md`, audited by `claude-audit`), and
  "capture session learnings" is already the **memory system**'s job (richer:
  structured frontmatter + index) — appending prose to CLAUDE.md would erode
  the curated, versioned file. So the plugin was **dropped** (disabled via
  `enabledPlugins`; cache + `installed_plugins.json` are gitignored local
  state). The one genuinely useful idea — *reflect after a piece of work and
  persist what was learned* — was **rebuilt, not converted**, as the global
  `retrospective` skill, but aimed at the **agent's own tooling** (rules /
  skills / hooks / patterns / commands / MCP): it runs as **ship-pr Step 4.6**
  (advisory, never a gate), decides kind + scope per `EXTENDING.md` + the
  three-tier model, and captures each finding as a detailed open TODO routed
  global vs repo-local — feeding `claude-audit`'s backlog. Landed via dotfiles
  PR.
- 2026-06-18 — **Dropped the `claude-code-setup` plugin (redundant).** Its sole
  content is the read-only `claude-automation-recommender` skill — "analyze a
  repo's stack → suggest 1–2 Claude Code automations per category." The
  capability is already covered, and better fitted to our environment, by
  `CLAUDE.md` (*When to Propose a Skill* + *Missing or Conflicting Tool Rules*
  — proactive gap-surfacing as work happens), `EXTENDING.md` (the placement
  ladder: rule vs skill vs hook vs MCP, global-lazy vs per-repo), the
  `claude-audit` skill (surfaces gaps from each repo's vantage), and `mcp.md`
  (the mymcp pattern). Converting it would mean rewriting nearly all of its
  concrete advice, which actively conflicts with our setup (`claude mcp add
  context7` vs mymcp, recommending marketplace plugins we're removing, generic
  `.claude/skills/` patterns vs the three-tier model) — duplication, not
  value. Disabled via `enabledPlugins` in `config/claude/settings.json`; the
  cached copy + `installed_plugins.json` entry are gitignored local state
  (optional cleanup). Landed via dotfiles PR.
- 2026-06-18 — **context7 MCP: marketplace plugin → `mymcp` (own/version it).**
  The context7 plugin bundled nothing but its MCP server (`npx -y
  @upstash/context7-mcp`) — no skills/commands/rules/agents/hooks — so there
  was nothing to convert to a rule/skill, only the launcher to re-home. Added
  a `context7()` case to `bin/mymcp` (`npx_run '@upstash/context7-mcp'`) and
  dropped `context7@claude-plugins-official` from `enabledPlugins` in
  `config/claude/settings.json` (the same file as `~/.claude/settings.json`
  via the `~/.claude → config/claude` symlink, so one edit covers both).
  context7 is wanted **globally**, so it is re-registered at **user scope** —
  `claude mcp add context7 --scope user -- mymcp context7`, written to the
  personal, uncommitted `~/.claude.json`. (Verified via claude-code-guide:
  MCP servers are **not** configured in `settings.json`, and user scope is the
  only all-projects mechanism short of bundling a plugin — so there is no
  committed global-MCP file; the launcher is what we own/version, the
  registration is a per-machine deploy step.) Same global availability as the
  plugin, but the `mymcp` launcher is now ours instead of a marketplace
  dependency. The Context7 API key now comes from the private store —
  `context7()` does `read_api_key context7` and passes it via the
  `CONTEXT7_API_KEY` env var the server reads — so the key no longer needs
  exporting into every shell; its line was removed from `api-keys.cfg`.
  **Deferred:** `config/opencode/config.json`'s remote context7 still reads
  `{env:CONTEXT7_API_KEY}` and will be broken until reconfigured — left as-is
  per the user (opencode unused lately; fix on next encounter). Smoke-tested:
  `mymcp context7` launches Context7 v3.2.1 over stdio and answers the MCP
  `initialize` handshake; full tool-resolution is a post-deploy check
  (re-register + reload). Landed via dotfiles PR.
- 2026-06-16 — **`ICEBOX:` marker + feature-request behaviors (from pigify).**
  Standardized a discoverability convention for *deferred / revisit-on-request*
  decisions, born from a real pigify case (persistent playlist reorder under
  review). Global: `rules/code-style.md` defines the `ICEBOX:` marker (vs
  `TODO`/`FIXME`/`XXX`) and the keyword-dense rule so a grep on a future
  request's wording lands on the note; `CLAUDE.md` gains a **Handling Feature
  Requests** section — scan `ICEBOX:` first, and (the *generic* form of) verify
  external-API support against current docs before building, surfacing +
  recording any limitation (an `ICEBOX:` note plus the dependency's
  `rules/<tool>.md` *or* the repo's `.claude/`). The *specific* Spotify limits
  (no queue reorder, no playlist-library reorder) live in pigify's local
  `.claude/CONVENTIONS.md`, per the generic-global / specific-local split.
  Landed via dotfiles PR.
- 2026-06-12 — **Added `rules/nginx.md` (rule-coverage gap from pigify).**
  pigify configures nginx (TLS termination, the `/api` reverse proxy, and a
  CSP / `Permissions-Policy` tuned for a cross-origin SDK iframe) but there was
  no nginx rule — every nginx edit there had been unguided, and the session hit
  the two classic footguns first-hand: the missing `always` flag (headers
  dropped on error responses) and `Permissions-Policy` delegation to a
  cross-origin iframe. The new detection-activated rule covers reverse-proxy
  header hygiene, TLS hardening (1.2/1.3, HSTS, OCSP), the security-header set
  with the `always` + `add_header`-inheritance gotchas, CSP / Permissions-
  Policy authoring, SPA serving, and hardening. Grounded in official nginx docs
  (Context7 currency check). **Rule-only — no skill:** authoring is reference/
  policy (a rule's job), and the *procedural* side (verifying headers are
  actually served, incl. on error responses) already lives in `rules/zap.md` /
  DAST + the qa Security dimension, which the rule cross-references. No Idea
  source / SOURCE.md (official docs, no third-party repo mined). Landed via
  dotfiles PR.
- 2026-06-12 — **Built `spotify-patterns` skill (completes the Spotify
  category).** The recipe half deferred from the Spotify category, mirroring
  `fastapi-patterns` / `sqlalchemy-patterns`: concrete recipes for proactive
  token refresh, relinking-aware Library ops (the two bugs pigify hit, written
  first-hand from those fixes), pagination + set-based dedup, a 429/Retry-After
  backoff wrapper, playlist-creation strategies (by-artist / theme /
  song-list — the recommendation-seeded one dropped as deprecated-dependent),
  and cover-art (SVG→PNG, a11y contrast, `ugc-image-upload`). Wired into
  `rules/spotify.md` ("for recipes, invoke spotify-patterns"); SOURCE.md cites
  `fabioc-aloha/spotify-skill` (Apache-2.0, ideas-only). The mining census's
  ADOPT set is now fully shipped. **Follow-up logged** (census + TODO): re-mine
  Spotify's official Concepts / Tutorials / How-Tos sections for more material.
  Landed via dotfiles PR.
- 2026-06-12 — **Spotify category: `rules/spotify.md` + `spotify-audit`
  skill (audit run from pigify).** pigify (the first Spotify repo) surfaced a
  cluster of hard-won, non-obvious Spotify Web API quirks — track relinking
  (`linked_from` for Library ops), the 1-hour token + proactive refresh, the
  `127.0.0.1`-only OAuth redirect, and the Web-Playback-SDK / EME / Permissions-
  Policy requirements — each of which had already caused a bug. Built a global,
  detection-activated **`rules/spotify.md`** (the policy/reference: auth +
  PKCE, tokens, scopes, current-vs-deprecated endpoints incl. the 2024-11-27
  deprecations and the legacy `/me/tracks` save/remove, 429/Retry-After,
  relinking, SDK/EME, compliance) and a **`spotify-audit`** skill (`/spotify-
  audit`) that checks a codebase against it and emits a severity-grouped
  report. Repo-foreign-API guidance → **global, front-loaded** (ADR-0003).
  Ideas adapted from `fabioc-aloha/spotify-skill` (Apache-2.0, ideas-only —
  SOURCE.md); policy grounded in Spotify's official docs (its references are
  stale). `spotify-patterns` (cover-art, playlist strategies, pagination/dedup)
  deferred to `TODO.md`. Landed via dotfiles PR.
- 2026-06-12 — **claude-audit: use Context7 (if available) to verify
  currency.** Added a step to the **claude-audit** skill — when auditing a rule
  or adopting a pattern, query **Context7** for the tool/library/API's current
  docs to catch drift without cloning (it caught Spotify's `/me/tracks`
  deprecation that third-party guides missed). Strictly **second-class**
  (`mcp.md`): a convenience for the audit *process*, never a dependency of the
  resulting config; the audit works without it.
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
