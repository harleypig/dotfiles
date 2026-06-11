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

## Findings & recommendations (proposed — awaiting decisions)

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

## Decisions log

Record keep / drop / defer + rationale here as each item is decided.
