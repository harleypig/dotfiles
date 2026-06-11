---
name: debug-assistant
description: Run a structured debugging session on a specific failure — reproduce it, capture the real evidence (stack/logs), isolate the cause by bisection, test one hypothesis at a time, fix the root cause, and lock it with a regression test. Use for "debug this", "why is this failing", "this test is flaky", "track down this bug", "this error", "it crashes when", "find the root cause", or resolving a bug report. Subject-agnostic scientific method. Serves troubleshooting.md (the bar); composes testing.md (regression test) and qa-check (verify). troubleshooting.
---

# debug-assistant

**Version:** v1.0.0

The procedure that turns "it's broken" into a root-cause fix locked by a
regression test — by **scientific method**, not by guessing-and-patching. The
discipline it serves (reproduce-first, root-cause, regression-test) lives in
`troubleshooting.md`; this skill is the *how*.

## When to reach for it

A specific failure to diagnose: a failing or flaky test, a crash or
exception, a bug report, or surprising behaviour you need to track to its
cause. This is the **investigation** step inside a bug-report resolution (the
planned `resolve-issue` skill composes it).

## Type / composition

A **skill** (a diagnostic procedure you invoke and watch). It serves
`troubleshooting.md` (the bar) and composes `testing.md` (the regression-test
bar) and `qa-check` (post-fix verification). For a large or unfamiliar
codebase, fan the investigation read-out to a **read-only agent** (isolation,
generic-in-subject) so tracing doesn't consume the main context. If the bug
exposes a structural problem, hand off to `arch-review` / `modernize`.

## Boundaries — what this is *not*

- **Not whole-codebase health.** "Is this codebase healthy / where's the
  rot" → `arch-review`.
- **Not "it's slow."** A performance problem → `perf-review` (measure-first).
  This skill is for **incorrect behaviour**.
- **Not ops/incident response** on running infrastructure (log fleets, deploy
  rollbacks) → a future `devops-troubleshooter`, built on first need.

## Procedure (scientific method)

1. **Reproduce.** Get a reliable repro — the **smallest** input/steps that
   trigger it. Can't reproduce? Gather signal first (exact version, env,
   inputs, full logs); **do not fix what you can't reproduce** — say so and
   ask for what's missing.
2. **Capture the evidence.** Read the **actual** error, stack trace, and logs
   — never infer the failure from the description. Pin the exact failure point
   and the expected-vs-actual.
3. **Isolate.** Narrow to the smallest failing surface by **bisection** —
   `git bisect` across history, or binary-search the input / comment-out
   regions — not scattershot edits. Separate the **trigger** from the **root
   cause**.
4. **Hypothesize, one at a time.** State a **falsifiable** hypothesis about
   the cause, test it with a **single** change, and revert it if wrong before
   trying the next. One variable per step.
5. **Fix the root cause.** Address *why* it broke, not the symptom, and grep
   for the **same cause elsewhere** (sibling bugs from one root).
6. **Regression-test.** Add a test that **fails before the fix, passes
   after** (`testing.md`). That test is the proof the cause is understood.
7. **Verify + record.** Re-run **`qa-check`** to confirm nothing else broke;
   note the root cause and fix in the commit/changelog, and an `adr` if it
   changed a decision.

## Output

The root-cause fix plus its regression test, and a short **root-cause note**:
what failed, why (the actual cause, not the symptom), how it's fixed, and what
the regression test pins. If the cause can't be found or reproduced, report
the dead end and the evidence gathered rather than shipping a guess.

## Provenance

Adapted (idea-level) from the mining census — `claude-tools` `debug-assistant`
(structured stack-trace → repro → fix harness). No upstream code reused. See
`SOURCE.md`.
