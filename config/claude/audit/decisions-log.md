# Audit decisions log

Chronological record of Claude Code setup-audit decisions (newest first) — the
durable "why" behind each change. Append-only: a superseded decision is
annotated, not rewritten. Audit-only (not context-loaded); written by the
**claude-audit** skill. Sibling records: [`BACKLOG.md`](BACKLOG.md) (open
items) and [`idea-sources.md`](idea-sources.md) (mined repos).

- 2026-06-29 — **Worked the backlog: authored the IaC rule set (terraform /
  packer / tflint + tftest-patterns skill).** Closed the IaC-rules backlog item
  (added earlier the same day). Authored `rules/terraform.md`,
  `rules/packer.md`, `rules/tflint.md` (path-scoped, lean — matching
  `shfmt.md`/`shellcheck.md`), and a `tftest-patterns` **skill** (matching
  `pytest-patterns`; with `SOURCE.md`). Extended `trivy.md` with the
  `--misconfig-scanners terraform` IaC-scoping note (no duplication). Grounded
  every artifact in **official HashiCorp docs** (verified current, URLs in each
  rule's *Sources* / the skill's `SOURCE.md`) — promoting the generic parts of
  harleydev's `.claude/CONVENTIONS.md` (validate `-backend=false` + dummy AWS
  env, plan-only `.tftest.hcl` + `mock_provider`, the docker-vs-native hook
  tradeoff, packer `-syntax-only`), leaving repo-specifics in the repo.
  **Rejected** the mining agent's proposed heavy multi-skill collection
  (terraform/ + packer/ + tflint/ skills with `references/` trees) — it fights
  the lean, rule-first house philosophy; rules + one patterns skill is the
  right weight. **No `qa.md`/`qa-check` change needed**: both are tool-agnostic
  and detection-activated per-tool rules self-wire (STRUCTURE.md + `paths:`);
  the "wire into qa" note in the backlog item was over-cautious. Current-doc
  corrections folded in: `tflint --deep` is removed (now `deep_check = true` in
  a plugin block, credential-bearing); `terraform_tfsec`→`terraform_trivy`;
  antonbabenko has **no** packer hooks. Updated `STRUCTURE.md` (3 rules under
  Docker/Infrastructure + the skill under Domain depth); recorded the mined
  reference artifacts in `idea-sources.md`. This **closes the IaC anticipation
  gap** the prior entry noted (the Watch list never expected a Terraform stack).

