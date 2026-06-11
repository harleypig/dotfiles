---
# No paths — the testing quality bar applies whenever code is written.
---

# Testing Rules

**Version:** v2.0.0

What a change must satisfy for tests, and the stance on how to organize
them. This rule is deliberately **non-prescriptive** about *which* runner,
file pattern, or directory layout to use — that is the language's and the
repo's call (see *Where the specifics live*). `qa.md` owns the Tests
*pipeline* stage that runs them.

## The bar

- Code with real logic has tests. Cover **success and failure** paths.
- Each bug fix adds a regression test that fails before the fix.
- Never silence a failing test by ignoring it — fix the code, fix the
  test, or record the debt where the repo tracks it.

## Structure — be idiomatic

Organize tests the way the **language** they are written in expects, not to
a fixed cross-language template:

- **Single language** — follow that language's idiomatic test layout and
  runner conventions. The concrete pattern lives in that language's runner
  rule (e.g. `bats.md`).
- **Multiple languages** — keep the languages' tests from colliding. A
  single `tests/` root split into per-language subdirs is **one** sensible
  model (this repo: `tests/shell/`, `tests/python/`, …), but it is not the
  only one — other repos split differently when their own structure calls
  for it (e.g. tests living in per-component subdirectories). Choose what
  fits the repo; record the actual choice in its `.claude/TESTS.md`.

Keep shared, non-test support (helpers, generators) out of wherever the
per-language tests live.

## Where the specifics live

| Layer | Holds |
|-------|-------|
| This rule (`testing.md`) | the quality bar + the "be idiomatic" stance |
| Runner rules (`bats.md`, …) | each tool's invocation, file pattern, idioms |
| `qa.md` | the QA pipeline that *runs* the tests (Tests dimension) |
| repo `.claude/TESTS.md` | that repo's concrete layout, what it tests, coverage policy |

## Agent Behavior

- Add tests using the idiomatic layout and runner for the **language**,
  taking the concrete pattern from that language's runner rule and the
  repo's `.claude/TESTS.md` — do not impose a fixed structure the repo
  does not already use.
- Cover success **and** failure paths; add a regression test with each bug
  fix.
- Get a repo's concrete layout/policy from its `.claude/TESTS.md`, each
  runner's details from its rule, and pipeline/gating from `qa.md`.
