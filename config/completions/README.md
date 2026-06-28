# Bash Completion Configuration

This document explains how bash completion is configured and works in this
dotfiles repository.

## Overview

This repository uses a **distributed, conditional loading approach** for bash
completion rather than a centralized system. Each shell-startup file is
responsible for loading completions for its specific tools, with conditional
loading based on tool availability.

## Architecture

### Current System

- **Distributed Loading**: Each tool's completion is loaded by its
  corresponding shell-startup file
- **Conditional Loading**: Completions only load when the associated tool is
  installed
- **System Integration**: Leverages the system's bash-completion package for
  standard tools
- **Custom Completions**: Defines custom completions inline where needed

### File Organization

```text
config/completions/          # Vendored completion files (committed)
├── git                      # Git (upstream git-completion.bash, ~92KB)
├── packwiz                  # Packwiz
├── poetry                   # Poetry
├── proj                     # proj (first-party)
├── gh                       # GitHub CLI — `gh completion -s bash`
├── docker                   # Docker — `docker completion bash`
├── npm                      # npm — `npm completion`
├── rustup                   # rustup — `rustup completions bash`
└── cargo                    # cargo — toolchain etc/bash_completion.d/cargo

config/shell-startup/         # Shell startup files that load completions
├── git                      # Loads git completion
├── gh                       # Loads gh completion
├── docker                   # Loads docker completion
├── rust                     # Loads rustup + cargo completion
├── nodejs                   # Loads NVM + npm completion
├── python                   # Loads poetry completion
├── ssh-config-completion    # Defines SSH completion
├── terraform                # Loads terraform completion
├── binenv                   # Loads binenv completion (dynamic)
├── perl                     # Loads Perlbrew completion
└── taskwarrior_inactive     # TaskWarrior completion (currently inactive)
```

### Vendored vs. dynamic loading

Most completions are **vendored**: the tool's official `completion` output is
generated once and committed, then sourced as a static file. Sourcing a file
is far cheaper than forking the tool at every interactive shell — `docker
completion bash` and `npm completion` each measured ~300ms. `binenv` is the
exception: it loads dynamically (`source <(binenv completion bash)`), cheap
enough to not bother vendoring.

The trade-off is staleness — a vendored completion reflects the tool version
it was generated from, so regenerate it after a tool upgrade (see
*Regenerating vendored completions* below).

## How It Works

### 1. Shell Startup Process

When bash starts as a login shell:

1. Sources `~/.bash_profile` (symlinked to `shell-startup`)
2. `shell-startup` calls `load_files()` which sources all files in
   `config/shell-startup/`
3. Each shell-startup file loads its specific completions conditionally
4. System bash-completion is already loaded from `/etc/bash_completion`

### 2. Individual Completion Loading

#### Git Completion (`config/shell-startup/git`)

```bash
# Loads the vendored upstream git-completion.bash
if [[ -r "$XDG_CONFIG_HOME/completions/git" ]]; then
  source "$XDG_CONFIG_HOME/completions/git"
fi
```

- **Source**: Vendored upstream `git-completion.bash` (~92KB), committed in
  `config/completions/git`
- **Condition**: Always loads if file is readable
- **Provides**: Complete git command completion, subcommands, options, branch
  names, etc.

#### Poetry Completion (`config/shell-startup/python`)

```bash
# Only loads if poetry is installed
command -v poetry &> /dev/null && source "$XDG_CONFIG_HOME/completions/poetry"
```

- **Source**: Custom poetry completion file
- **Condition**: Only loads if `poetry` command exists
- **Provides**: Poetry command completion, subcommands, options

#### SSH Completion (`config/shell-startup/ssh-config-completion`)

```bash
_ssh() {
  readarray -t SSH_KNOWN_HOSTS < <(awk '{print $1}' ~/.ssh/known_hosts | cut -d ',' -f 1 | uniq | grep -v 'localhost')
  read -ra SSH_CONFIG_HOSTS < <(grep 'Host ' ~/.ssh/config | cut -d ' ' -f 2- | tr '\n' ' ' | uniq)
  complete -o default -W "${SSH_KNOWN_HOSTS[*]} ${SSH_CONFIG_HOSTS[*]}" ssh
}
complete -F _ssh ssh
```

