# TODO - Dotfiles Repository Modernization

**Last Updated:** 2026-04-18
**Plan Version:** Based on Dotfiles Repository Modernization Plan

This TODO file tracks the modernization effort for the dotfiles repository,
organized by work area with phase markers. See `WORKFLOW.md` for development
guidelines and `TESTS.md` for testing strategy.

## 📝 Documentation (HIGH PRIORITY)

### Immediate Tasks
- [x] Review and consolidate docs/ directory
  - [x] Evaluate docs/bash-completion.md - moved to config/completions/README.md
  - [x] docs/git_aliases.md - leave in docs/; user-facing reference, not config
  - [x] docs/bin.md and docs/windows-notes.md - both user-facing reference, stay in docs/

### Code Comment Cleanup
- [ ] Address XXX/TODO/FIXME comments (convert to documentation or fix)
  - See "Code Improvements (LOW PRIORITY)" section for detailed list

## 🔧 Git File-Mode Normalization (HIGH PRIORITY)

This repo's local `.git/config` has `core.filemode = false`, which
overrides the global `config/git/config` setting of `true`. It was almost
certainly auto-detected by `git init`/`clone` on a Windows path (where exec
bits can't be confirmed) and rode along to this ext4 home, where exec bits
work fine. The side effect: a batch of files were committed with the wrong
mode, and git silently ignores exec-bit changes here.

Flipping `core.filemode` to `true` surfaces ~61 files as "modified" (as of
2026-06-05) — a two-directional mess that needs per-file judgment, NOT a
blind `git add -u`:

- **Should lose exec** (most): data/config files wrongly marked `755` —
  `.json`, `.yaml`, `.toml`, `README.md`, `.gitkeep`, `config/*`.
- **Should keep exec but may be `644` on disk**: real scripts —
  `bin/mymcp`, `config/claude/bin/statusline.sh`,
  `config/claude/skills/ship-pr/scripts/ship.sh`, `powershell/bin/*.ps1`.

Tasks (do as its own focused branch/commit, e.g. `chore(git): normalize
file modes`):

- [ ] Set `core.filemode = true` locally to match the global setting (or
  unset the local override so it inherits global)
- [ ] Review the full mismatch list: `git -c core.fileMode=true status -s`
- [ ] Per file, correct the index mode: `git update-index --chmod=-x` for
  data/config, `--chmod=+x` for genuine executables (verify each script
  actually needs the bit)
- [ ] Commit the normalized modes; confirm `git status` is clean with
  `filemode=true` in effect
- [ ] Note: there is no `.gitattributes` mechanism for exec bits — this
  must be done via `update-index`. Until normalized, new executables in
  this repo need `git update-index --chmod=+x <file>` (the on-disk bit is
  ignored while local `filemode=false` stands).

## 🔒 Dependabot Security Alerts (HIGH PRIORITY)

Open Dependabot alerts on the default branch (triage queue — see `gh.md`
*Issues & triage*). Both are the **same dependency**, both **high**, both
fixed by one bump. List them with:
`gh api repos/harleypig/dotfiles/dependabot/alerts -f state=open`.

- [ ] Bump **dulwich** to **>= 1.2.5** in `config/pypoetry/pyproject.toml`
  (currently resolves to a vulnerable version), then refresh the lockfile.
  This closes both alerts:
  - [ ] Alert #5 — GHSA-9277-mp7x-85jf: command injection via merge driver
    path (affects `>= 0.24.0, < 1.2.5`).
  - [ ] Alert #4 — GHSA-897w-fcg9-f6xj: arbitrary file write via
    NTFS-hostile tree entries on Windows (affects `>= 0.10.0, < 1.2.5`).
- [ ] After the bump lands on the default branch, confirm both alerts
  auto-close (or dismiss with reason if dulwich is only a transitive dev
  dependency that is not actually exercised).

## 🔗 docker_wrapper Symlink Automation (MEDIUM PRIORITY)

`bin/docker_wrapper` is a multi-call dispatcher: each tool is a `bin/<tool>`
symlink to it, and the tool list lives in the `known_tool` registrations
inside the script. The symlinks are created by hand today, so a newly added
tool — or a fresh checkout — can silently lack its symlink.

- [ ] Add a check that every registered tool has a matching `bin/<tool>`
  symlink pointing at `docker_wrapper`, and that no stray wrapper symlink
  points at it without a registration. Drive it from the `known_tool` keys
  (grep the `known_tool[...]=1` lines, or source the script in a guarded
  mode).
- [ ] Wire that check in as a meta-test (`tests/build-meta-tests` /
  `meta_*.bats`, per `TESTS.md`'s symlink validation) so CI flags a missing
  or stray symlink.
- [ ] Add a create/repair mode (a `--fix` flag or a small maintenance
  command) that creates any missing `bin/<tool>` symlinks and reports stale
  ones, so adding a tool or setting up a fresh clone is one command.
- [ ] Assert the link *target* (`docker_wrapper`), not file contents —
  symlink mode is 120000 and unaffected by `core.filemode=false` (see Git
  File-Mode Normalization above).

## 🔍 config/shell-startup Audit (MEDIUM PRIORITY)

Review all files in `config/shell-startup/` for correctness and security:

- [ ] Variables set at module scope but never unset (temporary/setup vars
  that pollute the shell environment)
- [ ] Sensitive values (tokens, keys, paths to secrets) that should be
  handled more carefully or not exported at all
- [ ] Variables exported unnecessarily (does the child process actually
  need it, or should it be local?)
- [ ] Patterns like `source`/`.` that execute arbitrary files without
  checking ownership or permissions
- [ ] Files read without checking they're not world-writable
- [ ] Missing `command -v ... || return 0` guards where a tool may not
  be installed
- [ ] Inconsistent guard style (`if command -v` vs `command -v || return 0`)
  — standardize to `|| return 0` pattern per `000-loadtokens` fix
- [ ] Any other shellcheck warnings not already suppressed with justification

## 🏠 $HOME Dotfile Audit (MEDIUM PRIORITY)

Reduce $HOME clutter by moving dotfiles to XDG directories where supported
and removing unused ones.

Reference: https://wiki.archlinux.org/title/XDG_Base_Directory
(comprehensive list of which apps support XDG and how to configure them)

- [ ] Inventory all dotfiles/dotdirs in $HOME (`ls -la ~ | grep '^\.'`)
- [ ] For each, check the Arch wiki XDG page:
  - If XDG is supported: move file/dir to appropriate XDG location and
    configure the app (env var, config option, symlink, etc.)
  - If XDG is not supported: determine if the app is still in use; remove
    the dotfile if not
- [ ] Update `config/shell-startup/` modules to set any required env vars
  for apps migrated to XDG paths
- [ ] Update dotlinks if any of these were previously managed there
- [ ] After migration, verify apps still work correctly

Known offenders to investigate (as of 2026-05-20):

| Path | Tool | Notes |
| --- | --- | --- |
| `~/.aider` | aider AI | check if `--config-dir` or `AIDER_CONFIG` supports XDG |
| `~/.cpan` | CPAN | `CPAN::Config` supports custom dirs |
| `~/.cpanm` | cpanm | `PERL_CPANM_HOME` env var |
| `~/.docker` | Docker | `DOCKER_CONFIG` — already set in `010-general` but dir still in `$HOME` |
| `~/.gradle` | Gradle | `GRADLE_USER_HOME` env var |
| `~/.gradle-mcp` | gradle-mcp | likely follows `GRADLE_USER_HOME` or its own config |
| `~/.java` | Java/JVM | `java.util.prefs.userRoot` system property |
| `~/.jbang` | jbang | `JBANG_DIR` env var |
| `~/.kivy` | Kivy | `KIVY_HOME` env var |
| `~/.lesshst` | less | `LESSHISTFILE` env var — set to `$XDG_CACHE_HOME/less/history` |
| `~/.m2` | Maven | `settings.xml` `<localRepository>` or `MAVEN_OPTS` |
| `~/.npm` | npm | `NPM_CONFIG_CACHE` or `.npmrc` `cache=` |
| `~/.redhat` | Red Hat tools | investigate; may not be movable |
| `~/.serena` | Serena AI | check if config path is configurable |
| `~/.sqlite_history` | SQLite | `SQLITE_HISTORY` env var |
| `~/.wget-hsts` | wget | already handled via alias in `010-general` |
| `~/.zshrc` | Zsh | not primary shell; remove if unused |

**Note:** Consider symlinking `~/.config -> $DOTFILES/config` to handle apps
that hardcode `$HOME/.config` rather than respecting `$XDG_CONFIG_HOME`. This
would make both paths resolve to the same location without needing per-app
symlinks. Risk: `~/.config` becomes the canonical store for all XDG config,
so anything the OS or other tools write there lands directly in the repo
working tree — evaluate carefully before implementing.

## 🧪 Testing (HIGH PRIORITY)

### Phase 2: Test Infrastructure
- [ ] Review and enhance existing BATS tests
- [ ] Ensure meta-tests are up to date (`./tests/build-meta-tests`)
- [ ] Create test fixtures in `tests/fixtures/`
- [ ] Create helper functions in `tests/helpers/common.bash`

### Phase 3: Core Test Coverage
- [ ] Add tests for shell-startup
  - [ ] Test DOTFILES detection
  - [ ] Test PATH building
  - [ ] Test module loading without errors
- [ ] Add tests for critical bin/ scripts
  - [ ] cleanpath (unit tests)
  - [ ] yesno (unit tests)
  - [ ] git-status (integration tests)
  - [ ] check-dotfiles (integration tests)
- [ ] Add tests for lib/ libraries
  - [ ] debug
  - [ ] strings
  - [ ] Arrays
  - [ ] is
  - [ ] parse_params
- [ ] Add tests for config/shell-startup/ modules
  - [ ] Test conditional loading
  - [ ] Test error handling

### Phase 4: Extended Coverage
- [ ] Completion tests for config/completions/
- [ ] Integration tests for tool configurations
- [ ] Performance tests for PATH building

### Test Infrastructure
- [ ] tests/build-meta-tests:5,6,71 - Add tests for sh compilation, improve
  shebang check, handle symbolic links (XXX)

### Comprehensive BATS Test Coverage Audit (MEDIUM PRIORITY)

Phase 3 covers a handful of critical scripts. This task is a full pass to
ensure everything that should have tests does.

- [ ] Inventory all scripts in `bin/` and classify each:
  - Already tested (Phase 3 covers cleanpath, yesno, git-status, check-dotfiles)
  - Needs unit tests (pure logic, no external deps)
  - Needs integration tests (calls external tools, modifies state)
  - Wrapper/trivial — document why tests aren't needed
- [ ] Write `test_<script>.bats` for each untested bin/ script
- [ ] Evaluate what else needs BATS tests beyond bin/:
  - [ ] `lib/` libraries (surface area for reuse bugs)
  - [ ] `config/shell-startup/` modules (sourcing, conditional logic)
  - [ ] `bin/check-dotfiles` and dotlinks behavior
  - [ ] Any scripts in other locations (setup-work, etc.)
- [ ] Ensure `tests/build-meta-tests` generates tests for all new scripts
- [ ] Update Phase 3 checklist once items are covered here

## 🧠 Claude Rules Files (MEDIUM PRIORITY)

Rules files in `config/claude/rules/` (global, `~/.claude/rules/`) tell the
agent how to use each tool. Already have: bash.md, perl.md, powershell.md,
pre-commit.md, python.md.

- [x] Check `../dotvim` for existing tool parameters before writing rules
  (shellcheck and shfmt configs are known to be there via ALE)
- [ ] Audit all tools in use across the repo and create missing rules files:
  - [x] shellcheck — inline disable conventions; .shellcheckrc location is an
    open question (global vs repo-local vs both) documented in the rules file
  - [x] shfmt — flags `-i 2 -s -bn -ci -sr` from dotvim ALE config
  - [x] `.editorconfig` for shfmt: repo-root `.editorconfig` encodes
    `indent_size`, `binary_next_line`, `switch_case_indent`,
    `space_redirects`. Only `-s` remains CLI-only (no editorconfig
    equivalent). Rules doc covers both forms (with/without editorconfig).
  - [x] yamllint — config file location, common relaxations
  - [x] markdownlint — line length, allowed HTML, rules to disable
  - [x] yapf — already have config/yapf; document how agent should invoke it
  - [x] git — commit conventions, branch naming, worktree workflow reference
  - [x] bats — test structure expectations, helper usage
  - [x] docker — image pinning, layer hygiene, security, compose rules
  - [x] gh — PR/issue conventions; fork-mode PR target; worktree skill ref
  - [ ] new project setup — rule covering the general checklist for
    initializing a project (git init, pre-commit, .claude/ scaffold,
    DEVELOPER.md, TODO.md, etc.); evaluate splitting language-specific
    bootstrapping steps (e.g. NeoForge MDK, Poetry, npm init) into the
    relevant per-language rules file rather than bloating the general rule.
    Points to consider from experience:
    - Investigate actual storage/file formats before designing around them;
      official docs may describe outdated formats (e.g. JourneyMap switched
      from per-waypoint JSON to a binary DAT in 6.x without updating docs)
    - Check whether related/foreign repos are already cloned as siblings
      before suggesting clone locations (../reponame convention)
    - Defer .claude/ scaffold until project-specific conventions emerge;
      Phase 0 setup rarely produces enough repo-specific content to justify it
    - Editor config belongs in the editor's own config repo, not the project;
      DEVELOPER.md should note the maintainer's editor but not prescribe setup
    - When adding language support to an editor config, verify that
      indentation and formatting settings match the chosen formatter's output
      rather than blindly following language community conventions (e.g.
      google-java-format uses 2-space, not the traditional 4-space Java style)
    - New project setup frequently exposes gaps in existing global config
      (missing docs, redundant settings, stale paths); capture these as
      follow-up items in the relevant repo's TODO rather than blocking setup
    - DEVELOPER.md should cover the full build/test workflow including
      platform-specific quirks (e.g. build in WSL2, test in Windows Minecraft)
    - Pin pre-commit hook versions to current stable at time of setup;
      note that versions need periodic review as hooks release updates
    - Document the rationale for non-obvious decisions (e.g. why 2-space
      Java indent) so future sessions don't relitigate them
  - [ ] commitizen — rule and/or skill for conventional commit message
    formatting; evaluate whether a rule (policy + invocation) is sufficient
    or whether the multi-step workflow warrants a skill
  - [ ] git tagging — rule and/or skill for version tag conventions (semver
    vs calver, signed vs unsigned, when to tag vs branch, how tags relate
    to release branches); likely a rule unless the tagging+push+release
    sequence is complex enough to warrant a skill
  - [ ] changelog generation — rule and/or skill for producing changelogs
    from git history on version changes; evaluate tools (git-cliff,
    conventional-changelog, keep-a-changelog manual pattern) and whether
    changelog generation should be part of a broader release skill alongside
    tagging and commitizen
  - [ ] Any other tools discovered during pre-commit or CI work
- [x] Consider a template for new rules files so they stay consistent
- [ ] Add a "best practices" rules/skills layer. The current
  `rules/code-style.md` may be better recast as a general best-practices
  document with language-specific subdocuments — i.e. a shared core that
  per-language rules files extend. Decide structure: one general
  best-practices doc + per-language extensions, vs. keeping `code-style.md`
  as the shared base that the language rules reference.
- [ ] When creating/modifying a rule or skill, check known sources for an
  existing implementation to adapt (vendor with a `SOURCE.md` and audit to
  fit) rather than authoring from scratch:
  - GitHub (search repos/topics)
  - https://github.com/VoltAgent/awesome-agent-skills
  - https://officialskills.sh/
  - other locations as discovered
  Ties into the vendored file/skill update checker (see Configuration
  Enhancements → Dependency Management).

## 🪝 Claude Code PostToolUse Hooks (MEDIUM PRIORITY)

Rules files instruct the agent to run shellcheck/shfmt, but only if the agent
remembers. `PostToolUse` hooks in `settings.json` enforce this automatically
after every `Edit` or `Write` on a shell file.

- [ ] Decide hook approach:
  - Option A: inline command in `settings.json` (simple, but not version-controlled
    separately from settings)
  - Option B: `config/claude/bin/post-edit-shell.sh` script invoked by the hook
    (keeps logic in a file, easier to maintain)
- [ ] Implement hook in `config/claude/settings.json`:
  - Match on `Edit` and `Write` tool use
  - Detect if the modified file is a shell file (by path pattern or shebang)
  - Run `shfmt -i 2 -s -bn -ci -sr -w <file>` then `shellcheck <file>`
  - Output failures so Claude sees them and can fix before continuing
- [ ] Research Claude Code hook input format: what env vars / stdin does a
  `PostToolUse` hook receive? (need file path of edited file)
- [ ] Document hook setup in this repo's WORKFLOW.md once stable

## 🔒 Pre-commit Configuration (HIGH PRIORITY)

**Key Rule:** CI/CD Phase N requires Pre-commit Phase N completed first.
Pre-commit can progress independently. CI/CD cannot lead pre-commit.

### Phase 1: Core Hooks (NEXT PRIORITY)
- [ ] Create `.pre-commit-config.yaml` with core hooks:
  - [ ] shellcheck (bash script linting)
  - [ ] shfmt (shell formatting check, not fix)
  - [ ] yamllint (YAML syntax)
  - [ ] markdownlint (Markdown formatting)
  - [ ] trailing-whitespace
  - [ ] end-of-file-fixer (check mode)
  - [ ] check-yaml
  - [ ] check-json
  - [ ] check-merge-conflict
  - [ ] check-added-large-files
- [ ] Create `.pre-commit-config-fix.yaml` with auto-fix hooks:
  - [ ] shfmt -w (write mode)
  - [ ] prettier (formatting)
  - [ ] end-of-file-fixer (fix mode)
  - [ ] trailing-whitespace (fix mode)
- [ ] Test pre-commit configuration with sample files
- [ ] Document pre-commit usage in README.md
- [ ] Update all `config/claude/rules/*.md` Agent Behavior sections to
  prioritize pre-commit over direct tool invocation:
  - Normal ops: `pre-commit run --files <file>` instead of `shfmt`/`shellcheck`/etc.
  - Fix ops: `pre-commit run --config .pre-commit-config-fix.yaml --files <file>`
  - Direct tool invocation becomes the fallback when pre-commit is not
    configured or the file is not covered by any hook

### Phase 2: Security Hooks
- [ ] Add security checks to `.pre-commit-config.yaml`:
  - [ ] gitleaks (secret detection)
  - [ ] detect-private-key
- [ ] Test security hooks on repository
- [ ] Update documentation

### Phase 3: Language-Specific Hooks
- [ ] Add Python hooks (commented/conditional):
  - [ ] black (formatting check)
  - [ ] isort (import sorting check)
  - [ ] flake8 (linting)
  - [ ] mypy (type checking)
- [ ] Add Perl hooks:
  - [ ] perlcritic (linting)
  - [ ] perltidy (formatting check)
- [ ] Add Rust hooks (if applicable):
  - [ ] cargo fmt (check mode)
  - [ ] clippy (linting)
- [ ] Update fix configuration with language-specific auto-fixes
- [ ] Test with actual project files
- [ ] Update documentation

### Phase 4: Documentation Linting
- [ ] Add documentation quality hooks:
  - [ ] proselint (prose linting)
  - [ ] Additional markdown checks
  - [ ] Link validation
- [ ] Test on repository documentation
- [ ] Update documentation

## 🚀 CI/CD Workflows (HIGH PRIORITY)

**Dependency:** Each CI/CD phase requires corresponding Pre-commit phase.

### Phase 1: Basic CI (requires Pre-commit Phase 1)
- [ ] Create `.github/workflows/ci.yml`:
  - [ ] Run on push to master
  - [ ] Run on pull requests
  - [ ] Execute BATS tests
  - [ ] Run shellcheck
  - [ ] Run yamllint
  - [ ] Run markdownlint
  - [ ] Report results as job status
- [ ] Test workflow with sample PR
- [ ] Document CI workflow

### Phase 2: Security Checks (requires Pre-commit Phase 2)
- [ ] Add security job to CI workflow:
  - [ ] Run gitleaks
  - [ ] Run detect-private-key
  - [ ] Block merge on security failures
- [ ] Test security checks
- [ ] Document security workflow

### Phase 3: Language Checks (requires Pre-commit Phase 3)
- [ ] Add language-specific jobs:
  - [ ] Python testing and linting
  - [ ] Perl linting
  - [ ] Rust checks (if applicable)
- [ ] Matrix testing for multiple bash versions (optional)
- [ ] Test language-specific jobs
- [ ] Document language workflows

### Phase 4: Documentation Validation (requires Pre-commit Phase 4)
- [ ] Add documentation quality job:
  - [ ] Prose linting
  - [ ] Link checking
  - [ ] Documentation build tests
- [ ] Test documentation workflow
- [ ] Document validation process

### Optional: Dependency Updates
- [ ] Create `.github/workflows/update-deps.yml`:
  - [ ] Check for git-completion.bash updates
  - [ ] Check for git-prompt.sh updates
  - [ ] Create PR if updates available
  - [ ] Weekly schedule
- [ ] Test update workflow
- [ ] Document update process

## 💻 Code Improvements (LOW PRIORITY)

### Shell-startup Issues
- [x] shell-startup:26 - Removed dead Windows MSYS block (see docs/windows-notes.md)
- [x] shell-startup:94 - Added --first/-f and --last/-l options to addpath
- [x] shell-startup:114 - Replaced XXX with description comment; run_hook is valid
- [x] shell-startup:180 - Removed dead placeholder export-script block
- [ ] Move the grok installer block out of the top-level `shell-startup`
  file into a dedicated `config/shell-startup/` module (e.g. `0NN-grok`).
  The grok installer appends directly to `shell-startup`, which is the
  wrong location and risks duplicate blocks on re-install; relocate it and
  guard against re-append.

### shell-startup: Shell Context Detection (HIGH PRIORITY)

`shell-startup` is symlinked from `.bashrc`, `.bash_profile`, and `.profile`,
but currently runs identically regardless of context. Shells have four main
contexts that need different behavior:

- **interactive login** — full environment, aliases, functions, prompts
- **interactive non-login** — already has login env; needs aliases, prompts
- **non-interactive login** — rare; env vars only, no aliases
- **non-interactive non-login** — scripts/subshells; env vars only, no
  aliases, no prompts (e.g., shell spawned from vim, cron, ssh command)

Problems to solve:

- [ ] Guard against double-sourcing — detect if shell-startup has already
  run and skip (or only run the parts appropriate to context)
- [ ] Detect shell context (`$-` contains `i` for interactive; login shells
  set by checking `shopt login_shell` or `$0` prefix `-`)
- [ ] Skip alias/function/prompt setup for non-interactive shells
- [ ] Handle incomplete terminal environments gracefully (e.g., vim shell,
  docker exec, ssh command) — these may lack `TERM`, `COLUMNS`, etc.
- [ ] Audit `config/shell-startup/` modules: tag or split each module by
  required context (env-only vs interactive-only)
- [ ] Write integration tests using Docker to cover each context:
  - Use a minimal Docker image with bash and the dotfiles mounted/installed
  - [ ] Interactive login: `docker run -it` with login shell (`bash -l`)
    — verify aliases, functions, prompt, and full env are set
  - [ ] Interactive non-login: `docker run -it` without `-l`
    — verify aliases/prompt present, env inherited correctly, no double-init
  - [ ] Non-interactive login: `docker run` with `bash -lc 'command'`
    — verify env vars set, aliases/prompt NOT defined
  - [ ] Non-interactive non-login: `docker run` with `bash -c 'command'`
    — verify minimal env only, no aliases, no prompt, no errors
  - [ ] Incomplete terminal (vim-style): simulate missing `TERM`/`COLUMNS`
    — verify shell-startup degrades gracefully without errors
  - [ ] Double-source guard: source shell-startup twice in same session
    — verify idempotent (no duplicate PATH entries, no re-run of setup)
  - [ ] Research: can/should BATS drive Docker-based tests? Options include
    running BATS inside the container, or using BATS on the host to `docker
    run` and assert on exit codes and output. Determine which approach fits
    the existing test framework and document the decision in TESTS.md
  - [ ] Update TESTS.md to document Docker-based integration test approach

### bin/cleanpath: Fix and Integrate (HIGH PRIORITY)

`bin/cleanpath` deduplicates PATH-style colon-separated variables but is
currently broken. `bin/CleanPath.tmp` appears to be a duplicate/scratch copy.

- [ ] Audit `bin/cleanpath` vs `bin/CleanPath.tmp` — determine which is
  canonical, remove the other (CleanPath.tmp has XXX: Document me, Test me)
- [ ] Fix `bin/cleanpath` so it works correctly (diagnose current failure)
- [ ] Add unit tests (`tests/test_cleanpath.bats`)
- [ ] Integrate into `shell-startup` — run cleanpath on PATH (and possibly
  other path vars like `LD_LIBRARY_PATH`, `MANPATH`) after `load_files`
  to eliminate duplicates accumulated during module loading

### PowerShell Improvements
- [ ] ps-startup.ps1:49 - Move Python path to dedicated setup file (XXX)
- [ ] 010-general.ps1:27,42,54,59 - Port remaining bash features marked with XXX

### PowerShell: Linux Dev/Test Environment (RESEARCH FIRST)

Before doing PowerShell work, research whether Linux PowerShell Core (`pwsh`)
is a viable dev/test environment for scripts intended to run on Windows
PowerShell 5.1.

- [ ] Research compatibility between `pwsh` (Core) and Windows PowerShell 5.1:
  - Known gaps: COM objects, Windows-only modules (`ActiveDirectory`, etc.),
    `$PSVersionTable.PSEdition` differences, some .NET APIs
  - Determine if `ps-startup.ps1` and `config/powershell/` scripts use any
    Windows-only features that would break under `pwsh` on Linux
  - Check if Pester (PowerShell test framework) runs identically on both
- [ ] Research using Docker for PowerShell testing:
  - Microsoft publishes official `mcr.microsoft.com/powershell` images
    (Linux-based `pwsh`) — suitable for CI and local testing
  - Investigate whether a Windows container (`mcr.microsoft.com/windows/...`)
    would be needed to test true Windows PowerShell 5.1 behavior, and
    whether that's practical (requires Windows host for Windows containers)
  - Document the recommended approach and its limitations in TESTS.md
- [ ] If Linux `pwsh` + Docker is viable: set up a test harness (likely
  Pester inside the container) before tackling the improvement tasks above

### Bin Scripts
- [x] git-all:3 - Refactored: replaced missing utility functions inline, fixed
  shellcheck issues (SC2155, unquoted vars, array appends)
- [x] git-status:3 - Add STASH information (XXX)
- [x] yesno:33 - Add option to suppress warnings (XXX)

### Library Documentation and Testing
- [ ] lib/debug:3,4 - Test (documented)
- [ ] lib/strings:7,8,9 - Document, test, enforce sourcing only (XXX)
- [ ] lib/Arrays:7,8,9,38 - Document, test, enforce sourcing, consider moving to
  tools/bin (XXX)
- [ ] lib/is:3,4,9 - Document, test, check for being sourced (XXX)
- [ ] lib/parse_params:3 - Test (XXX)

### Configuration File Issues
- [x] config/perl:12,54 - Existing checks are adequate; removed stale XXX
  markers and commented-out alternative
- [x] config/less:85,86 - lesspipe.sh handles syntax highlighting; removed XXX
- [x] config/tmux:37 - Detect multiple sessions (XXX)
- [x] config/terraform:9 - Comparison done; cleaned up XXX and dead code
- [x] config/taskwarrior:8,9,10 - Removed aspirational XXX markers (sourcing
  check unnecessary for shell-startup module; taskwarrior scripts item
  tracked below under Tool Configurations)
- [ ] config/bash_prompt:131,137 - Fix poetry/venv detection and colors (XXX)
- [ ] config/git/config:239-240 - `bd` / `bD` aliases collide because git
  config keys are case-insensitive. `bD` overwrites `bd`, so `git bd`
  force-deletes instead of safe-deleting. Rename `bD` to a case-distinct
  key (e.g. `bdf` for force-delete) so both intents are reachable. See
  XXX comment in file.
- [ ] config/git/config:199-200 - `unstage` / `unadd` have swapped
  semantics relative to common terminology: `unstage` resets to HEAD^
  (undoes last commit), `unadd` resets to HEAD (actual unstage). Either
  rename for clarity or document the convention in docs/git_aliases.md.
  See XXX comment in file.

## ⚙️ Configuration Enhancements (LOW PRIORITY)

### Bash Completion
- [ ] Enable bash completion for available but unconfigured tools
- [ ] Document completion setup in dedicated section or inline
- [ ] Create completion tests

### Prompt Enhancements
- [ ] bash_prompt:131 - Fix poetry venv detection
- [ ] bash_prompt:137 - Fix manual venv color issue

### Shell Helpers
- [ ] Evaluate creating a reusable `select`/menu helper (sibling to
  `yesno`) for enumerated-option prompts
  - Survey existing callers in `bin/` and `config/shell-startup/` that
    roll their own selection logic or use bare `select`
  - Decide: dedicated `bin/` script (like `yesno`, `anykey`) vs. shell
    function in `config/shell-startup/`
  - Required behavior: numbered options, re-prompt on invalid input,
    optional default, quiet mode, return selected value on stdout
  - If justified, implement it first and have the `proj` task above
    use it

## 🖥️ Statusline Coordination (MEDIUM PRIORITY)

Goal: avoid repeating the same information across the four statusline surfaces
(bash prompt, tmux status bar, vim statusline, Claude statusline). Each surface
should own a distinct slice of context.

Proposed ownership split (to be refined during implementation):

- **bash prompt** — exit code, venv/conda name, git branch+dirty state (when
  not in tmux or vim)
- **tmux status bar** — host, session name (multi-session only), clock, weather
- **vim statusline** — filename, filetype, linting errors, vim mode; git branch
  only when not in tmux
- **Claude statusline** — model name, context window %, session cost, worktree
  name; suppress anything already shown by tmux (e.g. git branch) when $TMUX
  is set

Context detection: use `$TMUX`, `$VIM`/`$VIMRUNTIME`, and
`$CLAUDE_SESSION_ID` (if available) to suppress duplicate info at each layer.

### Task 1: Claude Statusline Script (MEDIUM PRIORITY)

Docs: https://code.claude.com/docs/en/statusline

- [x] Decided location: Option B — `config/claude/bin/statusline.sh` (`~/.claude/bin/`)
  - `~/.claude/` IS `config/claude/` in this setup (no symlink needed)
  - Script is Claude-session-only → keep it claude-adjacent, not in general bin/
  - `statusLine.command` accepts any path; no requirement to be under `~/.claude/`
- [x] Created `config/claude/bin/statusline.sh`:
  - Shows: `model.display_name | ctx N% | $cost`
  - Context % colored cyan < 50%, yellow 50–74%, red ≥ 75%
  - All jq fields use `// fallback`; graceful exit if jq missing
- [x] Wired up in `config/claude/settings.json`:
  `"statusLine": { "type": "command", "command": "~/.claude/bin/statusline.sh", "refreshInterval": 5 }`
- [ ] Observe in a live session and tune (model name length, field order, colors)
- [x] Worktree marker: added to `bin/git-status` (shows `[wt:<main-repo>]`
  when in a linked worktree); surfaces automatically via the `git-status`
  segment in the Claude statusline
- [ ] Consider suppressing model name when $TMUX is set (if tmux bar shows it)

### Task 2: Unified Statusline Strategy (LOW PRIORITY — do after Task 1)

Once the Claude statusline exists, audit all four surfaces together:

- [ ] Inventory what each surface currently shows:
  - bash prompt (`config/bash_prompt`, `bin/git-status`)
  - tmux (`config/tmux/tmux.conf` status-left/right)
  - vim (vimrc / airline / lightline config in `../dotvim`)
  - claude (`config/claude/statusline.sh` — built in Task 1)
- [ ] Identify duplicates and decide canonical owner for each piece of info
- [ ] Implement suppression logic using context env vars (`$TMUX`, `$VIM`, etc.)
  - This subsumes the existing "if in tmux, disable git-status in bash prompt"
    and "consider adding git-status to vim status line (except when in tmux)"
    items from the old Prompt Enhancements list
- [ ] Update `bin/git-status` to respect context flags
- [ ] Document the ownership split in a comment block or inline README

### Tool Configurations
- [ ] Look into lesshst/lesskey configuration
- [ ] Look into taskwarrior scripts from /usr/share/doc/task/scripts/
- [ ] Look into colorized columns tool:
  https://github.com/LukeSavefrogs/column_ansi.git

### Dependency Management
- [ ] Create check4update script for git completion files:
  - git-prompt.sh
  - git-completion.bash
- [ ] Set up automated or manual update process

### Vendored file / skill update checker

Some files are **vendored** (copied in from an upstream repo) rather than
authored here — e.g. `config/claude/skills/frontend-design/` from
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
  - Option B: `config/claude/bin/check-vendored-skills` — Claude-scoped;
    limits to `config/claude/skills/*/SOURCE.md`.
  - Likely both: a general `bin/` core that does the work, plus a thin
    `config/claude/bin/` entry that scopes it to skills.
- [ ] Generalize the `SOURCE.md` provenance convention (repo / path / SHA /
  local-edits) and document it (WORKFLOW.md or a rules file).
- [ ] Consider folding the git-completion `check4update` item above into
  this same mechanism (give those files a `SOURCE.md` too).
- [ ] Optional: wire it to a periodic nudge (Claude `/schedule` or a CI
  `update-deps.yml` job — see CI/CD "Dependency Updates").

## 🔍 Research and Exploration (LOW PRIORITY)

- [ ] Look into serena MCP server: https://github.com/oraios/serena
- [ ] Look into pyscn tool: https://github.com/ludo-technologies/pyscn
  - [ ] Install via: `pipx install pyscn`
- [ ] Document bash changes resource:
  https://web.archive.org/web/20230401195427/https://wiki.bash-hackers.org/scripting/bashchanges

## 🤖 Claude Code -> local OpenWebUI offload (HIGH IMPORTANCE, LOW PRIORITY)

**Importance: high** (cost, privacy, and actually leveraging the dedicated
AI box, `beaker`). **Priority: low** (exploratory; depends on beaker's GPU
stack being finished and on finding the right integration point).

Idea: route the simpler, high-volume Claude Code subtasks to a locally
hosted model served from my own OpenWebUI/Ollama on `beaker` (see
`bin/openwebui`, `bin/ollama`), keeping the heavy reasoning on Claude.
Start with cheap, well-bounded work — qa-check triage, running and
evaluating test output, summaries — then generalize.

- [ ] Find the integration surface. Claude Code's main loop is
  Anthropic-only, so investigate the realistic hook points:
  - a **hook** (`PostToolUse`, etc.) that shells out to a local-LLM
    script for a specific check;
  - a **subagent** or **MCP server** that wraps the local endpoint;
  - the **Claude Agent SDK** for a custom delegating agent.
- [ ] Pick the API: OpenWebUI exposes an OpenAI-compatible endpoint;
  Ollama serves its own API on `:11434`. Decide which to target.
- [ ] Choose local model(s) sized for beaker's RTX 4080 (~12 GB VRAM) and
  capable enough for the offloaded tier (code-aware small/mid models).
- [ ] Define the task split: what is safe to delegate (triage, test-output
  evaluation, summarization) vs. what stays on Claude.
- [ ] Evaluate quality / cost / latency on real tasks before adopting; keep
  a fallback to Claude when the local model is unsure.
- [ ] Depends on: beaker GPU setup (driver + NVIDIA Container Toolkit) and
  ollama/openwebui running.

## 📋 Template Creation (LOW PRIORITY - FUTURE WORK)

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

See original TODO.md (archived) for detailed template specifications if needed
in the future.

## 📊 Progress Tracking

**Documentation:** ~80% complete (foundation laid, cleanup remaining)
**Testing:** ~20% complete (framework defined, implementation needed)
**Pre-commit:** ~0% complete (ready to start Phase 1)
**CI/CD:** ~10% complete (one workflow exists, needs expansion)
**Code Improvements:** ~0% complete (cataloged, not addressed)
**Config Enhancements:** ~0% complete (cataloged, not addressed)

## 🎯 Next Actions (Priority Order)

1. **Pre-commit Phase 1** - Create core pre-commit configuration
2. **CI/CD Phase 1** - Expand GitHub Actions with basic CI
3. **Testing Phase 2** - Review and enhance test infrastructure
4. **Testing Phase 3** - Add core test coverage for critical components
5. **Pre-commit Phase 2** - Add security hooks
6. **CI/CD Phase 2** - Add security checks to CI

## Notes

- **HIGH PRIORITY** items should be completed first
- **LOW PRIORITY** items can be deferred or completed incrementally
- Pre-commit phases can progress independently
- CI/CD phases MUST NOT lead pre-commit phases (dependencies enforced)
- Code improvements and config enhancements are cataloged but can be addressed
  opportunistically
- Template creation is extensive future work, deferred for now

## Version History

- **v1.0.0** (2026-01-18): Initial consolidated TODO based on modernization
  plan. Documented completed tasks, organized remaining work by phase and
  priority.

## References

- **[WORKFLOW.md](.claude/WORKFLOW.md)**: Development guidelines and conventions
- **[TESTS.md](.claude/TESTS.md)**: Testing framework and strategy
- **[CLAUDE.md](config/claude/CLAUDE.md)**: AI agent behavior specification
- **[config/claude/rules/pre-commit.md](config/claude/rules/pre-commit.md)**:
  Pre-commit agent policy
- **Modernization Plan**: Full plan available in conversation transcript
