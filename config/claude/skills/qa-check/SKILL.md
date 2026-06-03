---
name: qa-check
description: Run the full quality-assurance pipeline on a change — format, lint, type-check, code-smell, security, tests, UI/UX, end-to-end, build, CI — using the current repo's own QA doc for the concrete commands and the global qa.md for the dimensions/discipline. Use whenever the user wants to validate quality or readiness: "run QA", "qa check", "quality check", "is this ready to merge/PR", "run the checks", "lint and test this", "verify this change", "check everything passes", or before opening/finishing a PR. Composes the containerize skill (images) and security-scan skill (SAST/deps).
---

# QA Check

**Version:** v2.0.0

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

Use the repo's own commands/scripts and pre-commit configs. Match each step
to the change (docs-only skips build/tests; a backend change runs its cycle):

1. **Format** (auto-fix, once) → 2. **Lint** → 3. **Type-check** →
4. **Code smell** → 5. **Security** (SAST/SCA/DAST/IaC/secrets — defer to
**security-scan**) → 6. **Tests** (success + failure paths) →
7. **UI/UX + a11y** (manual visual/keyboard check if no tooling) →
8. **End-to-end** (run the suite if present; else check the critical flow
   manually and flag the gap) → 9. **Compatibility** (the targets the product
   claims; N/A if single-target) → 10. **Performance & load** (where it
   matters) → 11. **Reliability & observability** (often runtime/out-of-gate —
   status it) → 12. **Build** (compile/bundle; image build via
   **containerize** when containers changed) → 13. **Code review** (human
   gate) → 14. **CI** (after pushing, watch CI to green; honour required
   checks and the fix→check discipline).

Periodically audit coverage against the **ISO/IEC 25010** characteristics
(see `qa.md`) — a characteristic with no assuring activity is a candidate gap.

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
optimization or non-idiomatic code. Never report "all green" for a stage you
did not run, and never let a missing dimension pass unmentioned.
