[![CodeFactor](https://www.codefactor.io/repository/github/harleypig/dotfiles/badge)](https://www.codefactor.io/repository/github/harleypig/dotfiles)

# Dotfiles Repository

This repository contains my personal dotfiles and configuration files for
various development tools and environments. It provides a centralized way to
manage shell configurations, custom scripts, and application settings across
different systems.

## Why This Setup?

This dotfiles configuration serves two primary purposes:

1. **Quick Environment Setup** - Get a fully configured development
   environment running quickly on any new machine

2. **XDG Base Directory Compliance** - Follow the [XDG Base Directory
   specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html)
   to keep your home directory clean and organized

The XDG Base Directory specification defines standard locations for
configuration, cache, and data files, moving them out of your home directory's
root. This setup implements XDG compliance for supported applications, making
your environment more organized and portable.

For information on which applications support XDG Base Directory, see the
[Arch Linux wiki's XDG Base Directory support
page](https://wiki.archlinux.org/title/XDG_Base_Directory).

## Overview

This dotfiles repository includes:

- **Shell configurations** - Bash startup scripts with modular organization
- **Custom scripts** - Utility scripts in the `bin/` directory
- **Application configs** - Configuration files for various tools (git, tmux,
  vim, etc.)
- **XDG-compliant setup** - Environment variables and configurations that
  follow XDG Base Directory standards
- **PowerShell setup** - Windows PowerShell configuration (work in progress)
- **Cross-platform support** - Linux, macOS, and Windows configurations

### XDG Implementation

This repository implements XDG Base Directory compliance by:

- Setting `XDG_CONFIG_HOME="$DOTFILES/config"` to centralize configuration
  files
- Using `XDG_CACHE_HOME`, `XDG_DATA_HOME`, and `XDG_STATE_HOME` for
  application data
- Configuring applications to use XDG-compliant paths (see
  `config/shell-startup/app_env_vars`)
- Organizing configuration files in the `config/` directory structure

For detailed documentation on specific components, see the `docs/` directory.

## Installation

### Prerequisites

- Git
- Bash (Linux/macOS) or Git Bash (Windows)
- PowerShell 7+ (for Windows configuration)

### Basic Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/harleypig/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. **Configure environment variables:**
   - Set `DOTFILES` to point to your dotfiles directory
   - Set `PROJECTS_DIR` to your projects directory (defaults to `$HOME/projects`)

3. **Run the setup script:**
   ```bash
   ./setup-work  # Creates necessary directories and files
   ```

4. **Configure bin-dirs and dotfile-links** (see sections below)

## Bin-Dirs Configuration

The `bin-dirs-defaults` file defines directories that should be added to your
`PATH`. This ensures that custom scripts and tools are available system-wide.

### How it works:

- The file contains a list of directories (one per line)
- Order matters - directories are added to PATH in the order listed
- Variables like `$HOME`, `$PROJECTS_DIR` are expanded
- These directories are automatically added to your PATH during shell startup

### Configuration:

- **Default**: Uses `bin-dirs-defaults` for standard setup
- **Custom**: Create your own `bin-dirs-<hostname>` file for machine-specific
  paths
- **Examples**: `bin-dirs-harleypig.com`, `bin-dirs-sweetums`

### When to configure:

- After cloning the repository
- When adding new tool directories to your system
- When setting up a new machine with different directory structure

## Dotfile-Links Configuration

The `dotlinks-default` file defines symbolic links that should be created in
your home directory, pointing to configuration files in the dotfiles
repository.

### How it works:

- Each line specifies a link target and source
- Links are created in your home directory (`$HOME`)
- Source files are referenced from the dotfiles directory (`$DOTFILES`)
- This allows you to version control your dotfiles while keeping them in the
  standard locations

### Configuration:

- **Default**: Uses `dotlinks-default` for basic configuration files
- **Custom**: Create your own `dotlinks-<hostname>` file for machine-specific links
- **Examples**: `dotlinks-harleypig.com`, `dotlinks-sweetums`

### When to configure:

- During initial setup
- When adding new configuration files to version control
- When setting up a new machine with different configuration needs

## Shell Startup Configuration

The `.bash_profile`, `.bashrc`, and `.profile` files all link to the same
`shell-startup` file. This setup provides several benefits:

- **Simplified debugging** - One central file to examine instead of tracing
  through multiple files
- **Modular organization** - Tasks are broken into discrete functions (e.g.,
  `shell_startup.d/tmux`)
- **Consistent behavior** - Ensures aliases and configurations work when
  shelling from vim
- **Cross-shell compatibility** - Works across different shell startup
  scenarios

## PowerShell and Git for Windows

**Note**: PowerShell and Git for Windows configuration is currently a work in
progress.

The `powershell/` directory contains PowerShell scripts and configuration
files, but the setup process is still being refined. See
`powershell/README.md` for current instructions and limitations.

## Documentation

For more detailed information, see the `docs/` directory:

- `bash-completion.md` - Bash completion setup and configuration
- `git-commit-comment.md` - Git commit message conventions
- `todo.md` - Current development tasks and improvements
- `windows-notes.md` - Windows-specific setup notes

## Contributing

This is a personal dotfiles repository, but suggestions and improvements are
welcome. Please check the `CONVENTIONS.md` file for coding standards and
conventions used in this repository.
