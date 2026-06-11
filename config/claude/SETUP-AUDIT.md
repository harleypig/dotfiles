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

## Decisions log

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
