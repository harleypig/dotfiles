# Testing Strategy

**Version:** v2.5.0

## Purpose

This document is the **repo-specific** testing strategy for the dotfiles
repository: what we test, where it lives, how to run it, and the coverage
policy. It is deliberately thin.

**bats conventions are not repeated here.** The framework, helper-library
install/loading (`bats_load_library` + `BATS_LIB_PATH`), the `bats-toolbox`
helper lib, file naming, how to write tests and stub externals, linting
`.bats`, and the meta-test generator all live in the global rule
**`config/claude/rules/bats.md`** — read that first. This file only covers
what is specific to this repo.

For general workflow see `WORKFLOW.md`.

**Precedence:** `TESTS.md` > `WORKFLOW.md` > `CLAUDE.md`. Where this repo's
testing needs differ from `rules/bats.md`, this file wins for this repo;
otherwise the rule applies.

## Layout (this repo)

One `tests/` root with per-language subdirs (see
`config/claude/rules/testing.md` for the general convention):

```text
tests/
  helpers/common.bash   # shared bash/bats support (load_bats_libs, dotfiles_root, make_stub, docker harness)
  scaffold/             # meta-test generator + templates (build-meta-tests)
  docker/               # integration-test harness image (Dockerfile, entrypoint)
  shell/                # bats: *.bats hand-written, *_integration_*.bats, *.meta.bats (generated, gitignored)
  python/               # pytest: test_*.py
  perl/                 # prove: *.t
  powershell/           # Pester: *.Tests.ps1
```

bats helper libs come from the Debian packages (`bats bats-support
bats-assert bats-file`); `tests/helpers/common.bash` adds this repo's
`lib/bats` (`bats-toolbox`) to `BATS_LIB_PATH`.

## Docker integration harness

Tests that must exercise the *running* dotfiles (a real login shell, or a
script with side effects like `check-dotfiles`'s `ln -fs` into `$HOME`) use a
throwaway container as a sandbox — a mistake there can never touch the host.

- `tests/docker/` — the harness image (Debian slim + bash/git/gettext/less +
  the `en_US.UTF-8` locale). The repo under test is mounted **read-only** at
  `/dotfiles` at run time, so tests exercise the current checkout. The default
  entrypoint deploys `~/.bash_profile`/`~/.bashrc` → `shell-startup` and runs a
  login shell; tests needing a pristine `HOME` override the entrypoint.
- `tests/helpers/common.bash` provides `dotfiles_harness_image` (builds the
  image, cached; **skips** the test when docker is unavailable or the build
  fails) and `dotfiles_login`.
- `tests/shell/test_integration_*.bats` — e.g. `test_integration_startup`
  (login shell comes up with `DOTFILES`/XDG/PATH, double-source guard,
  cleanpath dedup) and `test_integration_check_dotfiles`.
- `tests/shell/test_integration_powershell.bats` — drives the **stock**
  `mcr.microsoft.com/powershell` image directly (no custom Dockerfile):
  deploys `ps-startup.ps1` as the pwsh profile, runs `pwsh -File`, and asserts
  the profile comes up (`DOTFILES` set, `powershell/startup/*` modules loaded)
  with no parser errors. Same skip-if-no-docker guard.

These run wherever docker exists (CI, dev) and skip otherwise, so they sit in
the same gating suite without breaking docker-less environments.

## What must be tested here

- Every new script in `bin/` and every function in `lib/` gets a
  `tests/shell/test_<name>.bats` covering a **success and a failure** path.
- Bug fixes get a regression test that fails before the fix.
- `config/shell-startup/` modules that contain real logic get an integration
  test that sources them and asserts the resulting environment.
- Multi-call dispatchers (e.g. `bin/docker_wrapper`) are tested once at the
  real file; their tool symlinks are not (the generator skips symlinks).
  Their symlink-vs-registry *consistency* is guarded separately —
  `test_docker_wrapper_links.bats` asserts every tool from `docker_wrapper
  --known-tools` has a matching `bin/<tool>` symlink (by `readlink` target,
  not contents) and that no stray wrapper symlink exists; `bin/docker_wrapper-links
  --fix` repairs missing links.
- Repo-structure invariants get a guard test too: `test_skill_frontmatter.bats`
  holds every `config/claude/skills/*/SKILL.md` to the Agent Skills
  open-standard frontmatter rules (see `config/claude/EXTENDING.md` Skill ›
  *Format*), `test_rule_frontmatter.bats` holds every
  `config/claude/rules/*.md` to declaring its load tier — a `paths:` key or a
  `# No paths — <why>` comment — so a rule can't silently join the always-on
  per-turn tier by omission (see `config/claude/rule-TEMPLATE.md`) — and
  `test_docker_wrapper_links.bats` (above) holds the docker_wrapper symlinks
  to its registry.

## Coverage priorities (incremental)

1. Critical scripts (anything that can lose data or break the shell).
2. Core libraries used by multiple components (`lib/*`).
3. Complex logic (parsing, loops, conditionals, dispatch).
4. Simple wrappers (lowest priority).

The generated **meta suite** runs language-specific static checks per file:
bash/sh → shebang + `bash -n` + shellcheck + shfmt; perl → shebang +
`perl -c`; python → shebang + `compile()`. It scans `bin lib` **plus
`config/claude/skills`** (the last covers skill helper scripts such as
`config/claude/skills/*/scripts/*`, e.g. `ship-pr`'s `ship.sh`; non-script
files are skipped). It currently surfaces pre-existing debt (legacy bash
lint/format + one perl module dependency) — tracked in `TODO.md`
("Lint/format Debt in Legacy Scripts"), not ignored and not auto-fixed. Until
those are clean, only the hand-written suite is gated.

## Running

```bash
bats tests/shell/test_*.bats      # hand-written suite (the gate)
bats tests/shell/                 # everything present (incl. generated meta)
tests/scaffold/build-meta-tests   # (re)generate the meta tests first
```

Run a single file or filter while iterating; reserve the full suite for
pre-commit / CI.

## CI

`.github/workflows/tests.yml` runs three jobs on pushes to `master` and on
PRs: **bats** (`tests/shell/test_*.bats`, the gate), **perl**
(`prove tests/perl/`, installing `libtest-cmd-perl` + `perltidy`; **non-gating
for now** via `continue-on-error`, pending a Perl::Tidy version-robustness fix
— see `TODO.md`), and **python** (`pytest tests/python`, self-activating once
`tests/python/test_*.py` exist). The generated meta suite is **not** gated yet
(see the debt note above); add it once its target scripts pass.

## Test development

- TDD is encouraged: write the failing test, implement, make it green, then
  run the suite.
- After adding or removing scripts, regenerate the meta tests
  (`tests/scaffold/build-meta-tests`) and review what it surfaces.
- Never silence a failing test by ignoring it; fix the code, fix the test, or
  record the debt in `TODO.md`.

## Questions

- Test structure (all languages) → `config/claude/rules/testing.md`
- bats how-to → `config/claude/rules/bats.md`
- General workflow → `WORKFLOW.md`
- Examples → `tests/shell/`
