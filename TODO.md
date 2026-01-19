# TODO - Dotfiles Repository Modernization

**Last Updated:** 2026-01-18
**Plan Version:** Based on Dotfiles Repository Modernization Plan

This TODO file tracks the modernization effort for the dotfiles repository,
organized by work area with phase markers. See `WORKFLOW.md` for development
guidelines and `TESTS.md` for testing strategy.

## ✅ Completed Documentation Tasks

- [x] Create WORKFLOW.md (foundation document)
- [x] Create TESTS.md (foundation document)
- [x] Fix README.md broken link (GIT_ALIASES.md → docs/git_aliases.md)
- [x] Add missing 13 shell-startup tools to README.md documentation
- [x] Add XDG Base Directory section to README.md
- [x] Document all 37+ config directories in README.md
- [x] Update docs/bin.md with descriptions for all 35 bin scripts
- [x] Add core documentation references to README.md

## 📝 Documentation (HIGH PRIORITY)

### Immediate Tasks
- [ ] Review and consolidate docs/ directory
  - [ ] Evaluate docs/bash-completion.md - move inline or keep as overview?
  - [ ] Consider moving docs/git_aliases.md to config/git/ or config/shell-startup/git
  - [ ] Ensure all remaining docs follow WORKFLOW.md philosophy

### Code Comment Cleanup
- [ ] Address XXX/TODO/FIXME comments (convert to documentation or fix)
  - See "Code Improvements (LOW PRIORITY)" section for detailed list

## 🧪 Testing (HIGH PRIORITY)

### Phase 1: Framework Definition ✅
- [x] Define testing framework in TESTS.md
- [x] Document test types and organization
- [x] Define test requirements and standards

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

### PowerShell Improvements
- [ ] ps-startup.ps1:49 - Move Python path to dedicated setup file (XXX)
- [ ] 010-general.ps1:27,42,54,59 - Port remaining bash features marked with XXX

### Bin Scripts
- [ ] CleanPath.tmp:3,4 - Document or remove temp file (XXX: Document me, Test
  me)
- [ ] git-all:3 - Refactor to current standards or remove (TODO: Finish updating
  or scrap)
- [ ] git-status:3 - Add STASH information (XXX)
- [ ] yesno:33 - Add option to suppress warnings (XXX)

### Library Documentation and Testing
- [ ] lib/debug:3,4 - Document and test (XXX)
- [ ] lib/strings:7,8,9 - Document, test, enforce sourcing only (XXX)
- [ ] lib/Arrays:7,8,9,38 - Document, test, enforce sourcing, consider moving to
  tools/bin (XXX)
- [ ] lib/is:3,4,9 - Document, test, check for being sourced (XXX)
- [ ] lib/parse_params:3 - Test (XXX)

### Configuration File Issues
- [ ] config/perl:12,54 - Check for completion capability, test if bakeini is
  installed (XXX)
- [ ] config/less:85,86 - Figure out lesspipe.html and syntax highlighting (XXX)
- [ ] config/tmux:37 - Detect multiple sessions (XXX)
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

- **[WORKFLOW.md](WORKFLOW.md)**: Development guidelines and conventions
- **[TESTS.md](TESTS.md)**: Testing framework and strategy
- **[AGENTS.md](AGENTS.md)**: AI agent behavior specification
- **[docs/agents/pre-commit.md](docs/agents/pre-commit.md)**: Pre-commit agent
  policy
- **Modernization Plan**: Full plan available in conversation transcript
