# Bin Scripts

**Note:** According to the repository's documentation philosophy (see
`WORKFLOW.md`), scripts should contain inline documentation (usage information,
help text, comments). This file provides a quick reference and categorization.
For detailed usage, run scripts with `--help` or read their inline
documentation.

## Categories

### Core Utilities (Used by Other Scripts)

**ansi**
ANSI color code utilities for terminal output formatting.

**anykey**
Wait for user to press any key to continue. Useful in interactive scripts.

**check-dotfiles**
Verify dotfiles setup and configuration integrity.

**check-dotvim**
Verify the companion dotvim repo is present at `$XDG_DOTVIM`
(default `$PROJECTS_DIR/dotvim`) and that the `~/.vim` / `~/.vimrc` symlinks
point at it; warns/links at login via `config/shell-startup/zzz-check-dotvim`.
`--setup` clones dotvim (with submodules) and creates the links for a fresh
machine.

**cleanpath**
Clean and deduplicate PATH variable entries. Removes duplicate directories from
colon-separated paths.
*Note: Needs work - see TODO comments in file*

**CleanPath.tmp**
Alternative/temporary version of cleanpath. May be obsolete.
*Note: Needs documentation or removal*

**dir-readable**
Check if a directory exists and is readable. Returns appropriate exit codes.

**duration**
Calculate and display time duration between two timestamps or events.

**envsubstitute**
Substitute environment variables in template files or strings.

**hr**
Horizontal rule - prints a separator line across the terminal width.

**loadavg**
Display or parse system load average information.

**yesno**
Interactive yes/no prompt utility. Returns 0 for yes, 1 for no.
Handles various input formats (y/n, yes/no, etc.)

### System and Information Utilities

**bash-colors**
Display available bash color codes and formatting options. Useful reference for
terminal color scripting.

**dateh**
Human-readable date formatting utility. Converts or displays dates in friendly
formats.

**findword**
Wordle solver/cheat. Builds a per-position character-class regex from
constraints (`--length`, `--exclude`, `--include`, `--posN`, `--not-posN`),
searches the system dictionary, and ranks matches by vowel richness. Run
`findword --help` for the full flag list.

**lwhich**
Enhanced 'which' that follows symbolic links and shows the actual executable
path.

**show-unicode**
Display Unicode character information and code points. Useful for debugging
character encoding issues.

**showvars**
Display environment variables with formatting. Useful for debugging environment
setup.

**vimwhich**
Open the script found by 'which' command in Vim. Combines `which` + `vim`.

**where**
Locate and display all instances of a command in PATH (like `which -a`).

### Git Utilities

**creds-helper**
Git credentials helper for secure credential management. Used by git
configuration.

**git-all**
Execute git commands across multiple repositories.
*Note: TODO comments indicate this needs updating or refactoring*

**git-branch-clean**
Clean up merged or stale git branches. Interactive cleanup utility.

**git-status**
Enhanced git status with additional information (dirty files, ahead/behind,
etc.).
*Note: TODO indicates adding STASH information*

### Formatting and Development Tools

**prettier** *(wrapper)*
Wrapper for prettier code formatter. May set environment or provide defaults.

**shellcheck** *(wrapper)*
Wrapper for shellcheck shell script linter. May provide project-specific
configuration.

**shfmt** *(wrapper)*
Wrapper for shfmt shell script formatter. May provide consistent formatting
options.

**yamllint** *(wrapper)*
Wrapper for yamllint YAML linter. May provide project-specific linting rules.

**perltidyrc-clean**
Clean or validate perltidyrc configuration files.

### Application-Specific Utilities

**run-help**
Help system integration, used with readline. Provides context-sensitive help.

**tmux_edit_buffer**
Edit tmux buffer contents in an editor. Used with tmux key bindings.

**tmux_mode_indicator**
Display current tmux mode (copy mode, etc.) in status line or prompt.

### Version / Toolchain Management

**vmgr**
Polyglot version-manager orchestrator. Accepts the standard verbs
`install` / `update` / `remove` / `report` plus a list of languages (e.g.
`vmgr install node`, `vmgr report node`), or lists what's available
(`vmgr list`, or any action with no language). `report` shows expected
(what vmgr would install / where) vs. current state and flags drift —
suggesting migration but leaving the *how* to you. `vmgr help <language>`
(e.g. `vmgr help node`) prints that language's own help — its verbs, pin
semantics, and install location — while a bare `vmgr help` is the general
usage. Wraps each language's *native* manager (nvm, perlbrew, pipx, uv, …) —
defined as a sourced module in `lib/version-managers/<language>` that
implements one function per standard
verb and manager (`<manager>_install`, `…_update`, `…_remove`, `…_report`) —
rather than adopting an off-the-shelf unified tool; see
[docs/adr/0001-custom-polyglot-version-manager.md](adr/0001-custom-polyglot-version-manager.md)
for the rationale. A language with more than one manager lists them instead
of acting, so you can pick. Pinned versions live in `config/vmgr/<language>`
(e.g. `config/vmgr/node` sets `NVM_PIN` / `NODE_PIN`) — in config, not code —
so they are set in one place and sourceable by anything that needs them. The
pins govern *only* what vmgr installs and sets as the default; the native
manager stays usable directly. `install` and `update` both reconcile the
toolchain to the pins (`install` also clones the manager on a fresh machine;
`update` requires it present) — re-asserting the pinned default, resetting it
even if newer versions were installed through the manager (intentional, so the
default is deterministic). Owns the install/update/remove lifecycle; runtime
lazy-load stays in `config/shell-startup/<language>`. Run `vmgr help` for usage.

### MCP and Integration

**mymcp**
Custom MCP (Model Context Protocol) related utility or wrapper.

## Wrapper Scripts

The following scripts are **wrappers** that provide project-specific
configuration or environment setup for external tools:

- **prettier** - Code formatter
- **shellcheck** - Shell script linter
- **shfmt** - Shell script formatter
- **yamllint** - YAML linter

These wrappers ensure consistent tool behavior across the repository and may:

- Set environment variables
- Provide default configuration
- Integrate with project-specific settings
- Ensure proper tool versions are used

## Usage Patterns

### Common Usage

```bash
# Interactive prompts
yesno "Proceed with operation?"

# Path cleaning
echo "$PATH" | cleanpath

# Finding executables
lwhich python        # Follow symlinks
where python         # Show all instances

# Git operations
git-status           # Enhanced status
git-branch-clean     # Interactive branch cleanup

# Information display
bash-colors          # Show available colors
show-unicode "é"     # Display character info
```

### In Scripts

```bash
#!/usr/bin/env bash
source "$(dirname "$0")/ansi"  # Load color utilities
source "$(dirname "$0")/yesno"  # Load prompt utility

# Use colors
echo "${GREEN}Success${RESET}"

# Use prompts
if yesno "Continue?"; then
  # proceed
fi
```

## Notes

- Scripts with TODO comments may need refactoring or completion
- Wrapper scripts depend on their underlying tools being installed
- Check individual scripts for `--help` options or usage information
- Most scripts return 0 on success, non-zero on failure
- Scripts in `lib/` are for sourcing; scripts in `bin/` are for executing

## Related Documentation

- **[WORKFLOW.md](../WORKFLOW.md)**: Development guidelines and conventions
- **[TESTS.md](../TESTS.md)**: How to test scripts
- **Script source**: `bin/` directory

For inline documentation and usage details, read the script source files
directly or run them with `--help` when supported.
