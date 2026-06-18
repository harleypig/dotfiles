# Repository Workflow

**Version:** v1.1.0

## Purpose

This document defines repository-specific workflow rules, development
guidelines, and tool setup procedures. It provides concrete operational
guidance that extends and, where necessary, overrides `CLAUDE.md`.

For testing procedures and framework details, see `TESTS.md`.

**Precedence hierarchy:** `WORKFLOW.md` > `TESTS.md` > `CLAUDE.md`

Repository-specific rules in this document override general principles in
`CLAUDE.md`. Testing-specific rules in `TESTS.md` override both `WORKFLOW.md`
and `CLAUDE.md` for test-related operations.

## Repository Structure

### Core Directories

* **`bin/`** - Executable scripts and utilities
* **`lib/`** - Shared shell libraries (sourced, not executed)
* **`config/`** - Configuration files organized by tool/application
* **`config/shell-startup/`** - Modular shell initialization files
* **`tests/`** - Test files using BATS framework
* **`docs/`** - Supplementary documentation (minimal, prefer inline)
* **`.github/`** - GitHub Actions workflows and templates

### Special Files

* **`shell-startup`** - Main shell initialization orchestrator
* **`ps-startup.ps1`** - PowerShell initialization for Windows
* **`CLAUDE.md`** - AI agent behavior specification
* **`WORKFLOW.md`** - This file
* **`TESTS.md`** - Testing framework and strategy
* **`TODO.md`** - Consolidated task tracking

## Development Workflow

### Documentation Philosophy

**Principle:** Documentation lives WITH code

1. **Individual files document themselves**
   * Scripts in `bin/`: Usage documentation in comments or `--help` output
   * Modular configs in `config/shell-startup/`: Inline comments
   * Configuration directories: `README.md` or inline documentation
   * Libraries in `lib/`: Docstrings and inline comments

2. **`README.md` (root): Minimal setup + navigation only**
   * How to set up new instance
   * Where to find specific documentation
   * High-level overview
   * Navigation pointers

3. **`docs/` directory: Minimize or eliminate**
   * Move documentation inline when possible
   * Keep only overviews or cross-cutting concerns
   * Avoid duplicating information available elsewhere

### XDG Base Directory Compliance

This repository follows XDG Base Directory specifications:

* **`$XDG_CONFIG_HOME`** (default: `~/.config`) - Configuration files
* **`$XDG_DATA_HOME`** (default: `~/.local/share`) - Data files
* **`$XDG_CACHE_HOME`** (default: `~/.cache`) - Cache files
* **`$XDG_STATE_HOME`** (default: `~/.local/state`) - State files

When creating new configurations or modifying existing ones, agents MUST:

* Use XDG variables when supported by the tool
* Document XDG paths in tool-specific READMEs
* Provide fallbacks for tools that don't support XDG

### Pre-commit Workflow

**Policy:** See `.claude/rules/pre-commit.md` for complete rules.

**Quick reference:**

* **Default mode: Check-only** (`.pre-commit-config.yaml`)
  * Runs on git commit
  * Blocks commit on failures
  * Read-only checks, no modifications

* **Fix mode: Auto-fix** (`.pre-commit-config-fix.yaml`)
  * Run manually: `pre-commit run --config .pre-commit-config-fix.yaml --all-files`
  * Modifies files to fix issues
  * Use before committing or to clean up repository

**Phased implementation:**

1. **Phase 1 (Core):** shellcheck, yamllint, markdownlint, trailing-whitespace
2. **Phase 2 (Security):** gitleaks, detect-private-key
3. **Phase 3 (Language):** Python, Perl, Rust hooks
4. **Phase 4 (Docs):** proselint, additional documentation linting

Agents MUST complete each phase before implementing the next. GitHub Actions
CI workflows MUST NOT include hooks from a phase until that phase is complete
in the pre-commit configuration.

### Testing Workflow

**Framework:** BATS (Bash Automated Testing System)

**See `TESTS.md` for this repo's testing strategy, and the global
`config/claude/rules/bats.md` for bats conventions.**

**Quick reference:**

* Run the gating suite: `bats tests/shell/test_*.bats`
* Run everything present: `bats tests/shell/`
* Run a specific file: `bats tests/shell/test_<name>.bats`
* Regenerate meta tests: `tests/scaffold/build-meta-tests`
* Tests MUST pass before merging to master
* New functionality MUST include tests

### Git Workflow

**Branch strategy:**

* **`master`** - Main branch, stable code
* Feature branches: `feature/<name>`
* Bugfix branches: `bugfix/<name>`
* Documentation: `docs/<name>`

