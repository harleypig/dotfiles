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
