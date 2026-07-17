# ADR-0002: Scope of the Perl QA tooling — what to gate, skip, and defer

- **Status:** Accepted
- **Date:** 2026-07-16

## Context

Standing up Perl QA (`TODO.md` *Perl Setup*) named several candidate tools:
Test::Perl::Critic, Test::Pod, Test::Pod::Coverage, Devel::Cover, a standalone
Perl SAST, B::Lint, B::Deparse, Perl::Analyzer, and a possible perl-QA skill.
Not all fit this repo, which has exactly **two** Perl files — both **scripts**
(`bin/parse_params`, `bin/perltidyrc-clean`), package `main`, no Perl modules.
Some candidates duplicate the gate that already exists.

The gate is a **pinned, private docker image per tool** (perltidy, perlcritic),
run at pre-commit and in CI, with the curated **core-severity-4**
`config/perl/perlcriticrc` as the profile. The perlbrew-managed Perl
(`vmgr install perl`) carries the same tools for local development.

## Decision

- **perltidy + perlcritic — gated via docker images.** The pre-commit + CI
  docker hooks are the enforcement; deterministic (pinned core-only images).
- **Test::Pod — gated.** POD syntax is stable and cheap to check; it
  immediately caught a real bug (a non-ASCII em-dash with no `=encoding`).
- **Test::Perl::Critic — skip.** Running perlcritic in-process in the suite is
  redundant with the docker gate and **non-deterministic**: it uses whatever
  Perl::Critic policies are installed, so a dev machine loaded with third-party
  policy bundles fails where CI (core-only) passes. The core-only docker gate
  is deterministic and sufficient.
- **Test::Pod::Coverage — skip.** Pod::Coverage checks a package's public
  subs; the CLIs are package `main` with ~25 **private** helper subs and no
  module-style public API. Their interface is the CLI, documented in the
  OPTIONS POD. Coverage-checking every internal helper is inappropriate.
- **Devel::Cover — non-gating report.** A coverage-percentage threshold on two
  scripts is brittle; coverage is measured on demand (`TESTS.md`). A gating
  threshold is Planned.
- **Perl SAST (standalone) — decline.** Checkmarx was already declined
  (commercial, no free tier). The core perlcritic **security** policies (at
  severity 4+) cover the near-term; a standalone OSS Perl SAST adds little for
  two scripts. Revisit if the Perl surface grows or a running service appears
  (fold into the `security-scan` skill / `qa.md`).
- **B::Lint — decline for the gate.** Deprecated/limited; low marginal signal
  over perlcritic. An occasional manual aid at most.
- **B::Deparse — a technique, not a gate.** Useful to spot non-idiomatic
  constructs by comparing deparsed output; noted in the dotagents Perl rules,
  not wired as a check.
- **Perl::Analyzer — defer.** Call-graph / structure analysis is not worth it
  at two files. Revisit when the Perl surface grows.
- **A perl-QA skill — defer.** With one Perl setup and two files, the Rule of
  Three is not met; revisit if Perl work recurs (an agent-config decision, so
  the actual skill would live in the **dotagents** repo).

## Consequences

The Perl QA gate is lean and deterministic — docker perltidy + perlcritic plus
Test::Pod — with the heavier, redundant, or ill-fitting tools deliberately
out. Each "defer" is anchored to a concrete revisit trigger (the Perl surface
growing). These are reversible tooling-scope calls, recorded here so they are
not silently re-litigated when the Perl Setup TODO items are pruned.
