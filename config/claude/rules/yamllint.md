---
paths:
  - "**/*.yml"
  - "**/*.yaml"
---

# yamllint Rules

**Version:** v1.0.0

## Invocation

```bash
yamllint <file>
```

No errors or warnings are permitted (warnings are reported; fix them).

## Configuration File

Config lives at `config/yamllint/config` in this repo, which resolves to
`$XDG_CONFIG_HOME/yamllint/config`. Key relaxations from `default`:

- `line-length`: max 120, level warning
- `indentation`: 2 spaces
- `comments-indentation`: disabled (ansible-lint compatibility)
- `document-start`: level warning
- `truthy`: allows `true`, `false`, `yes`, `no`
- `quoted-strings`: disabled

## Docker Wrapper

`bin/yamllint` mounts `$PWD` as `/mnt` and `$XDG_CONFIG_HOME` as `/config`
so the container finds the config. All file arguments must be relative to
the current directory.

## Agent Behavior

- After creating or modifying any YAML file matched by the paths above:
  1. Run `yamllint <file>` and fix all reported issues.
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes.
