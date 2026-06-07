# Testing Rules

**Version:** v1.0.0

Language-agnostic conventions for **organizing and running** a repo's tests.
Interlinked with `qa.md` but deliberately separate: this rule is about
*test-suite structure*; `qa.md` is about the *QA pipeline* that runs them.
Each runner's specifics live in its own rule (`bats.md`, `vitest.md`, …).

## Detection

Active when a repo has a `tests/` directory (or equivalent test files).

## One test root, organized by language

Keep all tests under a single `tests/` root, split into per-language
subdirectories. The runners coexist because each discovers only its own file
pattern — `pytest` ignores `.bats`/`.t`/`.ps1`, `bats` runs only `.bats`,
`prove` only `.t`, Pester only `*.Tests.ps1`:

| Language   | Subdir              | Files         | Runner                   |
|------------|---------------------|---------------|--------------------------|
| shell      | `tests/shell/`      | `*.bats`      | `bats` (see `bats.md`)   |
| python     | `tests/python/`     | `test_*.py`   | `pytest`                 |
| perl       | `tests/perl/`       | `*.t`         | `prove`                  |
| powershell | `tests/powershell/` | `*.Tests.ps1` | `Invoke-Pester` (Pester) |

A repo only needs subdirs for the languages it actually has. Shared, non-test
support lives alongside, never mixed into the per-language dirs:

- `tests/helpers/` — shared test support (helpers loaded by tests).
- `tests/scaffold/` — test-generation machinery (e.g. a meta-test generator).

This consolidates what some ecosystems split out — perl's `t/`, pytest's
`tests/` — into one root with language subdirs. `t/` is only *required* by
perl's CPAN/dist build tooling; a repo that runs `prove` by hand can use
`tests/perl/`.

## Naming

- Hand-written: `test_<component>` in the language's extension
  (`test_foo.bats`, `test_foo.py`); perl uses `<component>-<case>.t`; Pester
  `<X>.Tests.ps1`.
- Generated (e.g. meta-tests): a distinct suffix (e.g. `*.meta.bats`),
  **gitignored** and produced on demand / in CI rather than committed.
- Cover success **and** failure paths; add a regression test with each bug
  fix (see `qa.md`).

## Running

Point each runner at its subdir:

```bash
bats tests/shell
pytest tests/python
prove tests/perl
pwsh -c 'Invoke-Pester tests/powershell'
```

CI runs each applicable runner over its subdir; add a language's CI step when
that subdir gains tests.

## Where the specifics live

| Layer | Holds |
|-------|-------|
| This rule (`testing.md`) | the cross-language structure + conventions |
| Runner rules (`bats.md`, `vitest.md`, …) | each tool's invocation, helper libs, idioms |
| `qa.md` | the QA pipeline that *runs* the tests (Tests dimension) |
| repo `.claude/TESTS.md` | that repo's concrete layout, what it tests, coverage policy |

## Agent Behavior

- Put new tests under `tests/<language>/`, named per the convention; do not
  scatter tests across ad-hoc directories or mix languages in one subdir.
- Keep scaffolding/helpers out of the per-language test dirs.
- Get a repo's concrete layout/policy from its `.claude/TESTS.md`, each
  runner's details from its rule, and pipeline/gating from `qa.md`.