**Pull requests:**

* Must pass all CI checks
* Pre-commit hooks must pass
* Tests must pass
* At least one review for significant changes

**Enforced branch protection (`master`):**

`master` is protected by a GitHub ruleset (`protect-master-solo.json` in
`../private_dotfiles/github-rulesets/`, enforcement active). It is **not**
advisory — the remote enforces it:

* **Direct pushes to `master` are rejected** — all changes land via PR.
* **Squash is the only allowed merge method.**
* **`bats`, `perl`, and `pre-commit` must be green** to merge (required
  status checks).
* Deletion and force-push of `master` are blocked; unresolved review threads
  block merge; stale reviews are dismissed on push.
* No bypass actors — even the owner goes through a PR.
* A local `no-commit-to-branch` pre-commit hook also blocks a direct commit
  to `master` at commit time (early guard; the server ruleset is what
  actually enforces it). See `config/claude/rules/git.md`.

To change the ruleset, edit the JSON and re-apply with the OAuth token (the
narrow PAT lacks admin):

```bash
GH_TOKEN= GITHUB_TOKEN= gh api repos/harleypig/dotfiles/rulesets/17364459 \
  --method PUT --input ../private_dotfiles/github-rulesets/protect-master-solo.json
```

**Merge-time finalization (`merge-finalization: enforce`):**

This repo opts in to the merge-time documentation finalization (ship-pr
Step 4.5). Completed items are **pruned outright** from `TODO.md` (and
`ROADMAP.md` if one exists) once the PR that finishes them goes green —
finalized work is migrated to [`CHANGELOG.md`](../CHANGELOG.md), not left as
`[x]` markers. The `merge-finalization: enforce` sentinel in the heading above
activates the `PreToolUse` hook (`~/.claude/hooks/merge-finalization.py`),
which **blocks** a `gh pr merge` / `ship.sh merge` while any completed `- [x]`
items still remain in the planning docs. See
`config/claude/skills/ship-pr/SKILL.md` and `config/claude/rules/git.md`.

## Tool Setup Procedures

### Prerequisites

Required tools for development:

* `bash` (4.0+)
* `git` (2.0+)
* `bats-core` (for testing)
* `pre-commit` (for pre-commit hooks)

Optional but recommended:

* `shellcheck` (shell script linting)
* `shfmt` (shell script formatting)
* `yamllint` (YAML linting)
* `markdownlint-cli` (Markdown linting)

### Initial Setup

1. Clone repository:

   ```bash
   git clone <repo-url> ~/dotfiles
   ```

2. Install pre-commit:

   ```bash
   pip install pre-commit
   # or
   brew install pre-commit
   ```

3. Install pre-commit hooks:

   ```bash
   cd ~/dotfiles
   pre-commit install
   ```

4. Run tests to verify:

   ```bash
   bats tests/shell/
   ```

5. Follow setup instructions in root `README.md`

## Agent-Specific Overrides

### Pre-commit

* MUST follow phased implementation strategy.
* MUST ensure CI workflows match pre-commit configuration.
* MUST NOT advance to next phase until current phase is complete.
* MUST document any new hooks in `.claude/rules/pre-commit.md`.

## Integration Points

### External Services

Currently integrated:

* **GitHub Actions:** CI/CD workflows in `.github/workflows/`
* **OpenCode:** Issue management via `.github/workflows/opencode.yml`

### Environment Variables

Key environment variables used:

* `$DOTFILES` - Path to this repository
* `$XDG_CONFIG_HOME` - XDG config directory
* `$XDG_DATA_HOME` - XDG data directory
* `$XDG_CACHE_HOME` - XDG cache directory
* `$XDG_STATE_HOME` - XDG state directory

See individual tool configurations for additional variables.

## Maintenance

### Regular Tasks

* Review and update `TODO.md` as tasks are completed
* Update documentation when code changes
* Run `pre-commit run --all-files` periodically
* Review and address TODO/FIXME/XXX comments in code
* Keep git completion files updated (check upstream)

### Versioning

* `CLAUDE.md` - Versioned (see that file)
* `WORKFLOW.md` - Versioned (this file, v1.1.0)
* `TESTS.md` - Versioned (see that file)
* `.claude/rules/*.md` - Individual versions

Update version numbers when making significant changes to these files.

## Questions and Issues

* For general usage questions, see root `README.md`
* For agent behavior questions, see `CLAUDE.md`
* For testing questions, see `TESTS.md`
* For bug reports or feature requests, open a GitHub issue
