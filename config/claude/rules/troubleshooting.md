---
# No paths — a failure can surface on ANY turn (a bug report, a failing
# test, unexpected behaviour mid-development), so the debugging discipline
# must be present whenever it's needed, not gated to a file type. Kept
# deliberately THIN: the bar lives here; the full procedure is the
# debug-assistant skill.
---

# Troubleshooting Rules

**Version:** v1.0.0

The discipline for diagnosing a failure — present on every turn because a bug
can surface at any moment (resolving a bug report, a red test, surprising
behaviour while building). This rule is the **thin guardrail**; the full
step-by-step procedure is the **`debug-assistant`** skill.

## The bar

When something is broken, the fix is not done until:

- **Reproduced first.** A bug you can't reproduce isn't fixed, it's hidden.
  Get a reliable (ideally minimal) repro before changing code.
- **Root cause, not symptom.** Fix *why* it broke, not the surface that
  showed it — and check whether the same cause hides elsewhere.
- **Regression-tested.** Land a test that **fails before the fix and passes
  after** (`testing.md`). That test is the proof, and the guard against
  recurrence.

And the method that gets you there: **read the actual error/stack/logs**
(don't guess), **change one thing at a time**, and reverting a failed
hypothesis is progress, not waste.

## Where the depth lives

- **`debug-assistant`** skill — the full session: reproduce → capture the
  evidence → isolate (bisect) → hypothesize-and-test → fix the root cause →
  regression-test → verify with `qa-check`.
- **`testing.md`** — the regression-test-per-bug bar (the fix's safety net).
- repo `.claude/` — how to run / reproduce / attach a debugger locally.

## Agent Behavior

- Reproduce before fixing; fix the root cause; land a regression test that
  failed before the fix. State it plainly if a bug can't be reproduced rather
  than guessing at a fix.
- Reach for the **`debug-assistant`** skill for a structured session, then
  re-run **`qa-check`** to confirm the fix broke nothing else.
