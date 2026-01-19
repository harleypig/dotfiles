# Dotfiles Repository Workflow

**Version:** v1.0.0

## Purpose

This document defines repository-specific workflow rules, development
guidelines, and tool setup procedures for the dotfiles repository. It provides
concrete operational guidance that extends and, where necessary, overrides the
general principles defined in `AGENTS.md`.

This document conforms to the agent-consumed document schema defined in
`AGENTS.md`. For testing procedures and framework details, see `TESTS.md`.

**Precedence hierarchy:** `WORKFLOW.md` > `TESTS.md` > `AGENTS.md`

Repository-specific rules in this document override general principles in
`AGENTS.md`. Testing-specific rules in `TESTS.md` override both `WORKFLOW.md`
and `AGENTS.md` for test-related operations.

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
* **`AGENTS.md`** - Normative agent behavior specification
* **`WORKFLOW.md`** - This file
* **`TESTS.md`** - Testing framework and strategy
* **`TODO.md`** - Consolidated task tracking

## Development Workflow

### Documentation Philosophy

**Principle: Documentation lives WITH code**

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

4. **Agents creating documentation MUST:**
   * Prefer inline documentation over separate files
   * Create separate docs files only when explicitly requested
   * Place new docs WITH the code they document

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

**Policy:** See `docs/agents/pre-commit.md` (v1.0.0) for complete rules.

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

**See `TESTS.md` for complete testing strategy and requirements.**

**Quick reference:**

* Run all tests: `bats tests/`
* Run specific test: `bats tests/test_specific.bats`
* Tests MUST pass before merging to master
* New functionality MUST include tests

### Git Workflow

**Branch strategy:**

* **`master`** - Main branch, stable code
* Feature branches: `feature/<name>`
* Bugfix branches: `bugfix/<name>`
* Documentation: `docs/<name>`

**Commit messages:**

* Use conventional commits format when appropriate
* Reference issues: `Fixes #123`, `Relates to #456`
* Keep first line under 72 characters
* Wrap body at 72 characters

**Pull requests:**

* Must pass all CI checks
* Pre-commit hooks must pass
* Tests must pass
* At least one review for significant changes

### Code Style

**Shell scripts:**

* Use `shellcheck` for linting (no errors allowed)
* Format with `shfmt -i 2 -ci` (2-space indent, indent switch cases)
* Bash shebang: `#!/usr/bin/env bash`
* POSIX sh shebang: `#!/bin/sh`

**Documentation:**

* Wrap at 78 columns for Markdown files
* Wrap at 72 columns for commit messages and code comments
* Use GitHub-flavored Markdown
* Use reference-style links for readability

**Python:**

* Format with `black`
* Sort imports with `isort`
* Lint with `flake8`
* Type hints where appropriate, check with `mypy`

**Perl:**

* Format with `perltidy`
* Lint with `perlcritic` (level 4 or above)

**PowerShell:**

* Follow PowerShell best practices
* Use approved verbs
* Comment-based help for functions

### Error Handling

**Shell scripts:**

* Use `set -euo pipefail` for strict error handling in executables
* Do NOT use `set -e` in libraries (sourced files)
* Return meaningful exit codes (0=success, 1=general error, 2=usage error, etc.)
* Provide clear error messages to stderr

**Libraries:**

* Surface errors by returning non-zero exit codes
* Do NOT call `exit` in sourced libraries
* Document error conditions and return codes

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
   bats tests/
   ```

5. Follow setup instructions in root `README.md`

### Tool Detection and Policy

**Pre-commit:**

* **Detection signal:** `.pre-commit-config.yaml` exists
* **Policy document:** `docs/agents/pre-commit.md`
* **Status:** Configured (as of v1.0.0)

Additional tools will be documented here as they are added to the repository.

## Agent-Specific Overrides

### Code Generation Agent

**Additional requirements:**

* MUST check for existing similar code before generating new files
* MUST use repository's existing patterns and conventions
* MUST add inline documentation for all generated code
* When generating shell scripts:
  * Include proper shebang
  * Use `set -euo pipefail` for executables
  * Add usage/help function
  * Include error handling

### Documentation Agent

**Additional requirements:**

* MUST wrap at 78 columns in Markdown
* MUST wrap at 72 columns in code comments
* MUST prefer inline documentation over separate files
* MUST NOT create `docs/*.md` files without explicit request
* When updating `README.md`:
  * Keep setup instructions minimal
  * Focus on navigation and "where to find" information
  * Avoid duplicating details available in code/inline docs

### Testing Agent

**Additional requirements:**

* MUST use BATS framework
* MUST follow test organization in `TESTS.md`
* MUST test both success and failure paths
* MUST mock external dependencies
* Test files MUST use `.bats` extension

### Pre-commit Agent

**Additional requirements:**

* MUST follow phased implementation strategy
* MUST ensure CI workflows match pre-commit configuration
* MUST NOT advance to next phase until current phase is complete
* MUST document any new hooks in `docs/agents/pre-commit.md`

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

* `AGENTS.md` - Versioned (currently v2.0.0)
* `WORKFLOW.md` - Versioned (this file, v1.0.0)
* `TESTS.md` - Versioned (see that file)
* `docs/agents/*.md` - Individual versions

Update version numbers when making significant changes to these files.

## Questions and Issues

* For general usage questions, see root `README.md`
* For agent behavior questions, see `AGENTS.md`
* For testing questions, see `TESTS.md`
* For bug reports or feature requests, open a GitHub issue
