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

**available-subnets**
List available network subnets on the system.

**bash-colors**
Display available bash color codes and formatting options. Useful reference for
terminal color scripting.

**dateh**
Human-readable date formatting utility. Converts or displays dates in friendly
formats.

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

**filter_gmail**
Filter Gmail messages based on criteria. Email management utility.

**gmailfilter_toyaml**
Convert Gmail filters to YAML format for version control or portability.

**poetry2setup**
Convert Python Poetry configuration to setup.py or other formats. Migration
utility.

**run-help**
Help system integration, used with readline. Provides context-sensitive help.

**tmux_edit_buffer**
Edit tmux buffer contents in an editor. Used with tmux key bindings.

**tmux_mode_indicator**
Display current tmux mode (copy mode, etc.) in status line or prompt.

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
