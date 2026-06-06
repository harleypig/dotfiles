---
paths:
  - "tests/**/*.bats"
  - "tests/helpers/**"
  - "tests/scaffold/**"
  - "lib/bats/**"
---

# bats (Bash Automated Testing System) Rules

**Version:** v2.0.0

Conventions for testing shell code with **bats-core**. Pairs with `bash.md`,
`shellcheck.md`, and `shfmt.md`; the QA pipeline lives in `qa.md`.

## Detection

Active when a repo has `*.bats` files or a `tests/` directory with bats tests.

## Framework

- Use **bats-core** (the maintained community fork; the original
  `sstephenson/bats` was archived in 2021). Install from the OS package where
  possible (`apt install bats`); it targets bash 3.2+.
- A test file is `#!/usr/bin/env bats` with `@test "name" { ... }` blocks.
  `setup`/`teardown` run per test; `setup_file`/`teardown_file` once per file;
  `setup_suite`/`teardown_suite` (in `setup_suite.bash`) once per run.

## Helper libraries

The standard helpers live under the `bats-core` org and are **separate** from
bats: `bats-support` (plumbing), `bats-assert` (`assert_success`,
`assert_output`, `assert_equal`, `assert_line`, `--partial`, `--regexp`),
`bats-file` (`assert_file_exist`, `assert_dir_exists`, …).

**Install policy — prefer the OS package.** On Debian/Ubuntu install
`bats-support bats-assert bats-file` via `apt`; they land in `/usr/lib/bats`,
which is bats's default `BATS_LIB_PATH`, so `bats_load_library` resolves them
with no configuration. Only when a needed lib has **no** OS package is a
fallback justified: clone it (pinned) into a `BATS_LIB_PATH` entry (e.g. under
`$XDG_DATA_HOME`), and say why at the call site.

**Load with `bats_load_library`, not relative `load`.** `bats_load_library`
searches `BATS_LIB_PATH` (a standard colon-separated path, first match wins),
decoupling tests from where the libs are installed:

```bash
bats_load_library bats-support
bats_load_library bats-assert
bats_load_library bats-file
```

For CI, `bats-core/bats-action` installs bats + all libs and exports
`BATS_LIB_PATH`; or just `apt install` them on an Ubuntu runner.

## First-class custom helper lib

Project- or user-specific helpers belong in their own loadable library, not a
relative-`load`ed `global.bash`. In these dotfiles that is **`bats-toolbox`**
(`lib/bats/bats-toolbox/load.bash`: `note`, `random_string`,
`setup_temp_dir`/`cleanup_temp_dir`, `run_with_options`, `run_pipe`).
`shell-startup` puts `$DOTFILES/lib/bats` ahead of the system dir on
`BATS_LIB_PATH`, so any repo on the machine can `bats_load_library
bats-toolbox`.

A loadable lib is sourced inside `setup()` — i.e. **after** bats has already
fired `setup_file`/`setup_suite`. Do not define those hooks in a lib; they
would be no-ops. Ship plain functions and let consumers wire their own setup.

## Layout

Keep the **actual tests** in a subdirectory, separate from scaffolding:

```
tests/
  helpers/common.bash      # shared support (loaded via `load ../helpers/common`)
  scaffold/                # test-generation machinery
    build-meta-tests
    templates/
  suite/                   # the actual tests
    test_*.bats            # hand-written (committed)
    *.meta.bats            # generated (gitignored)
```

| Pattern | Purpose |
|---------|---------|
| `tests/suite/test_<component>.bats` | Hand-written unit tests (committed) |
| `tests/suite/test_integration_<feature>.bats` | Integration tests |
| `tests/suite/<dir>-<name>.meta.bats` | Generated static checks (gitignored) |
| `tests/helpers/<name>.bash` | Shared helper functions |

Resolve the repo root from a helper's own `${BASH_SOURCE[0]}` (not the test's
depth) so tests can move between subdirs.

## Invocation

```bash
bats tests/suite/             # everything present (hand-written + generated)
bats tests/suite/test_*.bats           # hand-written only (the CI gate)
bats tests/suite/test_foo.bats         # one file
bats --filter "pattern" tests/suite/   # matching tests only
```

## Writing tests

- `load ../helpers/common`; have `setup()` call a `load_bats_libs` helper that
  sets `BATS_LIB_PATH` (repo `lib/bats` + system) and loads the libs.
- Use `run cmd` then `assert_success` / `assert_failure N` /
  `assert_output [--partial|--regexp]` for exit-code and output checks.
- For array/nameref assertions (a function that appends to a caller array),
  call the function **directly** (not via `run`, which subshells and loses the
  mutation) and assert on the array.
- **Stub external commands** you don't want to really run (docker, npx, curl):
  put a fake on `PATH` ahead of the real one that records its args to a file,
  then assert on that file — tests how a script *would* invoke the command
  without it. See `tests/helpers/common.bash` `make_stub`.
- Keep tests runnable without external services where feasible; `skip` with a
  reason when a precondition (a real daemon, a specific host) is absent.

## Linting test files

- **shellcheck parses `.bats`** (it understands `@test`); run it on the test
  files and the `.bash` helpers/libs — no findings permitted (`shellcheck.md`).
- **shfmt does NOT parse `.bats`** (`@test` is not valid sh). Do not run shfmt
  on `.bats`; do run it on `.bash` helpers and libraries (`shfmt.md`).
- A sourced lib whose variables are read by code shellcheck can't see may trip
  SC2034 — use the inline `VAR=val cmd` form (reads as "used") rather than
  `export`, which then trips SC2030/SC2031 in a `@test` subshell.

## Meta-test generator

`tests/scaffold/build-meta-tests` generates one static-check test per shell
script (exists, shebang, `bash -n`, shellcheck, shfmt) from
`templates/file.meta.bats.template`:

- It scans configurable roots (default `bin lib`), skips symlinks (so a
  multi-call dispatcher is tested once, its tool symlinks are not), and writes
  gitignored `<dir>-<name>.meta.bats` into `tests/suite/`.
- `tests/scaffold/meta-ignore` lists repo-relative paths to skip. Do **not**
  ignore a file just to hide debt — fix it or record the debt in `TODO.md`.
- Regenerate after adding/removing scripts: `tests/scaffold/build-meta-tests`.

## CI and pre-commit

- CI installs bats + libs and runs the suite (`.github/workflows/tests.yml`).
  Gate the hand-written suite; add the meta suite once its target scripts are
  clean.
- Pre-commit: a check-only local hook running `bats tests/suite/test_*.bats`
  is appropriate; there is no fix variant.

## Agent Behavior

- New shell code gets bats tests in `tests/suite/`, named
  `test_<component>.bats`, loading helpers via `load ../helpers/common`,
  covering success and failure paths. Bug fixes include a regression test.
- Load helper libs with `bats_load_library` (OS package first); never add a
  relative-`load`ed `global.bash`.
- After writing/modifying tests, run the specific file, then
  `bats tests/suite/test_*.bats`; run `shellcheck` on the `.bats` files and
  `shfmt` on the `.bash` ones. Reserve the full suite for CI in general use.
- Regenerate meta tests after adding or removing scripts; record any lint/
  format debt the meta suite surfaces in `TODO.md` rather than ignoring it.
- To scaffold bats into a repo that lacks it, use the **bats-setup** skill.
