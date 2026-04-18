---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "bin/**"
  - "lib/**"
  - "shell-startup"
  - "config/shell-startup/**"
  - "config/claude/bin/**"
---

# shellcheck Rules

**Version:** v1.0.0

## Invocation

```bash
shellcheck <file>
```

Run after creating or modifying any shell file matched by the paths above.
No errors or warnings are permitted. Fix all reported issues before committing.

## Inline Disables

`# shellcheck disable=SCxxxx` is allowed only when:

- The flagged construct is intentional and correct.
- A brief comment on the same line explains why.

Example:
```bash
# shellcheck disable=SC1090  # path is dynamic, resolved at runtime
source "$dynamic_path"
```

Never suppress a code without a reason comment.

## Configuration File

shellcheck walks from the checked file's directory up to the filesystem root,
then falls back to `$XDG_CONFIG_HOME/shellcheckrc` (a file directly in XDG
config home, not in a `shellcheck/` subdir), then `~/.shellcheckrc`.

Global config lives at `config/shellcheckrc` in this repo, which resolves to
`$XDG_CONFIG_HOME/shellcheckrc` since `$DOTFILES/config/` is `$XDG_CONFIG_HOME`.
No dotlinks entry is needed.

`bin/shellcheck` is a Docker wrapper and cannot access `$XDG_CONFIG_HOME`
directly inside the container. It mounts the config as `~/.shellcheckrc` with
`HOME=/home/shellcheck` set explicitly (`--user $(id -u):$(id -g)` with a
non-container UID leaves HOME undefined). `SHELLCHECK_OPTS` is also forwarded
to the container if set in the environment.

For per-repo overrides, add a `.shellcheckrc` at the repo root — it takes
precedence over the global config for all files in that repo.

## Docker Wrapper

`bin/shellcheck` mounts `$PWD` as `/mnt` in the container. All file arguments
must be relative to the current directory; passing a file outside `$PWD` exits
with an error before docker runs. Run shellcheck from the repo root or the
directory containing the files.

## Agent Behavior

- After creating or modifying any shell file matched by the paths above:
  1. Run `shfmt -i 2 -s -bn -ci -sr -w <file>` to apply formatting.
  2. Run `shellcheck <file>` to catch any remaining issues.
  3. Fix all reported issues before continuing. Inline disables require a
     reason comment.
- In pre-commit context: `.pre-commit-config.yaml` checks only; `.pre-commit-config-fix.yaml` applies fixes.