- 2026-06-29 — **Assess pass from harleydev (IaC repo): fixed the `bats-setup`
  `tests/suite/`→`tests/shell/` drift; backlogged IaC rules (user-confirmed).**
  Ran `/claude-audit` from harleydev right after converting it (a Terraform/
  Packer/Docker repo) — a new stack vantage, which surfaced gaps rather than
  cruft (no ICEBOX/Watch triggers fired; nothing to drop/move). **(1) Drift
  fixed:** the `bats-setup` skill documented a `tests/suite/` layout, but its
  own declared source of truth `bats.md` (and `testing.md`'s per-language
  split, and the dotfiles' actual `tests/shell/`) mandate `tests/shell/`. Hit
  during the conversion and followed the rule, not the skill. Corrected the
  skill to `tests/shell/` (5 path refs + the frontmatter), bumped it to v1.0.1,
  and added a note tying the layout to the per-language split so it can't
  re-drift. Grep confirmed no other `tests/suite` referrers. **(2) Backlogged**
  (not authored this run, per the assess/work split): no `terraform.md`/
  `packer.md`/`tflint.md` exist despite heavy IaC use — added a MEDIUM
  `BACKLOG.md` item to author them (promoting the generic parts of harleydev's
  `.claude/CONVENTIONS.md`: `validate -backend=false` + dummy AWS env,
  plan-only `.tftest.hcl` + `mock_provider`, the docker-vs-native hook tradeoff,
  `packer fmt/validate`; extend `trivy.md` for `--misconfig-scanners
  terraform`). Noted the `mining-census.md` Watch list never anticipated an
  IaC/Terraform stack — to be closed when the rules land. **Not done:** did not
  path-scope the heavy always-on `git.md`/`code-style.md` (guardrail-dense —
  trim weight, not guardrails); did not wire harleydev's per-repo `terraform`
  MCP (second-class; the docker toolchain works without it).

- 2026-06-27 — **Adopted `pyright` for type-checking; `mypy` declined
  (user-confirmed).** Worked the `## 🐍 Python Setup` TODO items. The
  first-party Python surface is the seven agent hooks under
  `config/claude/hooks/` — all fully return-annotated and stdlib-only, and
  **clean under `pyright` standard mode** (0/0/0; strict adds 34 unavoidable
  `Unknown`/`Any` diagnostics from `json.load`, so standard is the right
  mode). Checked the sibling `pigify` repo to confirm the user's recollection:
  it is **pyright-only, no mypy anywhere** (`pyright` in pre-commit + CI; ruff
  for lint/format). Followed that precedent here — **`mypy` not adopted**: a
  second checker would add tooling + CI cost without catching anything on a
  small, fully-typed, pyright-clean surface (`python.md` keeps mypy as an
  optional CI second pass for repos whose plugin ecosystem needs it; this repo
  isn't one). Wired `pyright` **into pre-commit** (not a standalone CI step):
  the required `pre-commit` CI job runs `pre-commit run --all-files`, so the
  hook gives both commit-time and CI coverage with no double-run — the exact
  pattern `flake8`/`isort`/`yapf` already use, so no `tests.yml` change was
  needed. This **reverses** the prior TODO note ("type-check stays out of
  pre-commit") — superseded because the surface is now typed and clean, which
  it wasn't when that note was written. Authored the missing global rule
  `rules/pyright.md` (grounded in the official pyright config + CI docs, per
  `CLAUDE.md` *Missing or Conflicting Tool Rules*); `pyrightconfig.json` scopes
  the run to `config/claude/hooks` so pyright never recurses into vendored
  Python (`rustup`/`nvm`/`coc`/plugins). QA dim 3 flipped Off → Active.
- 2026-06-27 — **Evaluated a `pre-commit` skill — declined; clarified
  qa-check instead (user-confirmed).** Worked the root-`TODO.md` "Proposed:
  pre-commit skill, used by qa-check" item. Mapped every operational workflow
  the skill would package against existing forcing functions: **fix → check →
  commit-prep** is already driven by `ship-pr` Step 1 (runs the fix config
  then the check config) and `qa-check`'s Format/Lint stages; **repo
  scaffolding** (both configs + `pre-commit install`, the analogue to
  `bats-setup`) lives in `new-project` Step 3; the **cross-cutting-hook
  audit** is `qa-check`'s pre-commit-coverage note; and the one-shot
  maintenance commands (`install` variants, `autoupdate`, `validate-config`,
  `gc`) plus the **Hook & Repo Verification** procedure are already documented
  in the path-scoped `rules/pre-commit.md` (which loads on-demand when a
  config file is edited). The "cf. qa-check" framing doesn't transfer:
  `qa-check` earns its place orchestrating **many** easily-forgotten tools
  across **many** dimensions, whereas **pre-commit is a single,
  self-orchestrating tool** — `pre-commit run` *is* the pipeline, so there is
  no multi-tool sequence for a skill to force. A new skill would only
  duplicate trigger surface and drift against four existing artifacts. **Acted
  on the companion item** ("have qa-check delegate Format+Lint to pre-commit
  when present") by making the delegation **explicit** in `qa-check`'s
  `SKILL.md` (a new bullet: prefer pre-commit fix-then-check over direct
  `shfmt`/`shellcheck`, fall back when unconfigured) — it was previously only
  implied. Both root-`TODO.md` bullets pruned.
- 2026-06-20 — **Added a Watch-list trigger for writing/non-code repos
  (user request).** Folded the `claude-code-tips` writing tips — previously
  plain SKIP as "personal workflow" — into a single SKIP-until trigger keyed
  on **repo type**: a `gollum` wiki repo (specific) or, generally, any
  non-code "writing"/prose repo (the simplified code-vs-writing split, to be
  refined when it matters). When it fires, author a dedicated **writing rule**
  (`rules/writing.md`, "disabled until then") covering the
  drafting/revising/structural/consistency/gardening modes, grounded in Tip 16
  ("Claude as a writing assistant") **and Tip 25** ("Claude as a research
  tool" — research-assisted writing, `paper-search` for academic papers), plus
  Tip 17 (markdown medium) and Tip 26 (verify *every* claim — critical for
  scholarly/scriptural accuracy). The trigger also activates the backlog
  **Gollum Wiki rule** / **Ruby rule** / **Essay Helper skill** candidates,
  now marked trigger-gated rather than do-now. Per the mining rule, the
  original per-tip SKIPs in `mining/claude-code-tips.md` are left intact —
  this adds the resurfacing trigger, it doesn't rewrite them.
- 2026-06-20 — **Mined the plugin/skill collection queue (11 repos at once):
  heavy duplication, 1 CANDIDATE + 5 Watch triggers (PR #140).** Worked the
  *Mining queue* "big collection repos" item — `awesome-claude-plugins`
  (ComposioHQ), `claude-code-plugins-plus-skills` (jeremylongshore),
  `awesome-claude-code-plugins` (ccplugins), `claude-skills` (alirezarezvani),
  `caveman`, `antigravity-awesome-skills`, `headroom`,
  `awesome-claude-code-subagents` (VoltAgent), `claude-skills` (Jeffallan),
  `plugins-for-claude-natives` (clarify), `ClaudeAdvancedPlugins`. Fanned out
  to **11 read-only census agents** (net-new only, to spare audit context),
  then deduped. **All 11 SKIP as adopt-sources** (curated link-lists,
  domain/SaaS marketplaces, single-idea products); the queue's "expect
  duplicates" premise held. The value is the **cross-repo theme signal** — a
  theme surfaced by several independent repos. **One CANDIDATE** →
  `BACKLOG.md`: **agent supply-chain / install-safety audit** (scan an
  external skill/plugin for malicious code *before* install —
  `skill-security-auditor`; lint a repo for agent-readiness — `AgentLint`);
  directly relevant since we adopt external skills with no gate, and it
  **pairs with the `cc-safe` permission-allow-list
  CANDIDATE** into one "harden the agent's own attack surface" theme.
  **Five Watch-list triggers** (all build-on-first-use, ADR-0003):
  reliability/observability/SRE (chaos/SLO/incident/runbook — a **4-repo
  signal** that fills the acknowledged `qa.md` dim 10/11 gap), MCP-server
  building (4-repo), API-contract review, security-domain agents
  (red/blue-team/pentest — on authorized security work), and
  context-economy-by-compression (compress tool outputs / MCP descriptions /
  memory — vs our economy-by-removal+snapshot). **Reconfirmed held:** the
  spec→plan→onboarding *workflow* cluster (future workflow/planning category)
  and the standard language/domain-expert agent sets (already charted via
  `claude-tools`). Full per-repo + theme matrix:
  `audit/mining/plugin-collection-repos.md`; sweep registered in
  `idea-sources.md` as one grouped entry. **Also queued (user request):** the
  **Claude Code official documentation** as a first-party mining source — much
  is how-to-use-Claude that won't fit, but the config surface (hooks,
  settings, permissions, slash commands, skills, plugins, statusline) is
  mineable.
- 2026-06-20 — **Mined `ykdojo/claude-code-tips` (mining queue): 41/43 SKIP,
  two CANDIDATEs surfaced (PR #139).** A 43-tip prose README (hybrid — also a
  `dx` plugin + 6 skills) by a Claude-Code YouTuber, ~8.9k★, actively
  maintained, but **non-OSS** (proprietary contributor grant to YK Sugi) so
  **ideas only, no impl reuse**. Most tips skew to **personal interactive
  workflow** (voice, terminal tabs, Notion, Mac clipboard) or are already
  covered by our (more developed) tooling — worktrees →
  `git-worktree-workflow`;
  CLAUDE.md-vs-skills → `EXTENDING.md`; TDD → `testing.md`; simplify →
  `/simplify`; CI root-cause → `github-actions.md` + `ci-watch` +
  `debug-assistant`; periodic CLAUDE.md review → `claude-audit`. Two were
  **counter to our posture** and explicitly SKIP: disable-attribution (we keep
  `Co-Authored-By`) and `--dangerously-skip-permissions` containers (we don't
  skip permissions). **Two CANDIDATEs** recorded on `BACKLOG.md`: (1) **audit
  the permission allow-list** for risky auto-approved commands (the `cc-safe`
  idea, Tip 31 — `sudo`/`rm -rf`/`chmod 777`/`curl | sh`/`git reset --hard`);
  a real security gap, natural fold into `claude-audit` (it already inspects
  `settings.json`); the *idea* adopted, not the npm tool. (2) **input-box
  keybindings** (Tip 36) — exact bindings folded into the open *statusline
  keybinding cheat-sheet* item as a **secondary, non-authoritative** source to
  cross-check against the official docs. Full matrix:
  `audit/mining/claude-code-tips.md`; registered in `idea-sources.md`. (Census
  fanned out to a read-only research agent per the grounding rule; primary
  sources + URLs.)
- 2026-06-20 — **Evaluated `ruvnet/ruflo` (mining queue): SKIP the runtime,
  register the corpus as a low-yield source (PR #138).** Researched from
  primary sources (60k★, 7k forks, daily-active, MIT; it is the **renamed
  `claude-flow`**). It's a Claude-Code-native multi-agent **swarm** harness —
  `npx ruflo init` installs 98 agents / 60+ commands / 30 skills / an MCP
  server / a hooks daemon / a Rust memory engine. **Verdict: SKIP the
  framework** — its heavyweight, auto-routing, self-learning-swarm +
  always-on MCP/daemon philosophy is the **opposite** of our curated,
  minimal-context, audit-driven setup; adopting it would fight our whole
  approach. Its `.claude/` corpus is the largest real-world reference, but
  **low-yield to mine**: the patterns (hook dispatcher, skill-builder spec,
  SessionStart-restore, frontmatter rules) overlap what we already have
  (`EXTENDING.md`, `test_skill_frontmatter.bats`, `compact-snapshot` /
  `audit-cadence`), and the repo is marketing-heavy (1,500+ releases, volume ≠
  quality). **Recorded, not mined:** registered in `idea-sources.md` so a
  future audit doesn't re-evaluate cold; the one forward idea — **session
  checkpoint/restore** (its PreCompact + context-persistence hooks, beyond our
  `compact-snapshot`) — parked on the mining-census Watch list. No deep mining
  pass, no adoption. (Per the delegated-research grounding rule, the research
  agent returned primary-source facts + URLs, not impressions.)
- 2026-06-20 — **Text re-mined the Anthropic official `code-simplifier` +
  `commit-commands` plugins (PR #137).** Both were dropped at *capability*
  level on 2026-06-10 without reading their prompt/command text; this is the
  text-level pass (read from the local marketplace cache, no fetch). **One
  fold:** `code-simplifier`'s "avoid nested ternaries / dense one-liners,
  clarity over brevity" — a concrete, generic readability rule we lacked —
  added to `code-style.md` *Prefer elif Over Sequential if Blocks* (v1.7.0).
  **Rest SKIP, with reasons:** code-simplifier's stack-specifics (ES modules,
  React, arrow functions) violate the generic-layer-names-no-language rule
  (`EXTENDING.md`); its "auto-refine proactively after every edit" mode
  contradicts our scope discipline (`CLAUDE.md` — don't improve adjacent
  code); "focus on recently-modified code" / "preserve functionality" are
  already how our review skills work. `commit-commands` (`commit`,
  `commit-push-pr`, `clean_gone`) all SKIP — `git.md` *Commit Messages* +
  `ship-pr` + `git-worktree-workflow` Op 7 are richer and **safer** (ours
  confirms each branch / skips dirty; the plugin force-deletes). Net: the
  capability-level drops stand; one small wording fold gained. **Follow-up
  (user request):** the new no-nested-ternary rule's **Perl exception** was
  added to `rules/perl.md` — idiomatic terseness (single-line ternaries,
  statement modifiers) is Perl's character and relaxes the rule, short of
  golf; perl.md also gained its `code-style.md` reference-up, so it now
  conforms to the language layering (removed from the conformance-sweep list).
- 2026-06-20 — **Resolved commitizen + changelog-generation as deliberate
  non-adoptions; closed "Remaining rules to author" (PR #136).** Worked the
  last two items of the *Claude Rules Files* list together (they're coupled —
  `commitizen` is the one tool that spans conventional-commit *authoring* +
  `cz bump` + `cz changelog`). An inventory found **no functional gap**:
  conventional commits are mandated in `git.md` *Commit Messages* and authored
  by the agent (no `cz` CLI/config/hook anywhere), and the changelog is
  **manual** keep-a-changelog at merge-time (`ship-pr` 4.5), grouped by date
  since dotfiles isn't release-versioned (`.claude/QA.md` already records
  *Generated changelog: N/A*). **Decision (user picked the lean path):** do
  **not** author `commitizen.md` / `git-cliff.md` for tools nothing uses —
  build-on-first-use (ADR-0003) — and defer them to `ICEBOX.md` with triggers
  (a repo wanting `cz`-driven commits/bump, or a git-history-generated
  changelog). With these resolved, the *Remaining rules to author* list is
  **empty** and closed. No new artifact authored — the right outcome was the
  evaluation + a recorded deferral, exercising the ICEBOX structure.
- 2026-06-20 — **Completed the git-tagging rule item; added the missing
  definitions to `git.md` (PR #135).** The core was already covered (`git.md`
  *Versioning & tags*: semver, annotated-only hygiene, repo/subdir methods +
  the `release-tag` skill), so the item was largely done. Filled the gaps the
  backlog listed — kept brief because `git.md` is **always-on**. **Added (user
  chose the lean set):** (1) **calver** as the declared **format** alternative
  to semver (date-based, e.g. `vYYYY.MM.DD`; format is now a per-repo axis
  separate from the repo/subdir method; release-tag taught to derive it before
  first use); (2) **signing** is optional and per-repo — annotated is the
  baseline, `git tag -s` (GPG/SSH) optional, **default unsigned** (no signing
  configured); (3) a **trunk-based** note — tag the merge commit on the
  default branch; release-branch (`release/*`) strategies aren't used.
  **Deliberately NOT added:** a full release-branch / gitflow model —
  speculative (trunk-based workflow) and it would bloat always-on `git.md`.
  git.md → v1.12.0.
  **Naming decision:** rejected recasting `code-style.md` to a
  "best-practices" doc — too broad (not just code) — and kept it as the
  generic shared style layer. **Placement (user chose EXTENDING canonical):**
  stated the policy once in a new `EXTENDING.md` *The language & tool stacks*
  subsection under *Layer the generic over the specific*. **The policy:** the
  generic layer (`code-style.md` / `EXTENDING.md`) names **no** specific
  language or tool; a language gets a `rules/<lang>.md` rule, plus a **skill**
  and **patterns** skill *only where it makes sense / is available*; a
  **tool** mirrors that shape but **must not reference a language file** —
  instead the
  **tool rule** declares the language(s) it applies to, by name (its
  Detection/applicability; a tool skill defers to the rule). References flow
  one way, **specific → generic** (and tool → language-by-name, never tool →
  language file), to avoid circular drift-prone coupling. **Caveat caught in
  review:** the "no language-file reference" rule is only for
  *language-agnostic* tools — a **single-language framework/library**
  (`fastapi.md` building on `python.md`, `react.md` on `typescript.md`, the
  `*-patterns` skills) is language-axis and *may* reference its language; the
  policy, the `claude-audit` check, and the sweep task all carry that
  distinction so the sweep doesn't strip legitimate framework references.
  `code-style.md` *Language-Specific Notes* was stripped of its (stale,
  Bash/Python-only) language list and now points to the codified policy;
  `claude-audit` step 2 verifies the layering. Follow-up filed: a conformance
  sweep (several language rules don't yet reference up; audit tool rules for
  language-file links). code-style.md → v1.6.0, EXTENDING.md → v1.2.0.
- 2026-06-19 — **Folded the "check prior art before authoring" guidance into
  `EXTENDING.md` (PR #133).** A BACKLOG bullet ("when creating/modifying a
  rule or skill, check known sources for an existing implementation to vendor
  rather than author from scratch") was standing policy, not a task — so it
  belonged
  in the authoring doc, not the todo. Added it as a third requirement in
  `EXTENDING.md` *Grounding & sourcing* (v1.1.0): prefer adapting prior art
  (GitHub search, the `awesome-agent-skills` / officialskills.sh aggregators,
  the `idea-sources.md` registry; vendor-and-adapt with a `SOURCE.md`), the
  reactive counterpart to `claude-audit`'s *Mining repos for ideas*, with the
  pointer to the dotfiles `TODO.md` *Vendored file / skill update checker*
  preserved. Removed the bullet from BACKLOG.
- 2026-06-19 — **Added `audit/ICEBOX.md`; made BACKLOG a pure will-do todo
  (PR #132).** The user wanted the backlog treated strictly as a todo — icebox
  / wait-until-needed entries don't belong in it. **Structure (user chose "two
  homes by shape"):** three non-overlapping registers — `BACKLOG.md`
  (actionable will-do), `ICEBOX.md` (**our own** deferred "not now" decisions,
  free-form, each with a revisit condition: a trigger or "on request"), and
  the `mining-census.md` Watch list (**mined external** `SKIP-until`
  candidates, a
  terse trigger→adopt table). `ICEBOX.md` is the audit-scope home for the
  in-code `ICEBOX:` marker (`code-style.md`) when a decision has no code
  location to pin a comment to. **Moved** out of BACKLOG into ICEBOX.md: the
  "native statusline indicators can't be hidden" finding (revisit if
  anthropics/claude-code #27916 / #48246 lands a hide option) and the
  heavier/transcript-driven statusline candidates (revisit if plain `X%` stops
  being enough). Wired it in: `claude-audit` skill scans `ICEBOX.md` + the
  Watch list for fired triggers each run and routes follow-ups by kind;
  `SETUP-AUDIT.md` and the BACKLOG header index the boundary.
- 2026-06-19 — **Re-homed the "Plugin-audit follow-ups" items to the
  mining-census Watch list; removed the BACKLOG section (PR #132).** After
  the #131 prune, that section held only **trigger-gated `SKIP-until`** items
  (do nothing until a repo needs them / until we build `pydantic_ai` agents) —
  not actionable work, so they read as confusing open tasks. Worse, the
  `pydantic_ai` deferred-rule item **duplicated** the existing Watch-list row,
  and the claude-audit skill's own rule says *every `SKIP-until` lives on the
  census Watch list*. **Fix:** deleted the BACKLOG `pydantic_ai` item (already
  on the Watch list) and added the three vendor-when-needed items
  (`pr-review-toolkit` lenses, `feature-dev` phased flow, a GH-Actions
  PreToolUse hook) as Watch-list rows with triggers — their drop rationale
  already lives in this log (2026-06-10). Removed the now-empty "Plugin-audit
  follow-ups" section. Net: BACKLOG holds only actionable open work;
  trigger-gated items sit where the re-promote-on-trigger mechanism is.
  user noticed completed items weren't removed at merge and asked whether the
  skill/rule covers the backlog. **Diagnosis:** two of three sources already
  said *prune* — the `claude-audit` Finalize step ("remove the item from
  `audit/BACKLOG.md`") and ship-pr Step 4.5 ("any equivalent planning list") —
  but (a) the `merge-finalization.py` hook only scanned `TODO.md`/`ROADMAP.md`
  (BACKLOG not in `PLANNING_DOCS`), so nothing enforced it; (b) the BACKLOG
  **header said "retained for continuity,"** contradicting the prune rule; and
  (c) I leaned on that header and skipped it in #130 — inconsistent with #129,
  where I *did* prune. **Decision (user chose prune-at-merge):** BACKLOG
  behaves like `TODO.md` — done items removed at merge, the record kept in
  this log / ADRs / `mining-census.md`. **Cleanup:** rewrote the header;
  deleted the 25 `[x]` items; because the hook can't tell a done item from a
  *parent of open children*, **promoted** the open children to standalone
  `[ ]` items (the deferred `pydantic_ai` agent-framework rule; the
  pr-review-toolkit / feature-dev / GH-Actions vendor-when-needed bits) and
  reworded the *Future top-level categories* item so it doesn't dangle a
  now-empty list — leaving **zero `[x]`** so the hook enforcement is coherent.
  **Enforcement:** added a generic `merge-finalization-docs:` mechanism in the
  hook (a repo declares extra planning docs in its opt-in `.claude/` docs,
  keeping repo-specific paths out of the global hook); dotfiles `WORKFLOW.md`
  (v1.5.0) declares `config/claude/audit/BACKLOG.md`; ship-pr Step 4.5
  (v1.9.4) names it explicitly; `tests/python/test_merge_finalization.py`
  covers the new path (block on a declared doc with `[x]`, allow when clean,
  ignore when undeclared).
- 2026-06-19 — **Cleared the *Audit dimensions / design* backlog section
  (batch, PR #130).** Took the section to zero open items. The four
  design-checklist items (context-load tiering, recategorize/split/merge,
  plugins/MCP, build-vs-adopt) were marked done as **folded into the
  `claude-audit` skill** — standing dimensions of every run, retained in
  BACKLOG with a pointer (this section keeps `[x]` for continuity, like the
  `[x] Form` item). Seven build items: (1) **rule-frontmatter guard**
  `tests/shell/test_rule_frontmatter.bats` — flags any `rules/*.md` lacking
  `paths:` or a `# No paths` comment; a CI gate, not a hook (rules are added
  rarely); `rule-TEMPLATE.md` + `.claude/TESTS.md` (v2.5.0) updated. (2)
  **Canonical protected-branch detection** in `git.md` (v1.11.0) — the
  `gh api rules/branches` / `.../protection` commands as the numbered method;
  `new-project.md` now references it (resolves the PR #129 retrospective). (3)
  **Plugin-aware proposals** — CLAUDE.md's *Missing or Conflicting Tool Rules*
  and *When to Propose a Skill* + the `rule-coverage.py` reminder now add an
  adopt-vs-build plugin check. (4) **Cross-repo follow-up routing** —
  WORKFLOW.md (v1.4.0) gains a *Cross-repo* TODO-routing case. (5)
  **Delegated-research over-claim** — claude-audit grounding notes demand an
  exact quote + doc URL for any feature claim driving an action. (6)
  **External validation** closed as resolved+redirected to the badges task.
  (7) **Cadence
  (user chose the SessionStart hook nudge):** `config/claude/hooks/
  audit-cadence.py` injects a once-a-day `/claude-audit` nudge on
  startup/resume/clear, deduped via an `XDG_STATE_HOME/claude-audit-cadence`
  date marker, fail-safe; `tests/python/test_audit_cadence.py` (5 cases); hook
  count 5→6. Retrospective filed (LOW): a prose-wrap check for agent-config
  Markdown.
- 2026-06-19 — **Authored the "new project setup" item as both a rule and a
  skill.** Worked the long-standing BACKLOG item (under *Claude Rules Files*).
  **Kind decision:** by `EXTENDING.md`'s primitive guidance a multi-step init
  is skill-shaped, but the user chose **both** — a thin **policy** rule plus
  the **procedure** skill, the `bats-setup → bats.md` pattern. **Context
  economy:** the rule is **path-scoped** to manifest/scaffold files
  (`pyproject.toml`, `package.json`, `Cargo.toml`, `go.mod`, `Gemfile`, the
  pre-commit configs, `DEVELOPER.md`) so it never joins the always-on tier — a
  setup rule has no natural glob and would otherwise be per-turn bloat
  (scoped-rule count 42→43; always-on stays 8). The backlog's
  "points-from-experience" became the rule's policy; **language bootstrapping
  is delegated to the per-language rules**, not inlined (the split the item
  flagged), per *Layer the generic over the specific*. **Brownfield mode:**
  the skill also **converts an existing repo to the claude setup**
  (inventory → gap-analyze → wire missing layers non-destructively → the
  `.claude/` decision → promote repo-local rules to global) — folding in a
  convert-existing idea
  the user expected captured separately but that only existed implicitly here.
  **Protected-branch detection fix:** the "never author on a protected branch"
  guidance originally leaned on the local `no-commit-to-branch` hook, which a
  not-yet-converted repo lacks (circular); reworked to detect via the host
  ruleset/branch-protection **API** (`gh api .../rules/branches/<branch>`) →
  `.claude/` docs → local hook args, default-protected when unsure, and **ask
  the user** if nothing resolves it. Grounding: house convention (no external
  source). Retrospective filed (BACKLOG, LOW): promote that concrete detection
  command into `git.md` as the canonical source so it doesn't drift. Shipped
  PR #129. Files: `rules/new-project.md`, `skills/new-project/SKILL.md`,
  `SETUP-AUDIT.md`.
- 2026-06-19 — **Settled Claude Code compaction control; wired a
  `SessionStart`/`compact` snapshot hook.** Worked the BACKLOG item, grounded
  in current official docs (claude-code-guide). **Q1 — the `# Compact
  instructions` CLAUDE.md heading feature is REFUTED:** no such heading-matching
  feature is documented; the earlier claim was wrong (the more thorough prior
  lookup was right). What is real is that project-root `CLAUDE.md` + global
  `CLAUDE.md` + `MEMORY.md` are **auto-reinjected** after a compaction — no
  magic heading filters what's kept. So **nothing added to `CLAUDE.md`** (and
  recorded here so the heading idea isn't re-attempted). **Q2/Q3/Q4 confirmed:**
  `/compact [instructions]` takes free-text focus; no threshold knob;
  `autoCompactEnabled:false` / `DISABLE_AUTO_COMPACT=1` disable; `/compact` is
  user-only; and the **`SessionStart` hook fires after compaction with
  `source: "compact"`**, its `additionalContext` injected into the rebuilt
  context — the documented lever for surviving compaction. **Decision (user
  chose the git/session-state option):** built `config/claude/hooks/
  compact-snapshot.py` (matcher `compact`) — it injects a short deterministic
  snapshot (repo, branch + protected-default warning, the branch's open PR via
  `gh`, working-tree status) that the auto-reinjection does **not** cover.
  Read-only, fail-safe (non-git/detached/non-compact → emits nothing), gh
  best-effort with a short timeout. Tested via `tests/python/
  test_compact_snapshot.py` (pytest, matching the existing Python-hook test
  convention — *not* bats). Cost is near-zero: it runs only on compaction, not
  per turn. Hook count 4 → 5 (`SETUP-AUDIT.md`).
- 2026-06-19 — **Investigated the agentskills.io skill-format standard;
  confirmed we're already conformant.** Worked the BACKLOG item, grounded in
  current sources (three research agents). **`agentskills.io` is the real,
  Anthropic-originated open standard** for Agent Skills — the `SKILL.md` format
  Anthropic created and released as a cross-vendor open standard on 2025-12-18
  (adopters include OpenAI Codex, Google Gemini CLI, GitHub Copilot, Cursor,
  JetBrains, Goose, …). Crucially it is **the same format we already use**, not
  a competing one, so there is **nothing to migrate**: a conformance sweep of
  all 27 skills passed every hard constraint (name matches parent dir;
  lowercase/digits/hyphens; no leading/trailing/`--`; ≤64 chars; description
  ≤1024). **Corrected an over-claim:** one research agent asserted a name
  "must not contain `claude`/`anthropic`" rule; a targeted re-check of the spec,
  the Claude Code docs, and the `skills-ref` validator found **no such rule** —
  `claude-audit` is fully valid. Decision: **document the open standard as our
  reference** (`EXTENDING.md` Skill › *Format*) and keep the minimal
  `name`+`description` frontmatter; **skip the optional standard fields**
  (`license`/`compatibility`/`metadata`/`allowed-tools`) for internal skills
  (one vendored skill, `frontend-design`, legitimately keeps an upstream
  `license`). **Guard built (option a, same PR):**
  `tests/shell/test_skill_frontmatter.bats` self-hosts the conformance check
  (name matches dir + charset/length; description ≤1024) in the gating suite;
  the external Apache-2.0 `skills-ref` validator (option b) is **ICEBOXed** in
  that test — same no-external-tool-to-lint-our-own-files posture as semgrep/
  trufflehog/etc. Negative-tested (it fails on a missing description, bad
  charset, and name≠dir) so it isn't a no-op.
- 2026-06-19 — **`branch-protection.py` hook now allows edits to gitignored,
  untracked files.** The edit-time guard blocked an edit to a **gitignored**
  memory file while on `master` — and the report wrongly called that an
  inherent limitation ("the hook can't tell tracked from untracked"). The user
  corrected it: `git check-ignore` / `git ls-files --error-unmatch` answer
  exactly that. Added `_is_local_only(repo, target)` — **ignored AND
  untracked** — and a short-circuit allow in `main()`. The *untracked* half is
  load-bearing: a force-added file that is both tracked and ignore-matched can
  still land in a commit, so it stays protected (verified by a dedicated test).
  Rationale: the rule guards *commits* on the protected branch, and an
  ignored, untracked file (logs, caches, the agent's own memory) can never
  become one. Two new tests in `test_branch_protection.py` (allow ignored;
  block tracked-but-ignored); docs updated in `git.md` (v1.9.0→v1.10.0,
  layer 3) and `.claude/WORKFLOW.md`. Same-file edit (the `~/.claude →
  config/claude` symlink) means no separate deploy.
- 2026-06-19 — **Documented the kept-branch-after-squash sync mechanic in
  `git.md`.** Worked the BACKLOG item (a PR #117 retrospective follow-up).
  Added a new section *Continuing on a Kept Branch After a Squash-Merge*
  (git.md v1.8.0→v1.9.0) + an Agent Rules bullet. The fact: a squash-merge
  makes the branch's changes a *new* commit on the default branch but does
  **not** make the branch an ancestor, so `git merge <default>` into a kept
  branch carries the branch's original commits forward as redundant history
  that pollutes the next PR's commit list (PR #117 needed a `rebase --onto`
  cleanup). The mechanic: `git reset --hard origin/<default>` when nothing new
  is on the branch, or `git rebase --onto origin/<default> <last-merged>
  <branch>` when post-squash commits exist — never `git merge`. This **promotes
  the note out of the (untracked, personal) `batch-todos` working memory into
  the canonical rule** so it isn't memory-only; the memory can now point at the
  rule. Default-branch-agnostic wording (no hardcoded `master`), per `git.md`'s
  own rule.
- 2026-06-19 — **Evaluated CodeFactor & Snyk; relaxed the OSS-pinned-only
  security posture into a default + per-repo escape hatch.** Worked the BACKLOG
  *CodeFactor & Snyk* item, grounded in current official docs (two research
  agents). **Findings:** both are hosted SaaS *App* checks (not in CI).
  CodeFactor is App-only (no CLI — structurally can't run in a workflow); Snyk
  *can* run in CI via `snyk/actions` but only with a `SNYK_TOKEN` + account,
  reporting to app.snyk.io — the exact token-gated marketplace pattern the
  posture avoids. For *this* repo both fail the worthwhile-results bar: the only
  manifests are `config/pypoetry/{poetry.lock,pyproject.toml}` (already covered
  by osv-scanner + Dependabot), and CodeFactor merely re-runs ShellCheck /
  yamllint already gated locally (and skips Markdown/Perl). **Decision (this
  repo):** drop Snyk (uninstall the App — a user web-UI action, captured in
  BACKLOG), keep CodeFactor as a passive non-required badge; recorded in
  `.claude/QA.md`. **Policy change (global):** the user judged the absolute
  "never a marketplace action / vendor cloud" stance too broad — it's right for
  *this* shell repo but would wrongly forbid a real app repo from adopting Snyk
  SCA where its curated intel / reachability / fix-PRs are genuinely worthwhile.
  Reframed `security-scan` §4 (v1.1.0→v1.2.0) into **OSS-pinned-direct default +
  a documented per-repo exception**: a hosted scanner may be adopted when its
  results are worthwhile, overlap is acceptable (the user's bar: *some overlap
  is fine if the results are worthwhile*), the owner accepts the token/account/
  drift costs, and it's recorded in that repo's `.claude/` QA doc, non-required
  first. Cross-noted in `semgrep.md` (v1.0.0→v1.1.0) and `trufflehog.md`
  (v1.1.0→v1.2.0) — both note the exception doesn't apply to *them* (their OSS
  engines fully match the SaaS for our use). Spawned follow-ups: per-repo Snyk
  evaluation for **pigify** (Python) and **scripturestudy-app** (Ruby), plus a
  research task on **credibility badges as social proof** across public repos
  (all in BACKLOG).
- 2026-06-19 — **Resolved the always-on rule-scoping review (the last two
  unscoped single-purpose rules).** Worked the BACKLOG *Always-on rule scoping*
  item. **`trufflehog.md` → path-scoped** to `.github/workflows/**` (bumped
  v1.0.0 → v1.1.0): the rule's entire concern is the `secret-scan.yml` CI
  workflow, so it loads only when a workflow file is edited — mirroring the
  `github-actions.md` precedent (same glob, same reasoning). The `security-scan`
  skill reads it by name when it runs, so nothing that needs it depends on the
  per-turn tier. **`claude-code-auth.md` → kept always-on** (bumped v1.0.0 →
  v1.1.0, added a documenting `# No paths` frontmatter): it is a guardrail
  (never export `ANTHROPIC_API_KEY` globally — the mistake that broke the Max
  subscription, PR #110) whose trigger is **conversational** (auth diagnosis,
  "/status shows the wrong method", "set up my key"), not a file edit — so
  path-scoping would make it miss exactly those moments, and its token files
  live in a separate repo (`private_dotfiles`) anyway. Per "trim weight, never
  guardrails," it stays. Consequence: the always-on tier drops from 9 unscoped
  rules to 8 (7 cross-cutting + `claude-code-auth`); 42 are now `paths:`-scoped.
  Every always-on rule now carries an explicit `# No paths — <why>` frontmatter,
  so "no frontmatter" is no longer an ambiguous state. Updated `SETUP-AUDIT.md`
  baseline.
- 2026-06-19 — **Restored the vim-mode segment; confirmed the other native
  indicator lines can't be hidden.** Set `statusLine.hideVimModeIndicator: true`
  (placement confirmed against the docs — a sibling of `type`/`command`) and
  render `.vim.mode` ourselves: a leading segment, NORMAL in bright-yellow-on-red
  (live command keystrokes), INSERT/others standard, absent when vim mode is off.
  This removes the built-in `-- INSERT --` text and its NORMAL-collapses-to-empty
  vertical jitter. Two research tasks settled the rest: (a) the **auto-accept /
  permission-mode** indicator (`⏵⏵ auto mode on`) and the **subagent/task** line
  have **no documented or findable off-switch**, and the permission mode is **not
  in the statusline stdin JSON** (so not reconstructable); (b) **`claude-hud`
  offers no suppression** of native lines (sets no key, can't see the mode, just
  stacks its transcript-parsed agents line on top). Recorded as a BACKLOG
  `ICEBOX:` with upstream #27916 / #48246. 15 statusline tests. Folded into the
  statusline PR.
- 2026-06-19 — **Added the rate-limit / usage segment to the statusline.**
  Worked the top remaining claude-hud candidate. Added two fields
  (`rate_limits.five_hour.used_percentage`, `…seven_day…`) rendered as
  `5h:NN% 7d:NN%` **inside the context segment** (no `|` between — per the
  user), each colored by a shared `pct_color` helper (the same calm/warn/alarm
  ramp as context %; extracted because ctx/5h/7d all need it — Rule of Three).
  Hidden when `rate_limits` is absent (non-subscriber sessions). jq uses
  `(… // "") | if . == "" then "" else (floor|tostring) end` so the field is an
  empty string (not a vanished array element) when missing — safe with the
  unit-separator parse. Extended `test_statusline.bats` to 12 tests (present /
  absent / color-escalation). Folded into the statusline PR.
- 2026-06-19 — **Added the reasoning-effort indicator; root-caused the parse;
  corrected the `.vim.mode` story.** Verified against the official statusline
  docs (claude-code-guide) that **`.effort.level`** (low/medium/high/xhigh/max,
  absent when the model lacks effort) is a real field — added it to
  `statusline.sh` as a `[level]` tag riding with the model (no `|` between),
  colored by level via the same calm/warn/alarm scheme as context %, shown only
  when present. While there, fixed the
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
