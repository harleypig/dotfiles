---
name: test-review
description: Assess the quality and coverage of a test suite — does it cover success AND failure paths, is there a regression test per past bug, are tests well-structured (arrange-act-assert, intent-revealing names) and not brittle/over-mocked, what edge cases are missing. Use for "review the tests", "are these tests any good", "test coverage gaps", "is this well tested", "what's missing from the test suite". The tool for qa.md's Tests dimension (quality, not execution). Distinct from qa-check (runs the tests) and /code-review (reviews a diff).
---

# test-review

**Version:** v1.0.0

Assess a **test suite's quality and coverage** — not whether it passes
(`qa-check` runs it), but whether it's *worth* passing. Subject-agnostic; the
bar comes from `testing.md`.

## What it checks (the bar is `testing.md`)

- **Success *and* failure paths** — the headline gap. A suite that only
  asserts the happy path is half a suite; flag every behavior whose
  failure/error path is untested.
- **Regression coverage** — does each past bug fix have a test that would fail
  without the fix? Name behaviors with no guarding test.
- **Structure** — arrange-act-assert clarity, one behavior per test,
  intent-revealing names (`code-style.md`). A test you can't read won't be
  trusted or maintained.
- **Brittleness** — over-mocking (tests that assert implementation, not
  behavior), order-dependence, hidden shared state, time/randomness not
  pinned, assertions too loose (or too tight to refactor through).
- **Edge cases** — empty/large/boundary inputs, concurrency, partial failure —
  the cases real bugs hide in.

## Type / agent use

A **skill** you invoke. For a large suite, delegate the read to a **subagent**
that maps tests → behaviors-covered and returns the gaps, keeping the file-by-
file reading out of this conversation.

## Output

```markdown
## Test review — <scope>

**Coverage take:** <one line — biggest gap, usually failure paths>

### Untested failure paths
- `subject` — <the error/edge behavior with no test>

### Missing regression tests
- <past bug / risky behavior> — no guarding test

### Quality issues
- `test` — <brittle/over-mocked/unclear> → <fix>
```

Prioritize **untested failure paths and missing regressions** — they're where
real defects slip through. **Assess only**; writing the missing tests is a
separate step (use the repo's runner / `bats-setup` etc.). Don't report a raw
coverage % as if it were quality — a 90%-happy-path suite is worse than it
looks.

## Provenance

Adapted (idea-level) from the mining census — `claude-plugins` python
`test-reviewer` (coverage + AAA/quality analysis). No upstream code reused.
See `SOURCE.md`.
