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

## 🐚 Shell-startup Setup

### Shell-startup colors & helpers to get working (from audit)

Long-standing "I've been trying to get this working for years" items, parked
from the audit. Each is its own task:

- [ ] **`less` colors** — get the `LESS_TERMCAP_*` coloring reliable; while
  here, revisit the commented `LESSKEY` (`less`:7) and `LESS_TERMCAP_mh` dim
  (`less`:79–80), and the per-login `less --incsearch -V | grep` capability
  probe (`less`:26) — cache the result instead of running it every login.
- [ ] **`grep` colors** — get `GREP_COLORS` (and the commented `GREP_COLOR`,
  `010-general`:21) producing the intended highlight.
- [ ] **`run-help`** — get the Alt+h "help for word under cursor" binding
  working (commented in `010-general`:184; needs the inputrc macro).

### Move env-polluting shell-startup setup into bin wrappers

Some `config/shell-startup/` modules export tool-specific environment into
*every* interactive shell for a tool that's rarely run — the setup belongs in
an on-demand `bin/` wrapper (set the env, then `exec <tool> "$@"`) so it stops
polluting the global environment. The convention is now written down in
[`.claude/CONVENTIONS.md`](.claude/CONVENTIONS.md) *Shell-startup Module
Placement*; the per-module items below are the actionable findings of the
audit.

- [ ] **aider** — folds into the **AGENTS.md migration** (dotagents
  `audit/BACKLOG.md`), *not* a `bin/aider` wrapper: aider reads AGENTS.md, so
  its `AIDER_*` / `AIDER_EDITOR` / `AIDER_COMMIT_PROMPT` env is made
  client-agnostic there. Remove `config/shell-startup/aider` when that
  migration lands.
- [ ] **ansible** → `bin/ansible` wrapper: it exports only `ANSIBLE_HOME` /
  `ANSIBLE_CONFIG` (+ `mkdir`), nothing shell-facing. Cover the siblings
  (`ansible-playbook` / `-galaxy` / `-vault`) via a shared `bin/_ansible-env`
  the wrappers source.
- [ ] **claude** → a `bin/claude` wrapper candidate for
  `CLAUDE_CODE_NO_FLICKER`. First **verify** nothing (hook/tool) reads
  `CLAUDE_CONFIG_DIR` from the ambient env, and coordinate `CLAUDE_CONFIG_DIR`
  with the AGENTS.md migration (client-config).
- [ ] **Finish moving `LINODE_TOKEN` into each terraform repo's `set_env`.**
  The ambient export is gone from `api-keys.cfg` (its value selects a whole
  Linode **account**, so an ambient one meant terraform in a customer's repo
  authenticated as the *personal* account). `harleydev/bin/set_env` already
  loads it; the remaining work is per-repo:
  - **`harleydev/bin/set_env`** — repoint at the scope store
    (`private_dotfiles/linode/tokens/harleypig`) rather than the
    `api-key/linode` symlink, and fix its stale
    `LINODE_CLI_CONFIG="$PRIVATE_DOTFILES/linode"`, which now names the store
    *directory* instead of the retired config file. Harmless today — every
    `linode-cli` call in that repo passes explicit flags, and
    `LINODE_CLI_TOKEN` short-circuits the config — but it is a trap for the
    next reader.
  - **`methodsprime-provisioning`** — **done.** `bin/set_env` is in place,
    bound to the `methodsprime` scope and reading
    `private_dotfiles/linode/tokens/methodsprime`. It skipped the
    `api-key/linode` path harleydev still uses, which no longer exists.
  - **Keep the contract agnostic.** That repo's README already specifies the
    token "supplied via the environment as `LINODE_TOKEN`", which is correct
    and stays: CI and other developers supply it their own way. `set_env` is
    only the workstation's way of satisfying it.
  - Standardising the pattern across terraform repos is
    [dotagents#229](https://github.com/harleypig/dotagents/issues/229).
- [ ] **Scope `.s3cfg` per Linode account, the way tokens already are.**
  The same account-selection problem as `LINODE_TOKEN` above, on the *other*
  credential axis — and it has already caused a real mistake.

  Object Storage authenticates with an **access-key/secret-key pair**, not the
  API token. There is exactly one `private_dotfiles/.s3cfg`, and it holds the
  **harleypig** account's pair. So while `LINODE_TOKEN` correctly selects a
  customer account, the S3 state backend silently uses the personal one.

  **What that already cost:** a `methodsprime-terraform-state` bucket was
  created in the *personal* account rather than MethodsPrime's. It looked
  right from the terminal — the bucket exists, `plan` works, locking works —
  and was only caught by logging into the customer's console and seeing an
  empty Object Storage page. Nothing errors, because both credentials are
  individually valid; they just point at different accounts. Caught while
  empty, so nothing had to be migrated.

  The shape almost certainly mirrors `linx` / `ghx`:

  - a per-scope store (`private_dotfiles/linode/objectstorage/<scope>`, or
    `.s3cfg-<scope>`) holding one s3cmd-format file per account, so
    `s3cmd -c <file>` and the `AWS_*` exports both read the same source;
  - a scope-aware way to reach it — either a small `s3x`-style wrapper or
    just each repo's `set_env` naming its own scope, which is enough if
    nothing needs ad-hoc cross-account s3cmd;
  - a `README.md` beside `linode/README.md`, whose *"`LINODE_TOKEN` is a
    different thing"* section is the model for explaining the split.

  **Watch the scope names.** A Linode *username* is the natural scope key for
  API tokens (a user belongs to exactly one account), but an Object Storage
  key belongs to the **account** and can be region-scoped. Whether the two
  registries can share one key space or need separate ones is the first thing
  to settle.

  Blocking `methodsprime-provisioning` right now: its state cannot move to the
  customer's account until MethodsPrime has an Object Storage key pair and
  somewhere to keep it.
- [ ] **binenv** (partial) — move `BINENV_CACHEDIR` / `CONFDIR` / `LINKDIR`
  (+ `mkdir`) to a `bin/binenv` wrapper; keep the completion but gate it
  `[[ $- == *i* ]]` and **vendor** it to `config/completions/binenv` (it
  currently forks `binenv` on every shell). **Gated on the binenv keep/drop
  decision below** — binenv isn't used on this box (not installed, so the
  module is inert), so whether this hygiene is worth doing at all is
  ansible-stuff's call.
  - → **ansible-stuff**: decide whether binenv stays in the provisioning
    strategy. It is the active package manager there (its `package_manager`
    role installs binenv, defines a binenv packages map, and has roadmap
    items for it), but is unused for dotfiles and golden-image. The dotfiles
    side is binenv's config half — `config/binenv/distributions.yaml` (the
    sources catalog) and `config/shell-startup/binenv` (`BINENV_CONFDIR`,
    etc.). If kept, own that coupling; if dropped, remove ansible-stuff's
    binenv role and the dotfiles binenv config together. Cross-repo: migrate
    to ansible-stuff's `BACKLOG.md` when next working that repo.

