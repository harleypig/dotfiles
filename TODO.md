# TODO - Dotfiles Repository Modernization

**Last Updated:** 2026-04-18
**Plan Version:** Based on Dotfiles Repository Modernization Plan

This TODO file tracks the modernization effort for the dotfiles repository,
organized by work area with phase markers. See `WORKFLOW.md` for development
guidelines and `TESTS.md` for testing strategy.

## 📝 Documentation (HIGH PRIORITY)

### Immediate Tasks
- [ ] Review and consolidate docs/ directory
  - [x] Evaluate docs/bash-completion.md - moved to config/completions/README.md
  - [ ] Consider moving docs/git_aliases.md to config/git/ or config/shell-startup/git
  - [ ] Ensure all remaining docs follow WORKFLOW.md philosophy

### Code Comment Cleanup
- [ ] Address XXX/TODO/FIXME comments (convert to documentation or fix)
  - See "Code Improvements (LOW PRIORITY)" section for detailed list

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

- [ ] Check `../dotvim` for existing tool parameters before writing rules
  (shellcheck and shfmt configs are known to be there via ALE)
- [ ] Audit all tools in use across the repo and create missing rules files:
  - [ ] shellcheck — severity thresholds, disable conventions, SC codes to
    always suppress or always enforce
  - [ ] shfmt — indent style, switch-case indent, space-redirects flags
  - [ ] yamllint — config file location, common relaxations
  - [ ] markdownlint — line length, allowed HTML, rules to disable
  - [ ] yapf — already have config/yapf; document how agent should invoke it
  - [ ] git — commit conventions, branch naming, force-push policy
  - [ ] bats — test structure expectations, helper usage
  - [ ] docker — image pinning policy, layer hygiene
  - [ ] gh — PR/issue conventions for this repo
  - [ ] Any other tools discovered during pre-commit or CI work
- [ ] Consider a template for new rules files so they stay consistent

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
- [ ] shell-startup:26 - Clarify or fix Windows git bash setup (XXX: FIXME)
- [ ] shell-startup:94 - Add options for first and last place to addpath function
  (XXX)
- [ ] shell-startup:114 - Document or fix run_hook function behavior (XXX: Does
  this actually work?)
- [ ] shell-startup:180 - Clarify environment setup section (XXX: WTF am I
  trying doing here?)

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
- [ ] git-all:3 - Refactor to current standards or remove (TODO: Finish updating
  or scrap)
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
- [ ] config/perl:12,54 - Check for completion capability, test if bakeini is
  installed (XXX)
- [ ] config/less:85,86 - Figure out lesspipe.html and syntax highlighting (XXX)
- [x] config/tmux:37 - Detect multiple sessions (XXX)
- [ ] config/terraform:9 - Compare with gist (XXX)
- [ ] config/taskwarrior:8,9,10 - Add sourcing check, version check, look at
  scripts (XXX)
- [ ] config/bash_prompt:57,131,137 - Fix poetry/venv detection and colors (XXX)

### Test Infrastructure
- [ ] tests/build-meta-tests:5,6,71 - Add tests for sh compilation, improve
  shebang check, handle symbolic links (XXX)

## ⚙️ Configuration Enhancements (LOW PRIORITY)

### Bash Completion
- [ ] Enable bash completion for available but unconfigured tools
- [ ] Document completion setup in dedicated section or inline
- [ ] Create completion tests

### Prompt Enhancements
- [ ] bash_prompt:131 - Fix poetry venv detection
- [ ] bash_prompt:137 - Fix manual venv color issue
- [ ] Consider adding git-status to tmux status line
  - [ ] If in tmux, disable git-status in bash prompt
- [ ] Consider adding git-status to vim status line (except when in tmux)

### Tool Configurations
- [ ] Look into lesshst/lesskey configuration
- [ ] Review terraform completion gist comparison
- [ ] Look into taskwarrior scripts from /usr/share/doc/task/scripts/
- [ ] Look into colorized columns tool:
  https://github.com/LukeSavefrogs/column_ansi.git

### Dependency Management
- [ ] Create check4update script for git completion files:
  - git-prompt.sh
  - git-completion.bash
- [ ] Set up automated or manual update process

## 🔍 Research and Exploration (LOW PRIORITY)

- [ ] Look into serena MCP server: https://github.com/oraios/serena
- [ ] Look into pyscn tool: https://github.com/ludo-technologies/pyscn
  - [ ] Install via: `pipx install pyscn`
- [ ] Document bash changes resource:
  https://web.archive.org/web/20230401195427/https://wiki.bash-hackers.org/scripting/bashchanges

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
