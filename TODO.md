# TODO

## 🪟 PowerShell Setup

### PowerShell ↔ Bash Feature Parity

The PowerShell startup (`ps-startup.ps1` + `powershell/startup/*`) lags the
bash side (`shell-startup` + `config/shell-startup/*` + `lib/*` + `bin/*`).
Bring it to parity **where it makes sense for PowerShell** — port the
cross-shell concepts, skip the bash-only or Windows-irrelevant bits. Now that
`tests/shell/test_integration_powershell.bats` exists, each ported feature
should get an assertion there (or a Pester test under `tests/powershell/`).

- [ ] Audit bash `config/shell-startup/*` against `powershell/startup/*` and
  decide, per feature, port / adapt / skip. Candidates that map cleanly:
  - [ ] **History** — `010-general.ps1` already flags this (PSReadLine: history
    file location/size, dedupe, search); mirror the bash `HIST*` intent.
  - [ ] **Completions** — bash completions → PSReadLine / argument completers.
  - [ ] **Prompt** — a pwsh `prompt` function mirroring the bash prompt (git
    status, last exit code, cwd) — reuse the `bin/git-status` concept.
  - [ ] **Aliases/functions** — port still-relevant bash aliases/functions not
    already in `010-general.ps1`; grep colors → PSReadLine colors.
  - [ ] **PATH dedup** — a `cleanpath` equivalent for `$env:PATH` so
    ps-startup's PATH prepend can't accumulate duplicates. (Also fixes the
    Windows-style `\`/`;` PATH line in `ps-startup.ps1` when run under Linux
    `pwsh`.)
  - [ ] **Interactive vs always split** — the bash side guards interactive-only
    setup with `[[ $- == *i* ]]`; decide the pwsh analog (a non-interactive
    `pwsh -File`/`-Command` still loads the profile — keep env setup cheap and
    side-effect-free, gate interactive-only bits on
    `[Environment]::UserInteractive`/`$Host` if needed).
  - [ ] **debug helper** — a `$env:DEBUG`-gated trace mirroring `lib/debug`.
- [ ] `powershell/bin/*` vs `bin/*` — note which bash utilities have a
  Windows-relevant analog worth providing (and which stay bash-only).
- [ ] Fold the XXX items below into this audit as they're addressed.

### PowerShell Improvements

- [ ] ps-startup.ps1:49 - Move Python path to dedicated setup file (XXX)
- [ ] 010-general.ps1:27,42,54,59 - Port remaining bash features marked with XXX

### PowerShell: Linux Dev/Test Environment

Linux `pwsh` + Docker is proven viable — the integration test runs the
profile cleanly in the stock `mcr.microsoft.com/powershell` image. Remaining
research:

- [ ] Compatibility between `pwsh` (Core) and Windows PowerShell 5.1:
  - Known gaps: COM objects, Windows-only modules (`ActiveDirectory`, etc.),
    `$PSVersionTable.PSEdition` differences, some .NET APIs
  - Determine if `ps-startup.ps1` and `config/powershell/` scripts use any
    Windows-only features that would break under `pwsh` on Linux
  - Check if Pester runs identically on both
- [ ] Whether a Windows container is needed to test true Windows PowerShell
  5.1 behavior, and whether that's practical (requires a Windows host for
  Windows containers).

## 📋 Move task tracking to GitHub issues

This repo has no `tracker:` sentinel, so it falls back to the pre-sentinel
default: this file. Switching to issues gets the things a flat file cannot
give — per-task state and assignment, cross-repo links (the `→ dotagents`
items below are a workaround for exactly that), labels for the `role:*` /
`type:*` / nature axes, and blocking relationships.

- [ ] **Declare `tracker: github`** in `.claude/WORKFLOW.md`. Read from the
  working tree, so it takes effect as soon as the line lands. Do this
  *after* the migration, not before — otherwise new captures land in issues
  while 115 open items still sit in the file, and the backlog is split
  across two places.
- [ ] **Migrate the open items by disposition**, per `gh.md` *Legacy backlog
  → issues / ICEBOX*: an **active, will-do** task becomes a GitHub issue; a
  **future / deferred** one is **iceboxed, never issued** — promoted only
  when it is time to work it. This is the whole point of the exercise: 115
  open bullets is not a backlog, it is a pile, and a straight file→issue
  conversion would just move the pile.
- [ ] **Triage what survives** — label per the taxonomy (`labels.md`): a
  mandatory `role:*`, `type:new` / `type:change`, nature, and any meta
  marker. Reconcile each against current code first; several are likely
  already done (this file has entries predating work that shipped).
- [ ] **Decide what happens to `TODO.md` itself** — delete it, or leave a
  stub pointing at the issue list. Also update `.claude/WORKFLOW.md` *TODO
  Routing*, which currently sends everything here, and the `CHANGELOG.md`
  header, which describes `TODO.md` as its open-work counterpart.

Sizeable enough to be an epic in its own right; the migration should probably
be its own issue tree once `tracker: github` is live.

## 🔄 Upstream / update tracking

How the repo stays current with files and tools that originate elsewhere.

### Vendored file / skill update checker

Some files are **vendored** (copied in from an upstream repo) rather than
authored here — e.g. the dotagents repo's `skills/frontend-design/` from
`anthropics/skills`. Each vendored item carries a `SOURCE.md` recording its
upstream repo, path, and pinned commit SHA (frontend-design has the first
one). We need a way to check whether any vendored item is behind upstream so
we can stay current.

- [ ] Build a checker that finds every `SOURCE.md`, reads `Upstream repo` /
  `Path` / `Vendored SHA`, queries
  `gh api "repos/<repo>/commits?path=<path>&per_page=1"` for the latest SHA,
  and reports which vendored items are BEHIND (optionally show the diff).
- [ ] Decide placement (**leaning toward both**):
  - Option A: `bin/check-vendored` — general, repo-wide; scans for any
    `SOURCE.md` so it works for non-Claude vendored files too.
  - Option B: the dotagents repo's `bin/check-vendored-skills` — Claude-scoped;
    limits to the dotagents repo's `skills/*/SOURCE.md`.
  - Likely both: a general `bin/` core that does the work, plus a thin
    dotagents repo `bin/` entry that scopes it to skills.
- [ ] Generalize the `SOURCE.md` provenance convention (repo / path / SHA /
  local-edits) and document it (WORKFLOW.md or a rules file).
- [ ] Consider folding the git-completion `check4update` item below into
  this same mechanism (give those files a `SOURCE.md` too).
- [ ] Optional: wire it to a periodic nudge (Claude `/schedule` or a CI
  `update-deps.yml` job — now issue
  [#351](https://github.com/harleypig/dotfiles/issues/351), which records that
  this mechanism subsumes it).

### Git-completion dependency checker

- [ ] Create check4update script for git completion files:
  - git-prompt.sh
  - git-completion.bash
- [ ] Set up automated or manual update process

## 🔍 Research and Exploration

- [ ] Look into pyscn tool: <https://github.com/ludo-technologies/pyscn>
  - [ ] Install via: `pipx install pyscn`
- [ ] Document bash changes resource:
  <https://web.archive.org/web/20230401195427/https://wiki.bash-hackers.org/scripting/bashchanges>
- [ ] Consider adopting the old **`gitperms`** repo to record and restore
  full file permissions in a repository. Git stores only the executable bit
  (`100644` vs `100755`), not group/other read-write — so tightening files to
  owner-only (`700`/`600`, e.g. across a `bin/`) can't be committed (surfaced
  while committing harleydev `bin/` permission changes). A `gitperms`-style
  manifest + restore hook can carry the bits git drops. **If adopted, the
  global `~/.claude` config must be updated to manage it** — a rule (and
  likely a hook) teaching the agent to record/restore and verify permission
  state, the way it manages other repo tooling.

## 📋 Template Creation

**Note:** This is extensive future work and may warrant its own project/branch.

### Pre-commit Templates (Deferred)

- [ ] Research comprehensive pre-commit hook registry
- [ ] Create language-specific hook collections
- [ ] Document hook configurations and best practices

### Configuration Templates (Deferred)

- [ ] Python tooling templates (pyproject.toml, .flake8, etc.)
- [ ] General development templates (.editorconfig, .gitignore, etc.)
- [ ] Documentation and markup templates
- [ ] Infrastructure and DevOps templates
- [ ] Language-specific configurations
- [ ] IDE and editor configurations
- [ ] CI/CD templates
- [ ] GitHub issue templates — wire the new-project setup/conversion to
  scaffold `.github/ISSUE_TEMPLATE/` (bug, test, documentation, enhancement),
  matching the harleydev naming.

See original TODO.md (archived) for detailed template specifications if needed
in the future.
