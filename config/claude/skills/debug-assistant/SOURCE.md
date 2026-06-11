# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source; the implementation is our own (house style, the
scientific-method procedure, the troubleshooting.md composition).

## Idea source (NOT tracked)

Recorded in `../../audit/mining/claude-tools.md`:

- `rafaelkamimura/claude-tools` `debug-assistant` — structured debugging
  harness (stack-trace → reproduce → fix). MIT.

## Local design decisions

- **Serves `troubleshooting.md`** (the thin always-on bar) rather than
  restating policy — the skill is the *how*, the rule is the *what/why* (DRY).
- **Scientific method, reproduce-first** — no fix without a reliable repro;
  isolate by bisection; one falsifiable hypothesis at a time; root cause over
  symptom, with a grep for sibling occurrences.
- **Locks the fix with a regression test** (`testing.md`) and **verifies with
  `qa-check`** — the fix isn't done until the bar holds.
- **Boundaries drawn** — whole-codebase health → `arch-review`; "it's slow" →
  `perf-review`; ops/incident response → a future `devops-troubleshooter`.
- **Composed by the planned `resolve-issue` skill** as its investigation step
  (the `gh` issue-resolution flow).
- The Tier-1 build that **opens the `troubleshooting` category**.
