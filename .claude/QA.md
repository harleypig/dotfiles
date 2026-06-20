# Quality Assurance

**Version:** v1.0.0

## Purpose

This is the **repo-specific** QA doc for the dotfiles repository: the concrete
tools, commands, and a **per-dimension status** for every dimension in the
global `config/claude/rules/qa.md` pipeline. `qa.md` owns the dimensions,
their ordering, and the fix/check discipline (generic); this file records what
each dimension *is* here. The **qa-check** skill reads this doc for the
commands.

**Precedence:** `WORKFLOW.md` > `TESTS.md` > this file. Testing specifics live
in `TESTS.md`; pre-commit policy in `config/claude/rules/pre-commit.md`; this
file is the QA map that ties them to the global dimensions.

## How QA runs here

Two pre-commit configs (see `config/claude/rules/pre-commit.md`):

- **Fix** — `.pre-commit-config-fix.yaml` (auto-fixers; run once as prep):

  ```bash
  pre-commit run --all-files --config .pre-commit-config-fix.yaml
  ```

- **Check** — `.pre-commit-config.yaml` (read-only gate; commit + CI):

  ```bash
  pre-commit run --all-files
  ```

CI (`.github/workflows/tests.yml`) runs on push to `master`, on PRs, and on
manual dispatch: jobs **bats**, **perl**, **python**, **pre-commit**. The
`master` ruleset requires **bats + perl + pre-commit** green to merge
(squash-only).

## Dimension status

Every dimension from `qa.md`, with its status (**Active** / **Planned** +link
/ **Off** +reason / **N/A**):

| # | Dimension | Status | This repo |
|---|-----------|--------|-----------|
| 1 | Format | **Active** | `shfmt`, `yapf`, `isort`, `prettier`, `markdownlint-fix`, trailing-whitespace, end-of-file-fixer (fix config) |
| 2 | Lint | **Active** | `shellcheck`, `yamllint`, `markdownlint`, `flake8` (check config) |
| 3 | Type-check | **Off** | No typed source under active dev; Python `mypy`/`pyright` deferred to on-demand (`rules/python.md`). See TODO *pre-commit Phase 3*. |
| 4 | Code smell / complexity | **Off** | `shellcheck` catches some; no dedicated bash complexity tool. Acknowledged gap, no tracked owner yet. |
| 5 | Security | **Active (partial)** | Secrets: `gitleaks` + `detect-private-key` (commit-time check) **plus `trufflehog`** — PR-time *verified* scan in CI (`secret-scan.yml`, non-required for now). SCA / supply-chain: Dependabot alerts + version updates (`.github/dependabot.yml`). SAST: `semgrep` via the `security-scan` skill; **Checkmarx evaluated & declined** (commercial, no free tier — disproportionate). **`Snyk` & `CodeFactor` evaluated (2026-06-19) & not formalized** — both are hosted SaaS App checks that fail this repo's *worthwhile-results* bar (`security-scan` §4 escape hatch): no real dependency tree, so Snyk is a near-noise advisory check, and CodeFactor only re-runs ShellCheck/yamllint already gated locally. **Snyk dropped (uninstall the App); CodeFactor kept as a passive, non-required badge.** DAST: **N/A** (no running service). Deeper triage → `security-scan` skill. |
| 6 | Tests | **Active** | `bats tests/shell/test_*.bats` (gate), `prove tests/perl/`, `pytest tests/python` (self-activating). Layout/policy in `TESTS.md`. Suite *quality/coverage* (missing, outdated, brittle tests) → the **test-review** skill (qa.md dim 6), which `qa-check` composes. |
| 7 | UI/UX & accessibility | **N/A** | Headless dotfiles / CLI — no UI. |
| 8 | End-to-end | **N/A** | No application. Docker integration tests that bring up a real login shell / pwsh profile live under Tests (`TESTS.md`). |
| 9 | Compatibility | **N/A** | No external API / data-format contracts. Cross-shell (bash + PowerShell) and the docker context matrix are exercised under Tests. |
| 10 | Performance & load | **Off** | Not a service. Login-shell startup perf is handled ad hoc, measure-first (resolved — see `CHANGELOG.md`). |
| 11 | Reliability & observability | **N/A** | Not a deployed service. |
| 12 | Build | **N/A** | Nothing compiles / bundles. The test docker harness image is test infra, not a product artifact. |
| 13 | Documentation | **Active** | `markdownlint` (prose); inline-first doc philosophy (`WORKFLOW.md`); changelog is **hand-written** (`CHANGELOG.md`). `proselint` / link-validation **Planned** — TODO *Pre-commit Phase 4*. |
| 14 | Code review | **Active (solo)** | `master` ruleset requires a PR (no bypass) with review-thread resolution; **0 required approvals** (solo repo) — review is self-review. |
| 15 | CI | **Active** | `tests.yml` jobs bats / perl / python / pre-commit; required checks bats + perl + pre-commit gate merges. Watch via the `ship-pr` skill's `ci-watch`. |

## Optimization stance

Measure first (`qa.md`): no optimization without a baseline; premature
optimization is itself a smell. The login-shell perf work is the worked
example — each suspect module was profiled directly (non-DEBUG) before any
code changed (see `CHANGELOG.md`).

## Notes

- **Generated changelog: N/A.** `CHANGELOG.md` is maintained by hand at the
  merge-time finalization step (`WORKFLOW.md`; ship-pr Step 4.5), not
  generated from git history — so there is no regenerate-and-commit prep
  action in the QA pipeline.
- Deferred Perl QA (`perlcritic` / `perltidy`, commented in both pre-commit
  configs) is tracked under TODO *Perl quality tooling*.
- This doc must give **every** dimension a status; when a new dimension
  becomes relevant (e.g. a UI is added), update its row rather than leaving
  it silent.
