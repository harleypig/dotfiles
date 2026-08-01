# Icebox

Deferred decisions for this repo — **considered, "not now."** This is the
repo-wide home for the `ICEBOX:` marker convention (the dotagents repo's
`rules/code-style.md`), for cases with no single code location to pin an
in-code `ICEBOX:` comment to. A deferral that *does* have an obvious code
anchor belongs as a comment at that code instead.

**This is not a todo file.** Items here are **not** open work — will-do tasks
are GitHub issues. The boundary:

- **Will do it** → a **GitHub issue**.
- **Deferred, maybe someday, with its context** → **here**.

Each entry states its **revisit condition**: a concrete trigger, or "on
request only" (the classic `ICEBOX:` semantics).

Created 2026-08-01 during the `TODO.md` → issues migration
([#345](https://github.com/harleypig/dotfiles/issues/345)), which needed a
destination for deferred items — `gh.md` *Legacy backlog → issues / ICEBOX*
is explicit that a future/deferred task is **iceboxed, never issued**, and
this repo had nowhere to put one.

## Matrix testing across multiple bash versions

**Revisit on request**, or if a bash-version bug actually bites.

Migrated from `TODO.md` *CI/CD Setup › Phase 3*, where it was already marked
*(optional)*. CI runs one bash — whatever the `ubuntu-latest` runner ships —
so nothing verifies the scripts against the older bash a different machine
might have.

Deferred rather than issued because it is speculative: no version-specific
breakage has been observed, and a matrix multiplies CI minutes across every
job for a risk that has not materialised. The `bats` suite is the thing that
would run in the matrix, and it is already the slowest job.

## Detecting version-gated bash features against the supported floor

**Revisit if** the matrix-testing item above is ever picked up — this is the
cheaper half of the same problem, and probably the better starting point.

The sharper version of "test across bash versions": rather than running the
whole suite against every bash, **detect the use of constructs newer than the
minimum version being claimed**. If the floor is bash 4.1 but a script uses
something introduced in 4.5, that is a defect discoverable by inspection —
no matrix required.

Concrete examples of the class:

- `${var@Q}` / `${var@a}` parameter transformations — bash **4.4**
- `mapfile`/`readarray` — bash **4.0** (used throughout this repo)
- associative arrays (`declare -A`) — bash **4.0**
- `wait -n` — bash **4.3**
- `${ }` nameref (`declare -n`) — bash **4.3**

Open questions, none answered yet: **what is the supported floor?** Nothing
currently declares one — `bash.md` says "bash 4.0+" for bats, but the repo's
own scripts have no stated minimum. Until that is decided the check has no
threshold to test against, which is a large part of why this is iceboxed
rather than issued.

Whether a tool exists for this is also unknown — shellcheck does not flag
version-gated syntax by default, though it does accept a `# shellcheck
shell=bash` directive and has some version awareness worth investigating
before building anything.

## Extending `cleanpath` to other path variables

**Revisit if** duplicates actually show up in `LD_LIBRARY_PATH`, `MANPATH`, or
another path-shaped variable.

Migrated from `TODO.md` *Features & fixes*, where it was already marked
*(Optional)*. `bin/cleanpath` is fixed, tested
(`tests/shell/test_cleanpath.bats`), and integrated into `shell-startup`
behind a guard so a failure cannot blank `PATH`. Extending it to other
variables is speculative — the item's own wording is "if duplicates show up
there too", and none have been observed.

Deferred rather than issued because there is no evidence of the problem it
would solve. The trigger is concrete enough to notice if it ever fires.

## Version managers: adopting a pre-installed global manager

**Revisit when** a machine actually turns up with one installed system-wide.

Migrated from `TODO.md` *Tool/Version Manager Setup*, whose own wording was
"when first needed". Handle a machine that already has a manager installed
globally — detect it and decide adopt / skip / coexist rather than blindly
re-installing.

Deferred because the case is hypothetical: every machine `vmgr` currently
provisions starts without one. Writing detection-and-adopt logic against an
imagined layout is how the wrong abstraction gets built.

## Version managers: mutual exclusivity within one language

**Revisit when** a language actually has two managers that cannot coexist —
the item names nvm vs an alternative Node manager as the likely first case.

Migrated from `TODO.md` *Tool/Version Manager Setup*. The **model is already
settled**: managers coexist by default (python's pipx / uv / pip), the
dispatcher allows naming several, and a module enforces any mutual exclusivity
in its own install logic rather than the dispatcher doing it.

What remains is only the concrete case plus a regression test — and it cannot
be written until such a language exists here. Iceboxed rather than issued
because there is nothing to implement, only a decision already made.

## Template creation — config/tooling template library

**Revisit on request**, or if a second repo actually needs the same scaffold
and copying it by hand becomes the friction.

Migrated wholesale from `TODO.md` *Template Creation*, whose own heading
marked both subsections **"(Deferred)"** and warned the work "is extensive
future work and may warrant its own project/branch". Iceboxed rather than
issued, per `gh.md`: a future/deferred task is never filed as an issue.

The scope as written:

- **Pre-commit templates** — a comprehensive hook registry, language-specific
  hook collections, and documented configurations
- **Configuration templates** — Python tooling (`pyproject.toml`, `.flake8`),
  general development (`.editorconfig`, `.gitignore`), documentation and
  markup, infrastructure/DevOps, per-language, IDE/editor, and CI/CD

Detailed specifications are in the archived original TODO, referenced from the
section, if the work is ever picked up.

**One item did not stay here.** Scaffolding `.github/ISSUE_TEMPLATE/` during
project setup is concrete, small, and owned by the `new-project` skill — filed
as [dotagents#259](https://github.com/harleypig/dotagents/issues/259) instead.

The honest reason this is deferred rather than planned: a template library is
only worth its maintenance when several repos consume it, and the pattern here
has been the opposite — each repo's config has been tuned to that repo. The
Rule of Three has not fired.
