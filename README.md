[![CodeFactor](https://www.codefactor.io/repository/github/harleypig/dotfiles/badge)](https://www.codefactor.io/repository/github/harleypig/dotfiles)

# Dotfiles Repository

This repository contains my personal dotfiles and shell configuration for
Linux, Windows (PowerShell), and cross-platform development environments.

## What This Repository Contains

- **Shell Configuration**: Bash startup scripts, aliases, and environment
  setup
- **Tool Configurations**: Git, Vim, Tmux, Python, Node.js, Rust, and more
- **Custom Scripts**: Utility scripts in the `bin/` directory
- **Cross-Platform Support**: Linux bash and Windows PowerShell configurations
- **Modular Design**: Organized by tool/functionality with conditional loading

## Quick Setup

### 1. Clone the Repository

```bash
git clone https://github.com/harleypig/dotfiles.git ~/projects/dotfiles
cd ~/projects/dotfiles
```

### 2. Create Symbolic Links

The repository uses symbolic links to connect configuration files to your home
directory:

```bash
# Create the main shell startup link
ln -sf ~/projects/dotfiles/shell-startup ~/.bash_profile

# Optional: Link other shell files if needed
ln -sf ~/projects/dotfiles/shell-startup ~/.bashrc
ln -sf ~/projects/dotfiles/shell-startup ~/.profile
```

### 3. Configure Custom Files

#### Dotlinks Files

The repository supports multiple dotlinks configurations for different
environments:

- **`dotlinks-default`**: Default configuration for most users
- **`dotlinks-harleypig.com`**: Specific configuration for harleypig.com
  environment
- **`dotlinks-sweetums`**: Configuration for sweetums environment


**When to use**: Choose the dotlinks file that matches your environment or
create your own custom one.

**How to set up**:
```bash
# Copy the appropriate dotlinks file
cp dotlinks-default ~/.dotlinks

# Or create your own custom dotlinks file
# Edit ~/.dotlinks to specify which configuration files to link
```

#### Bin-Dirs Files

The `bin-dirs-defaults` file specifies additional directories to add to your
PATH:

```bash
# Default bin directories (in order of precedence)
$HOME/bin
$HOME/.local/bin
$HOME/.vim/bin
$HOME/.cabal/bin
$HOME/.cargo/bin
$HOME/.minecraft/bin
$HOME/go/bin
$HOME/.dotnet/tools
$HOME/Dropbox/bin
$HOME/videos/bin
$PROJECTS_DIR/depot_tools
$PROJECTS_DIR/android-sdk/tools
$PROJECTS_DIR/android-sdk/platform-tools
```

**When to customize**: If you have additional tool directories or want to
change the PATH order.

**How to set up**:
```bash
# Use defaults (no action needed)
# The system will automatically use bin-dirs-defaults

# Or create custom bin directories
cp bin-dirs-defaults ~/.bin-dirs
# Edit ~/.bin-dirs to customize your PATH
```

### 4. Test the Setup

```bash
# Start a new login shell to test
bash -l

# Verify environment variables
echo "DOTFILES: $DOTFILES"
echo "XDG_CONFIG_HOME: $XDG_CONFIG_HOME"

# Check if completions are working
complete -p | grep git
```

## Architecture Overview

### Shell Startup System

The `.bash_profile`, `.bashrc`, and `.profile` files all link to the same
`shell-startup` file. This unified approach provides:

- **Simplicity**: One central file to understand and modify
- **Consistency**: Same configuration regardless of how bash is started
- **Vim Integration**: Ensures aliases work when shelling from vim
- **Modular Loading**: Individual tool configurations in
  `config/shell-startup/`

### Directory Structure

```
├── bin/                     # Custom utility scripts
├── config/                  # Tool-specific configurations
│   ├── completions/         # Bash completion files
│   ├── shell-startup/       # Modular shell startup files
│   ├── git/                 # Git configuration
│   ├── vim/                 # Vim configuration
│   └── ...                  # Other tool configs
├── docs/                    # Documentation
├── powershell/              # Windows PowerShell configuration
├── shell-startup            # Main shell startup script
├── dotlinks-default         # Default dotlinks configuration
├── bin-dirs-defaults        # Default PATH directories
└── README.md               # This file
```

### Modular Configuration

Tool configurations are organized in `config/shell-startup/` with conditional
loading:

- **`000-loadtokens`**: Load authentication tokens
- **`010-general`**: General environment setup
- **`git`**: Git configuration and aliases
- **`python`**: Python environment and poetry setup
- **`nodejs`**: Node.js and NVM configuration
- **`rust`**: Rust and Cargo setup
- **`vim`**: Vim configuration
- **`tmux`**: Tmux configuration
- **`ssh-config-completion`**: SSH host completion

## Cross-Platform Support

### Linux/Unix (Primary)

- **Shell**: Bash with comprehensive completion system
- **Package Management**: Supports apt, pacman, and other package managers
- **Development Tools**: Git, Vim, Tmux, Python, Node.js, Rust, Go
- **System Integration**: XDG Base Directory specification

### Windows (Work in Progress)

The repository includes PowerShell configuration for Windows environments:

- **PowerShell Profiles**: Located in `powershell/` directory
- **Git for Windows**: Integration with Git Bash and PowerShell
- **Cross-Platform Scripts**: Some utilities work in both environments

**Note**: Windows support is actively being developed. Some features may be
incomplete or require manual setup.

### Git for Windows

When using Git for Windows:

- **Git Bash**: Uses the same bash configuration as Linux
- **PowerShell**: Uses Windows-specific PowerShell profiles
- **MSYS Integration**: Handles symlink creation appropriately

**Setup for Git for Windows**:
```bash
# In Git Bash
ln -sf ~/projects/dotfiles/shell-startup ~/.bash_profile

# PowerShell setup (manual)
# Copy powershell/ files to appropriate PowerShell profile location
```

## Customization

### Adding New Tools

1. **Create shell-startup file**: Add `config/shell-startup/newtool`
2. **Add completion**: Place completion file in `config/completions/`
3. **Update PATH**: Add to `bin-dirs-defaults` or `~/.bin-dirs`

### Environment-Specific Configuration

1. **Create custom dotlinks**: Copy and modify `dotlinks-default`
2. **Custom bin directories**: Create `~/.bin-dirs` file
3. **Tool-specific configs**: Add files to `config/` directory

## Troubleshooting

### Common Issues

1. **Symbolic links not working**: Ensure you're using absolute paths
2. **Completions not loading**: Check file permissions and tool installation
3. **PATH issues**: Verify `bin-dirs-defaults` or `~/.bin-dirs` configuration
4. **Environment variables**: Use `bash -l` to test login shell behavior

### Debug Mode

```bash
# Enable debug output
DEBUG=1 bash -l

# Check specific configurations
bash -l -c 'echo "DOTFILES: $DOTFILES"'
```

## Documentation

- **[Bash Completion](docs/bash-completion.md)**: Detailed explanation of the
  completion system
- **[Git Aliases](GIT_ALIASES.md)**: List of available git aliases
- **[Conventions](CONVENTIONS.md)**: Coding and configuration conventions

## Contributing

This is a personal dotfiles repository, but suggestions and improvements are
welcome. Please:

1. Test changes thoroughly
2. Document new features
3. Maintain backward compatibility
4. Follow existing conventions

## License

See [LICENSE](LICENSE) file for details.
