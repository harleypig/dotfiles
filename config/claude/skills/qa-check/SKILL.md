---
name: qa-check
description: Run the full quality-assurance pipeline on a change — format, lint, type-check, code-smell, security scan, tests, UI/UX, end-to-end, build, CI — routing through the QA rules so they actually get consulted. Use whenever the user wants to validate quality or readiness: "run QA", "qa check", "quality check", "is this ready to merge/PR", "run the checks", "lint and test this", "verify this change", "check everything passes", or before opening/finishing a PR. Composes the containerize skill (images) and security-scan skill (SAST/deps) rather than duplicating them.
---

# QA Check

**Version:** v1.0.0

Run the quality-assurance pipeline and route every stage through its rule.
QA spans many tools that are individually easy to forget; this skill is the
forcing function that runs them **in concert and in order**. It orchestrates;
the rules are the source of truth.

## Read first

- **`rules/qa.md`** — the pipeline definition (stages, order, fix/check
  discipline, the idioms + optimization stance, and the routing table).
- The repo's **`CONVENTIONS.md` / `WORKFLOW.md` / `TESTS.md`** — the concrete
  commands and required checks for *this* repo (these win over general
  habits).

## Scope to the repo

Detect what exists, then run only those stages — and **name the gaps**:

- Languages present (`*.py`, `*.ts/tsx`, `*.sh`, …) → their format/lint/type
  tools.
- Test runners (`pytest`, `vitest`), a security setup (semgrep/trivy/
  dependabot), Dockerfiles, CI workflows.
- **Absent dimensions are findings, not skips** — no e2e suite, no a11y
  tooling, no complexity linter → report them.

## Run the pipeline (in order, fail-fast)

Prefer the repo's own scripts / pre-commit configs. Match each step to the
change (a docs-only change skips build/tests; a backend change runs the
Python cycle):

1. **Format** (auto-fix, once) → 2. **Lint** → 3. **Type-check** →
4. **Code smell** (linter smell rules + semgrep; note if no dedicated tool) →
5. **Security** (defer to the **security-scan** skill) →
6. **Tests** (success + failure paths) →
7. **UI/UX + a11y** (manual visual/keyboard check if no tooling — still do it) →
8. **End-to-end** (run the suite if present; else check the critical flow
   manually and flag the gap) →
9. **Build** (compile/bundle; image build via the **containerize** skill when
   containers changed) →
10. **CI** (after pushing, watch GitHub Actions to green; honour required
    checks and the pre-commit fix→check discipline).

## Report

A per-stage summary: what ran, pass/fail, and — explicitly — which dimensions
were **skipped because the repo lacks them** (e2e, a11y, complexity). Note any
optimization claims must be backed by before/after measurement, and flag
premature optimization or non-idiomatic code as QA findings. Never report
"all green" for a stage you did not run.
