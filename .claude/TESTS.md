# Testing Strategy

**Version:** v2.6.7

## Purpose

This document is the **repo-specific** testing strategy for the dotfiles
repository: what we test, where it lives, how to run it, and the coverage
policy. It is deliberately thin.

**bats conventions are not repeated here.** The framework, helper-library
install/loading (`bats_load_library` + `BATS_LIB_PATH`), the `bats-toolbox`
helper lib, file naming, how to write tests and stub externals, linting
`.bats`, and the meta-test generator all live in the global rule
**the dotagents repo's `rules/bats.md`** — read that first. This file only
covers what is specific to this repo.

For general workflow see `WORKFLOW.md`.

**Precedence:** `TESTS.md` > `WORKFLOW.md` > `CLAUDE.md`. Where this repo's
testing needs differ from `rules/bats.md`, this file wins for this repo;
otherwise the rule applies.

## Layout (this repo)

One `tests/` root with per-language subdirs (see the dotagents repo's
`rules/testing.md` for the general convention):

```text
tests/
  helpers/common.bash   # shared bash/bats support (load_bats_libs, dotfiles_root, make_stub, make_test_repo, docker harness)
  scaffold/             # meta-test generator + templates (build-meta-tests)
  lint/                 # repo lint helpers, not tests (e.g. prose_wrap.py, run via a pre-commit hook); their unit tests live in python/
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
- `tests/docker/xdg-audit/` + `tests/shell/test_integration_xdg_audit.bats` —
  a **fourth** harness image (Debian slim + `perl` + **git**, run as a
  **non-root** user since xdg-audit operates on a real user's `$HOME`, not
  root's; throwaway dirs live under `/tmp`) for `bin/xdg-audit`, exercising
  what the hermetic unit suite
  (`tests/perl/xdg-audit.t`, one synthetic tempdir) structurally cannot.
  `common.bash` provides `xdg_audit_harness_image` and `xdg_audit_run` (which
  also mounts a **`--tmpfs /altfs`** — a genuinely separate filesystem — for
  the cross-fs cases). It covers: the read-only modes end-to-end against the
  **real vendored database** in a clean env (index build over the real corpus,
  plus `--json`, `--all`, lookup, reverse, `--search`, the filters, `--help`);
  the mutating modes with **real filesystem side effects** in a throwaway
  `$HOME` (`--remove` deletes a stray / refuses a symlink; `--migrate` moves a
  file to its XDG target); `--migrate` **across a filesystem boundary** — a
  FILE move must still succeed (`File::Copy::move` copy+unlink) and a DIRECTORY
  move must be **refused** (`EXDEV`, core-only) — the regression guard for the
  errno-clobbering bug the tempdir suite can't reach; and `--update-db`
  against a **local git upstream** (hermetic, no network) proving the mirror
  refresh + obsolete-override detection. The image carries git because
  `--update-db` shells out to `git clone`. Same skip-if-no-docker guard.
- `tests/docker/vmgr/` + `tests/shell/test_integration_vmgr.bats` — a
  **second** harness image (Debian slim + git/curl/xz) because `bin/vmgr`
  installs **real** toolchains: the test actually clones nvm and downloads a
  Node, then proves the install → expose → update → remove lifecycle.
  `common.bash` provides `vmgr_harness_image` and `vmgr_run` (same
  skip-if-no-docker guard). Kept separate from the startup image, which
  deliberately lacks those download tools.
- `tests/docker/perl/` + `tests/shell/test_integration_vmgr_perl.bats` — a
  **third** harness image (Debian slim + `perl` + a C toolchain) for `bin/vmgr`'s
  perl (perlbrew) manager, which **compiles Perl from source**. Because that
  compile takes minutes, the always-run tests exercise everything *except* the
  build — the pinned perlbrew self-install, `vmgr report perl`, and `vmgr
  remove perl` (fast, one network fetch, enough to gate per-PR) — while the
  full lifecycle that builds a real Perl + installs the module set is **opt-in
  via `VMGR_PERL_COMPILE=1`**. `common.bash` provides `perl_harness_image` and
  `perl_run`. Separate from the node/python `vmgr` image, which lacks a C
  toolchain.

These run wherever docker exists (CI, dev) and skip otherwise, so they sit in
the same gating suite without breaking docker-less environments.

## What must be tested here

- Every new script in `bin/` and every function in `lib/` gets a
  `tests/shell/test_<name>.bats` covering a **success and a failure** path.
- Bug fixes get a regression test that fails before the fix.
- `config/shell-startup/` modules that contain real logic get an integration
  test that sources them and asserts the resulting environment.
- Multi-call dispatchers (e.g. `bin/docker_wrapper`) are tested once at the
  real file; their tool symlinks are not (the generator skips symlinks). Their
  symlink-vs-registry *consistency* is guarded separately —
  `test_docker_wrapper_links.bats` asserts every tool from
  `docker_wrapper --known-tools` has a matching `bin/<tool>` symlink (by
  `readlink` target, not contents) and that no stray wrapper symlink exists;
  `bin/docker_wrapper-links --fix` repairs missing links.
- Repo-structure invariants get a guard test too:
  `test_docker_wrapper_links.bats` (above) holds the docker_wrapper symlinks
  to its registry. (The former `config/claude` rule/skill frontmatter and
  layering guards moved to the **dotagents** repo with that config.)

## Deliberately not unit-tested

A handful of `bin/` scripts are intentionally left without unit tests —
recorded here so the absence reads as a decision, not a gap. They are pure
display, interactive reads, or thin wrappers with no branching logic worth
pinning (the generated meta suite still static-checks them):

- `anykey` — interactive single-key read.
- `dateh` — date-format display; non-deterministic output.
- `lwhich` / `vimwhich` — thin `which` / vim wrappers.
- `run-help` — 9-line readline shim.
- `show-unicode` — static table.
- `bash-colors` — color-variable definitions.
- `motd` — large pure-display system summary.
- `tmux_edit_buffer` — 5-line tmux glue.
- `tmux_mode_indicator` — tmux format-string assembly only tmux evaluates
  (its leftover `set -ex` cleanup is tracked separately in `TODO.md`).

## Coverage priorities (incremental)

1. Critical scripts (anything that can lose data or break the shell).
2. Core libraries used by multiple components (`lib/*`).
3. Complex logic (parsing, loops, conditionals, dispatch).
4. Simple wrappers (lowest priority).

The generated **meta suite** runs language-specific static checks per file:
bash/sh → shebang + `bash -n` + shellcheck + shfmt; perl → shebang +
`perl -c`; python → shebang + `compile()`. It scans `bin lib`. It does **not**
scan repo-local `.claude/skills/` — that
helper (`shell-startup-guard`'s `guard.sh`) is covered by the repo-wide
pre-commit `shellcheck`/`shfmt` hooks plus its hand-written
`test_shell_startup_md5_guard.bats`. The `bin/` + `lib/` + skill-helper debt is
clean, so the
meta suite **gates in CI** — the `meta` job in `tests.yml` is a **required
status check** on `master` (alongside `bats`, `perl`, `pre-commit`). Its
`shellcheck`/`shfmt` are pinned to the repo's versions (matching the docker
wrappers and the pre-commit hooks), so CI results match what runs locally; the
generator prunes stale `*.meta.bats` so a renamed/deleted source can't leave a
dangling test. The extensionless sourced shell files (`shell-startup`,
`config/shell-startup/*`, `lib/*`) — which `identify` won't tag as shell
because they're non-executable — are covered locally by dedicated
path-selected pre-commit entries (`shellcheck-sourced` / `shfmt-sourced`), with
sourced-file false positives scoped out via `config/shell-startup/.shellcheckrc`.

## Running

```bash
bats tests/shell/test_*.bats      # hand-written suite (the gate)
bats tests/shell/                 # everything present (incl. generated meta)
tests/scaffold/build-meta-tests   # (re)generate the meta tests first
```

Run a single file or filter while iterating; reserve the full suite for
pre-commit / CI.

## Perl coverage (Devel::Cover — non-gating)

`tests/perl/` includes `pod-syntax.t` (Test::Pod over the CLIs). Coverage is
measured **on demand** with Devel::Cover (in the perlbrew toolchain — see
`config/vmgr/perl`); it is a **report, not a gate** (a percentage threshold on
two scripts would be brittle — a gating threshold is Planned, see `QA.md`):

```bash
cover -delete
HARNESS_PERL_SWITCHES=-MDevel::Cover prove tests/perl/
cover                              # prints a summary; writes cover_db/ (gitignored)
```

## CI

`.github/workflows/tests.yml` runs these jobs on pushes to `master` and on
PRs: **bats** (`tests/shell/test_*.bats`, the gate), **meta** (regenerates and
runs `tests/shell/*.meta.bats` with pinned `shellcheck`/`shfmt` — a required
check, see the meta-suite note above), **perl** (`prove tests/perl/`,
installing `libtest-cmd-perl` + `libtest-pod-perl` + `perltidy`), **python**
(`pytest tests/python`,
self-activating once `tests/python/test_*.py` exist), and **pre-commit** (the
check config via `pre-commit run --all-files`).

## Test development

- TDD is encouraged: write the failing test, implement, make it green, then
  run the suite.
- After adding or removing scripts, regenerate the meta tests
  (`tests/scaffold/build-meta-tests`) and review what it surfaces.
- Never silence a failing test by ignoring it; fix the code, fix the test, or
  record the debt in `TODO.md`.

## Questions

- Test structure (all languages) → the dotagents repo's `rules/testing.md`
- bats how-to → the dotagents repo's `rules/bats.md`
- General workflow → `WORKFLOW.md`
- Examples → `tests/shell/`
