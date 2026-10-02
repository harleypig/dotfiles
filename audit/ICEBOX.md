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

**Data source:** the bash-hackers *bash changes* page, a version-by-version
record of when each feature arrived — the [archived original][bashchanges-wa]
(bash-hackers.org itself is dead) and its [community-maintained
mirror][bashchanges-flokoe]
([#390](https://github.com/harleypig/dotfiles/issues/390)).

[bashchanges-wa]: https://web.archive.org/web/20230401195427/https://wiki.bash-hackers.org/scripting/bashchanges
[bashchanges-flokoe]: https://flokoe.github.io/bash-hackers-wiki/scripting/bashchanges/

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

## Taskwarrior helper scripts: vendoring rejected

**Revisit if** the taskwarrior shell module is reactivated (renamed off
`_inactive` and its leading `return 0` dropped) and a script turns out to be
wanted in daily use.

Rejected strand of [#359](https://github.com/harleypig/dotfiles/issues/359):
whether to vendor any of taskwarrior's bundled helper scripts (hooks,
add-ons, completion, editor syntax) into this repo, with a `SOURCE.md`.

The source-built task 3.3.0 here installs them under
`/usr/local/share/doc/task/scripts/`, not the Debian
`/usr/share/doc/task/scripts/` the item named. What is there is example
hooks (`on-add`, `on-exit`, …), bash and fish completion, vim syntax files,
and an `add-ons/README` that only points to taskwarrior.org/tools — samples
and editor/shell integration, not helpers worth carrying a vendored copy of.

It is rejected rather than deferred because nothing here would use it:
`config/shell-startup/taskwarrior_inactive` opens with `return 0`, so the
module is off, and installing taskwarrior itself (and so its bundled
scripts) is the ansible-stuff repo's job, not this one's.

## `column_ansi` for motd's colourised columns: rejected

**Revisit if** motd gains a `column` input whose cells in one column carry
colour codes of different lengths, or mixes coloured and plain cells in the
same column.

Rejected strand of [#359](https://github.com/harleypig/dotfiles/issues/359):
<https://github.com/LukeSavefrogs/column_ansi>, a `column(1)` replacement
that ignores ANSI escape sequences when measuring width. Plain `column`
counts the escape bytes, so colourised table cells can misalign.

It does not bite here. The only coloured `column` input in `bin/motd` is the
Docker container table (the `column -t -s ','` near line 207): every state
cell is wrapped in `c_ok` (green) or `c_alert` (red) plus `c_off`. Red and
green are the same length in both branches — `\033[31m` / `\033[32m` from
`ansi`, `\033[0;31m` / `\033[0;32m` from the fallback — so every cell in a
column carries identical overhead and the columns still align. Checked by
running mixed red/green rows through `column -t` and stripping the codes:
aligned. The fail2ban tables use `column` too but are uncoloured.

## `cleanpath` rewritten in Perl: rejected

**Revisit if** `cleanpath` grows logic that bash expresses poorly.

Rejected strand 1 of [#359](https://github.com/harleypig/dotfiles/issues/359),
measured 2026-10-02: whether to port `bin/cleanpath` to Perl, as a faster
PATH dedup or a cleanpath rewrite in a second language.

A core-only Perl port took 8.6 ms per call. A fork-free bash version built
on `cd -P` took about 7 ms. The current script takes about 45 ms, and it
runs once per login. So Perl is slower than the bash fix and adds a second
language to maintain. It also does nothing for the parallel WSL `/mnt`
lookups that [#59](https://github.com/harleypig/dotfiles/issues/59) added.
The speed-up went to bash instead, in
[#495](https://github.com/harleypig/dotfiles/issues/495).

## pyscn for Python static analysis: rejected

**Revisit if** a substantial first-party Python surface returns outside
`tests/`.

Rejected in [#390](https://github.com/harleypig/dotfiles/issues/390),
2026-10-02: pyscn, a Python static analyser for dead code, unreachable code,
clone (duplicate code) detection and complexity.

It reported 0 findings on this repo's live Python, `tests/lint/prose_wrap.py`
and `tests/python/test_prose_wrap.py`. Both are already clean under flake8,
isort and yapf. Its complexity check duplicates flake8's built-in C901
check, which [#496](https://github.com/harleypig/dotfiles/issues/496)
enables. Its default excludes (`test_*.py`, `tests/**`) cover all of this
repo's Python, so it scans nothing unless they are overridden. Its one
unique check, unreachable code after `return`, has no instance here.
Lighter options for that check, such as pylint W0101 or vulture, were not
evaluated.

## Vendoring tpm, the tmux plugin manager: rejected

**Revisit if** the operator wants a tmux plugin re-enabled.

Rejected in [#436](https://github.com/harleypig/dotfiles/issues/436),
2026-10-02: whether to vendor tpm, the tmux plugin manager, or carry it and
the tmux plugins as a git submodule.

Nothing would use it. The plugin stack has been disabled since
[#330](https://github.com/harleypig/dotfiles/issues/330), the repo has had
no submodules since 2025-09-01, and no plugins are installed. tpm is never
needed for a vendored plugin, which loads with
`run-shell <dir>/<plugin>.tmux`.

If plugins come back, vendor each one under `config/tmux/plugins/<name>/`
with a `SOURCE.md` in the
[#389](https://github.com/harleypig/dotfiles/issues/389) format. The
exception is tmux-menus. At about 12.5k lines and about 44 commits a year,
it is cheaper to keep as a pinned, ignored clone than to vendor.
