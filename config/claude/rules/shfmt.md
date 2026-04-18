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

# shfmt Rules

**Version:** v1.0.0

## Flags

Derived from `dotvim` ALE configuration (`after/ftplugin/sh.vim`):

| Flag | Long form           | Meaning                                      |
|------|---------------------|----------------------------------------------|
| `-i 2` | `--indent 2`      | 2-space indentation                          |
| `-s`   | `--simplify`      | Simplify code where possible                 |
| `-bn`  | `--binary-next-line` | Binary ops (`&&`, `\|\|`) start next line |
| `-ci`  | `--case-indent`   | Indent switch/case bodies                    |
| `-sr`  | `--space-redirects` | Space before redirect operators            |

## Invocation

**Check (no modification) — use for linting and pre-commit:**
```bash
shfmt -i 2 -s -bn -ci -sr -d <file>
```
Exits non-zero and prints a diff if the file would change.

**Fix (apply formatting) — use when creating or editing files:**
```bash
shfmt -i 2 -s -bn -ci -sr -w <file>
```

## Docker Wrapper

`bin/shfmt` mounts `$PWD` as `/mnt` in the container. All file arguments must
be relative to the current directory; passing a file outside `$PWD` exits with
an error before docker runs. The `-w` flag writes in place through the mount,
so it modifies files on the host as expected.

## Agent Behavior

- After creating or modifying any shell file matched by the paths above:
  1. Run `shfmt -i 2 -s -bn -ci -sr -w <file>` to apply formatting.
  2. Run `shellcheck <file>` to catch any remaining issues.
- In pre-commit context: `.pre-commit-config.yaml` uses `-d` (check only);
  `.pre-commit-config-fix.yaml` uses `-w` (auto-fix).
