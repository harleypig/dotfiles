---
name: bats-setup
description: Scaffold bats-core testing into a repository — create the tests/ layout (suite/helpers/scaffold), wire helper libraries via bats_load_library, install the meta-test generator, add a starter test, and set up CI. Use when a repo has no tests yet or an outdated test setup: "set up bats", "add tests to this repo", "scaffold bats testing", "get bats working here", "stand up a test suite", "add a test harness", or when porting another repo to this repo's bats conventions. Follows rules/bats.md.
---

# bats-setup

**Version:** v1.0.0

Stand up (or modernize) bats-core testing in a repo. This is the procedure;
**`rules/bats.md` is the source of truth** for conventions — read it first and
defer to it on any specifics.

## When to use

- A repo has no tests, or a stale/broken setup (e.g. a relative-`load`ed
  `global.bash`, a flat `tests/` with scaffolding mixed into tests).
- You want another repo to match these dotfiles' bats conventions.

## Steps

1. **Prerequisites.** Ensure bats + helper libs are available. Prefer the OS
   package: `sudo apt-get install -y bats bats-support bats-assert bats-file`
   (they install to `/usr/lib/bats`, bats's default `BATS_LIB_PATH`). For a lib
   with no OS package, justify it and clone pinned into a `BATS_LIB_PATH` entry.

2. **Create the layout** (actual tests separated from scaffolding):
   ```
   tests/
     helpers/common.bash
     scaffold/{build-meta-tests,templates/file.meta.bats.template,meta-ignore}
     suite/{.gitignore,test_<first>.bats}
   ```
   `tests/suite/.gitignore` holds `*.meta.bats` (generated tests are not
   committed).

3. **Helpers.** Drop in `tests/helpers/common.bash` with:
   - `load_bats_libs` — set `BATS_LIB_PATH` to `<repo>/lib/bats:` + the system
     default, then `bats_load_library` bats-support/assert/file (+ `bats-toolbox`
     if the machine provides it via the dotfiles).
   - `dotfiles_root` (or `repo_root`) — resolve the repo root from
     `${BASH_SOURCE[0]}`, not the test's depth.
   - `make_stub` / `make_stub_dir` — PATH-stub maker for faking docker/npx/etc.
   (Copy from this repo's `tests/helpers/common.bash` and adjust.)

4. **Meta-test generator.** Copy `tests/scaffold/build-meta-tests` and
   `templates/file.meta.bats.template`; set its default roots to the repo's
   script dirs (e.g. `bin lib`, or `src`). Generated `*.meta.bats` are
   gitignored and produced on demand / in CI.

5. **Starter test.** Write one real `tests/suite/test_<component>.bats`
   (`load ../helpers/common`; `setup()` calls `load_bats_libs`) so the suite is
   non-empty and the wiring is proven. Cover a success and a failure path.

6. **CI.** Add a workflow that installs bats + libs and runs
   `bats tests/suite/test_*.bats` (gate the hand-written suite). See this
   repo's `.github/workflows/tests.yml`. Optionally add the meta suite once the
   target scripts are clean.

7. **Verify.** `bats tests/suite/` is green; `shellcheck` the `.bats` files and
   `shfmt` the `.bash` helpers (shfmt cannot parse `.bats`). Run
   `tests/scaffold/build-meta-tests` and confirm it generates sane tests;
   record any lint/format debt it surfaces in `TODO.md` (don't ignore to hide).

## Notes

- `bats-toolbox` (this repo's first-class helper lib in `lib/bats`) is
  available in any repo on a machine whose dotfiles export `BATS_LIB_PATH`.
  In a repo meant to run elsewhere, either don't depend on it or vendor it.
- Do not recreate a relative-`load`ed `global.bash`; use `bats_load_library`
  and a small `helpers/common.bash`.
