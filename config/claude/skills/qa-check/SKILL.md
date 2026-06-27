---
name: qa-check
description: Run the full quality-assurance pipeline on a change (format, lint, type-check, tests, security, build, CI, and the rest of the qa.md dimensions) — using the current repo's own QA doc for the concrete commands and the global qa.md for the dimensions/discipline. Use whenever the user wants to validate quality or readiness: "run QA", "qa check", "quality check", "is this ready to merge/PR", "run the checks", "lint and test this", "verify this change", "check everything passes", or before opening/finishing a PR. Composes the containerize skill (images) and security-scan skill (SAST/deps).
---

# QA Check

**Version:** v2.3.1

Run the quality-assurance pipeline for **this** repo and route every stage
through its rule. QA spans many tools that are individually easy to forget;
this skill is the forcing function that runs them in concert and in order. It
orchestrates; the rules and the repo's QA doc are the source of truth.

This skill is **tool-agnostic** — it does not assume any particular language
or toolchain. It learns the concrete commands from the repo itself.

## Read first

1. **The repo's QA doc** — the concrete tools, commands, required CI checks,
   and a **per-dimension status** for *this* repo. Look in `.claude/` (a
   "Quality assurance" section in `CONVENTIONS.md`, or a dedicated QA doc),
   plus `WORKFLOW.md` / `TESTS.md`. **This is where the actual commands come
   from.** Per `qa.md`, the doc should give every dimension a status —
   **Active** / **Planned** (+TODO link) / **Off** (+reason) / **N/A**.
2. **`rules/qa.md`** — the language-agnostic pipeline: the dimensions, their
   order, the fix/check discipline, and the idioms + optimization stances.
3. The detection-activated **per-tool rules** for whatever the repo uses
   (e.g. `biome.md`, `semgrep.md`, `vitest.md`) — for each tool's details.

If the repo has **no QA doc**, derive the pipeline from the detected tooling
(manifests, configs, pre-commit, CI workflows) and the per-tool rules — and
flag that the repo should document its QA setup.

## Scope to the repo

Detect what exists and run only the applicable dimensions; **name the gaps**:

- Languages, manifests, test runners, security setup, Dockerfiles, CI
  workflows present → the stages they imply.
- Inapplicable dimensions are N/A (a library has no UI/e2e); **applicable
  but missing** ones (no e2e suite, no a11y tooling, no complexity linter)
  are findings, not silent skips.

## Run the pipeline (in order, fail-fast)

Run the dimensions from **`qa.md`'s Pipeline**, in order, using the repo's own
commands/scripts and pre-commit configs (that ordered list is the single
source — not restated here). Match each step to the change: a docs-only change
skips build/tests; a backend change runs its cycle.

Only the qa-check-specific operational notes (the rest is in `qa.md`):

- **Format + Lint via pre-commit** — when `.pre-commit-config.yaml` is
  present, drive these stages **through pre-commit** rather than invoking
  `shfmt`/`shellcheck`/etc. directly: run the fix config, then the check
  config (the config is the single source of truth for tool/version/flags —
  see *Prefer pre-commit Over Direct Tool Invocation* in `pre-commit.md`).
  Fall back to direct per-tool invocation only when pre-commit is not
  configured or the file is not covered by any hook.
- **Format** is the one auto-fix stage — run it once (the fix config), then
  the check-only pass; never fix-and-recommit per failure.
- **Documentation prep (generated changelog)** — if the repo's QA doc lists a
  changelog-regeneration command (a generate-then-commit prep action, same
  mutating class as Format), run it once when preparing the PR and commit the
  result; never in CI. Get the concrete command from the repo's QA doc.
- **Pre-commit hook coverage** — when the repo uses pre-commit, audit its
  config against the *Recommended Cross-Cutting Hooks* in `pre-commit.md`
  (secret detection, large-file / merge-conflict / case-conflict guards,
  exec-bit ↔ shebang consistency, …) and flag any that are missing but would
  fit the repo — the easy-to-forget, language-agnostic ones.
- **Code style audit** — beyond what Format/Lint catch, audit the change
  against `code-style.md` (plus any repo override in `.claude/`) for the
  conventions no tool enforces: naming, paragraph spacing, section/function
  separators, comment wrap/density, Rule of Three, efficiency by default.
  Report deviations as findings (see *Code style audit* in `qa.md`). Invoke
  the built-in `/code-review` (diff: bugs + cleanups) for the review pass and
  `/simplify` for cleanup-only — the dedicated commands for this.
- **Security** → defer to the **security-scan** skill (plus the built-in
  `/security-review` for a quick pending-changes vuln pass); **Build**'s image
  step → the **containerize** skill.
- **Whole-codebase dimension reviews** (an across-the-repo pass, not the diff)
  → route to the review skills: **arch-review** (code-smell/complexity/
  maintainability), **perf-review** (performance — measure-first),
  **test-review** (test-suite *quality*, distinct from the Tests step that
  *runs* them), **a11y-review** (UI/UX & accessibility — UI repos). They assess
  and report; they don't mutate. For Python depth invoke **pytest-patterns** /
  **typing-patterns**. Run these when the change (or the request) is about a
  dimension's health, not on every trivial diff.
- **CI** is the post-push stage — watch it to green; honour required checks.
- For a dimension with no tooling (UI/UX, e2e), do the manual pass and flag
  the gap rather than skipping it.
- Periodically audit coverage against **ISO/IEC 25010** (see `qa.md`).

## Report

Report **every** dimension with its **documented status** and this run's
outcome:

- **Active** → what ran (the actual command) and pass/fail.
- **Planned** → note it's not built yet, cite the TODO/ROADMAP item, and —
  when appropriate — **suggest concrete options for implementing it** (e.g.
  "add Playwright for e2e", "add axe for a11y", "adopt ruff for code-smell").
- **Off** → restate the documented reason (don't silently treat as pass).
- **N/A** → note it doesn't apply.
- **Undocumented** dimension → flag it as a QA-doc defect (per `qa.md`, every
  dimension needs a status) and propose the entry.

Back any optimization claim with before/after measurement, and flag premature
optimization, needless pessimization, and any **Code style audit** deviations
from `code-style.md`. Never report "all green" for a stage you did not run,
and never let a missing dimension pass unmentioned.
