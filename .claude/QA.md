# Quality Assurance

**Version:** v1.1.0

## Purpose

This is the **repo-specific** QA doc for the dotfiles repository: the concrete
tools, commands, and a **per-dimension status** for every dimension in the
global QA pipeline (the dotagents repo's `rules/qa.md`). `qa.md` owns the
dimensions, their ordering, and the fix/check discipline (generic); this file
records what each dimension *is* here. The **qa-check** skill reads this doc
for the commands.

**Precedence:** `WORKFLOW.md` > `TESTS.md` > this file. Testing specifics live
in `TESTS.md`; pre-commit policy in the dotagents repo's
`rules/pre-commit.md`; this file is the QA map that ties them to the global
dimensions.

## How QA runs here

Two pre-commit configs (see the dotagents repo's `rules/pre-commit.md`):

- **Fix** — `.pre-commit-config-fix.yaml` (auto-fixers; run once as prep):

  ```bash
  pre-commit run --all-files --config .pre-commit-config-fix.yaml
  ```

- **Check** — `.pre-commit-config.yaml` (read-only gate; commit + CI):

  ```bash
  pre-commit run --all-files
  ```

CI (`.github/workflows/tests.yml`) runs on push to `master`, on PRs, and on
manual dispatch: jobs **bats**, **meta**, **perl**, **perl-compile**,
**python**, **pre-commit** (plus `publish-tool-images.yml` for the perl tool
images). The `master` ruleset requires **bats + meta + perl + perl-compile +
pre-commit** green to merge (squash-only).

## Dimension status

Every dimension from `qa.md`, with its status (**Active** / **Planned** +link
/ **Off** +reason / **N/A**):

| # | Dimension | Status | This repo |
|---|-----------|--------|-----------|
| 1 | Format | **Active** | `shfmt`, `yapf`, `isort`, `prettier`, `markdownlint-fix`, trailing-whitespace, end-of-file-fixer (fix config) |
| 2 | Lint | **Active** | `shellcheck`, `yamllint`, `markdownlint`, `flake8`; **Perl** `perltidy` + `perlcritic` (`--severity 4`, curated core-only `config/perl/perlcriticrc`) via pinned private ghcr **docker-image** pre-commit hooks (`ghcr.io/harleypig/{perltidy,perlcritic}`, `docker login` required — see `WORKFLOW.md`) |
| 3 | Type-check | **Off** | No type checker. `pyright` was removed when `config/claude/hooks` (its only typed surface) was extracted to the dotagents repo; the small remaining first-party Python (`bin/poetry2setup`, `tests/lint/prose_wrap.py`) is not type-checked. Revisit if a substantial typed Python surface returns. |
| 4 | Code smell / complexity | **Off** | `shellcheck` catches some; no dedicated bash complexity tool. Acknowledged gap, no tracked owner yet. |
| 5 | Security | **Active (partial)** | Secrets: `gitleaks` + `detect-private-key` (commit-time check) **plus `trufflehog`** — PR-time *verified* scan in CI (`secret-scan.yml`, non-required for now). SCA / supply-chain: Dependabot alerts + version updates (`.github/dependabot.yml`). SAST: `semgrep` via the `security-scan` skill; **Checkmarx evaluated & declined** (commercial, no free tier — disproportionate). **`Snyk` & `CodeFactor` evaluated (2026-06-19) & not formalized** — both are hosted SaaS App checks that fail this repo's *worthwhile-results* bar (`security-scan` §4 escape hatch): no real dependency tree, so Snyk is a near-noise advisory check, and CodeFactor only re-runs ShellCheck/yamllint already gated locally. **Snyk dropped (uninstall the App); CodeFactor kept as a passive, non-required badge.** DAST: **N/A** (no running service). Deeper triage → `security-scan` skill. |
| 6 | Tests | **Active** | `bats tests/shell/test_*.bats` (gate), `prove tests/perl/` (incl. `pod-syntax.t` — Test::Pod), `pytest tests/python` (self-activating). **Perl coverage** (Devel::Cover) is a non-gating on-demand report (`TESTS.md`); a gating threshold is **Planned**. Layout/policy in `TESTS.md`. Suite *quality/coverage* → the **test-review** skill (qa.md dim 6), which `qa-check` composes. |
| 7 | UI/UX & accessibility | **N/A** | Headless dotfiles / CLI — no UI. |
| 8 | End-to-end | **N/A** | No application. Docker integration tests that bring up a real login shell / pwsh profile live under Tests (`TESTS.md`). |
| 9 | Compatibility | **N/A** | No external API / data-format contracts. Cross-shell (bash + PowerShell) and the docker context matrix are exercised under Tests. |
| 10 | Performance & load | **Off** | Not a service. Login-shell startup perf is handled ad hoc, measure-first (resolved — see `CHANGELOG.md`). |
| 11 | Reliability & observability | **N/A** | Not a deployed service. |
| 12 | Build | **N/A** | Nothing compiles / bundles. The test docker harness image is test infra, not a product artifact. |
| 13 | Documentation | **Active** | `markdownlint` (prose); inline-first doc philosophy (`WORKFLOW.md`); changelog is **hand-written** (`CHANGELOG.md`). `Vale` (prose; chosen over proselint) / link-validation **Planned** — TODO *Pre-commit Phase 4*. |
| 14 | Code review | **Active (solo)** | `master` ruleset requires a PR (no bypass) with review-thread resolution; **0 required approvals** (solo repo) — review is self-review. |
| 15 | CI | **Active** | `tests.yml` jobs bats / meta / perl / perl-compile / python / pre-commit (+ `publish-tool-images.yml`); required checks **bats + meta + perl + perl-compile + pre-commit** gate merges. `perl-compile` builds a real pinned Perl only when a PR touches the perl toolchain (else early-green). Watch via the `push-pr` skill's `ci-watch`. |

## Optimization stance

Measure first (`qa.md`): no optimization without a baseline; premature
optimization is itself a smell. The login-shell perf work is the worked
example — each suspect module was profiled directly (non-DEBUG) before any
code changed (see `CHANGELOG.md`).

## Notes

- **Generated changelog: N/A.** `CHANGELOG.md` is maintained by hand at the
  merge-time finalization step (`WORKFLOW.md`; push-pr Step 4.5), not
  generated from git history — so there is no regenerate-and-commit prep
  action in the QA pipeline.
- **Perl QA is Active** — `perltidy` + `perlcritic` gate via pinned private
  ghcr docker-image pre-commit hooks (dim 2), `Test::Pod` + non-gating
  Devel::Cover coverage in the suite (dim 6). Tooling *scope* decisions (what
  was skipped/declined/deferred: Test::Perl::Critic, Test::Pod::Coverage, perl
  SAST, B::Lint, B::Deparse, Perl::Analyzer, a perl-QA skill) are recorded in
  [ADR-0002](../docs/adr/0002-perl-qa-tooling-scope.md). The remaining perl
  work (perlcritic severity ratchet, combined tool image) is in `TODO.md`.
- This doc must give **every** dimension a status; when a new dimension
  becomes relevant (e.g. a UI is added), update its row rather than leaving
  it silent.