## 📝 Documentation Setup

- [ ] **Auto-fix companion for `prose_wrap.py` (78-col reflow).** The
  `prose-wrap` pre-commit check flags >78-col agent-config prose but has no
  `--fix`, so reflowing is manual and **cascades** (moving a word overflows the
  next line) — a recurring agent friction (seen repeatedly, e.g. dotfiles PR
  #255). Investigate a reflow mode (extend `tests/lint/prose_wrap.py`, or a
  markdown-aware wrapper) that rewraps prose paragraphs to 78 cols while
  leaving fenced code, tables, headings, and lists untouched — wired into
  `.pre-commit-config-fix.yaml`. Weigh against the risk of mangling intentional
  line breaks.
- [ ] **Widen the `prose-wrap` check to the repo's own authored docs
  (retrospective, PRs #319/#320).** `tests/lint/prose_wrap.py` already does
  exactly the right thing — counts *characters* (no em-dash byte-count trap)
  and exempts code/frontmatter/tables/reference-links/headings/URLs — but the
  hook is scoped `files: ^\.claude/.*\.md$`, so `TODO.md`, `CHANGELOG.md`, and
  `docs/adr/*.md` get no automated 78-col gate. Authoring those docs meant
  hand-counting with `perl -CSD` and iterating on overflows (hit in both the
  ADR-0005 PR and this one). Widen the hook's `files` pattern to cover the
  repo's authored Markdown (`TODO.md`, `CHANGELOG.md`, `docs/**.md`,
  `README.md`, `.claude/**.md`). **Prereq:** the hook gates on a clean corpus,
  so first fix the pre-existing >78-col prose lines in those files (several
  exist in `TODO.md`) or the widened hook blocks every commit.

### Prose linting: adopt Vale for Phase 4

**Research complete (2026-06-26) — decision: adopt Vale.** proselint is
maintained again but **superseded** by Vale here: Vale is a single Go binary
(no Python dep — fits the docker-wrapper/pinned-binary pattern), markup-aware
(Markdown scoping), config-driven, and can even **run proselint's own ruleset**
as a package — so the two overlap and running both is redundant. **Grammarly is
ruled out** (no CLI/headless/CI interface; current offering is an enterprise
B2B REST API). The stale global `dot-general/.proselintrc` is retired in this
change (mirrors the markdownlintrc retirement, PR #149). Full research record
in [`CHANGELOG.md`](CHANGELOG.md).

Implementation follow-up (do when Pre-commit **Phase 4** lands):

- [ ] **Wire Vale into Phase 4.** Add Vale as the prose linter — a pinned
  `docker_wrapper` entry and/or the official pre-commit hook + GitHub Action;
  a repo-local `.vale.ini` selecting curated styles (start minimal — e.g.
  `proselint` and/or `write-good`, scoped to skip code blocks/links so
  technical docs stay quiet); run `vale sync` in setup/CI. Ground a new
  the dotagents repo's **`rules/vale.md`** in Vale's current docs at that
  point (build-on-first-use) and wire it into the tool-detection table + the
  `qa.md` Documentation dimension. *(The agent-config parts route to the
  dotagents repo's `audit/BACKLOG.md` per the TODO convention when authored.)*

### Phase 4: Documentation Linting (pre-commit)

- [ ] Add documentation quality hooks:
  - [ ] Vale (prose linting) — see *Prose linting: adopt Vale*
  - [ ] Additional markdown checks
  - [ ] Link validation
- [ ] Test on repository documentation
- [ ] Update documentation

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