- **Source**: Custom inline completion function
- **Condition**: Always loads
- **Provides**: SSH host completion from `~/.ssh/known_hosts` and `~/.ssh/config`

#### Modern CLI Completions (gh, docker, npm, rustup, cargo)

These tools each emit a completion script from an official subcommand. The
output is vendored (committed) and sourced from a small `havecmd`-guarded,
interactive-only module — `gh`, `docker`, and `rust` (rustup + cargo); npm
loads from the `nodejs` module. See *Regenerating vendored completions* below
for the exact generator commands.

#### Other Completions

- **Terraform**: Loaded in `config/shell-startup/terraform`
- **Node.js/NVM**: Loaded in `config/shell-startup/nodejs`
- **binenv**: Loaded in `config/shell-startup/binenv` (dynamic)
- **Perl**: Loaded in `config/shell-startup/perl`
- **TaskWarrior**: `config/shell-startup/taskwarrior_inactive` (inactive)

## Regenerating vendored completions

A vendored completion reflects the tool version it was generated from. After
upgrading a tool, regenerate its file from the repo root:

```bash
gh completion -s bash                          > config/completions/gh
docker completion bash                         > config/completions/docker
npm completion                                 > config/completions/npm
rustup completions bash                        > config/completions/rustup
cp "$(rustc --print sysroot)/etc/bash_completion.d/cargo" config/completions/cargo
```

`tests/shell/test_completions.bats` guards these — it parses every vendored
file and checks each generated one still registers its command — so a botched
regeneration fails CI rather than silently breaking completion.

## Adding New Completions

### Method 1: Add to Existing Shell-Startup File

If the tool already has a shell-startup file, add the completion loading there:

```bash
# In config/shell-startup/python
command -v newtool &> /dev/null && source "$XDG_CONFIG_HOME/completions/newtool"
```

### Method 2: Create New Shell-Startup File

For a new tool, create a dedicated shell-startup file:

```bash
# Create config/shell-startup/newtool
#!/bin/bash

# Tool-specific environment setup
export NEWTOOL_CONFIG="$XDG_CONFIG_HOME/newtool/config"

# Load completion if tool is installed
command -v newtool &> /dev/null && source "$XDG_CONFIG_HOME/completions/newtool"
```

### Method 3: Custom Inline Completion

For simple completions, define them inline:

```bash
# In config/shell-startup/newtool
_newtool() {
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--help --version --config"

  if [[ ${cur} == -* ]]; then
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
  fi
}
complete -F _newtool newtool
```

## Troubleshooting

### Check Loaded Completions

```bash
# List all loaded completions
complete -p

# Count loaded completions
complete -p | wc -l

# Check specific completion
complete -p | grep git
```

### Debug Completion Loading

```bash
# Enable debug mode
DEBUG=1 bash -l

# Check if completion file exists and is readable
[[ -r "$XDG_CONFIG_HOME/completions/git" ]] && echo "Git completion readable" || echo "Git completion not readable"
```

### Common Issues

1. **Completion not loading**: Check if tool is installed (`command -v toolname`)
2. **File not readable**: Check file permissions (`ls -la config/completions/`)
3. **Wrong path**: Verify `XDG_CONFIG_HOME` is set correctly
4. **Shell not login shell**: Use `bash -l` to test login shell behavior

## Best Practices

1. **Use conditional loading**: Only load completions for installed tools
2. **Keep completions with tool configs**: Maintain modularity
3. **Test with login shell**: Use `bash -l` to test completion loading
4. **Check file permissions**: Ensure completion files are readable
5. **Document custom completions**: Add comments explaining complex completion logic

## References

- [Bash Completion Manual](https://www.gnu.org/software/bash/manual/html_node/Programmable-Completion.html)
- [System Bash Completion](https://github.com/scop/bash-completion)
- [Git Completion Source](https://github.com/git/git/blob/master/contrib/completion/git-completion.bash)
