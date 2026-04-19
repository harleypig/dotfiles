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

**Version:** v1.2.0

## Default Settings

Derived from `dotvim` ALE configuration (`after/ftplugin/sh.vim`):

| Flag  | Long form            | editorconfig key      |
|-------|----------------------|-----------------------|
| `-i 2`| `--indent 2`         | `indent_size = 2`     |
| `-bn` | `--binary-next-line` | `binary_next_line`    |
| `-ci` | `--case-indent`      | `switch_case_indent`  |
| `-sr` | `--space-redirects`  | `space_redirects`     |
| `-s`  | `--simplify`         | (not supported)       |

`-s` has no `.editorconfig` equivalent and must always be passed on the
command line. The other four can come from either CLI flags or
`.editorconfig`; CLI flags take precedence when both are present.

Other shfmt `.editorconfig` properties not used here:
`shell_variant` (→ `-ln`), `keep_padding` (→ `-kp`),
`function_next_line` (→ `-fn`). CLI-only (no `.editorconfig` mapping):
`-s`, `-mn`, `-w`/`-d`/`-l`.

## Invocation

These settings are the default. Which form to use depends on the file:

**Files with `.sh` / `.bash` extensions** — shfmt reliably reads
`.editorconfig`, so the short form works:
```bash
shfmt -s -d <file>    # check
shfmt -s -w <file>    # fix
```

**Extension-less files** (e.g. `bin/*`, `lib/*`, `shell-startup`,
`config/shell-startup/*`, `config/claude/bin/*`) — shfmt does not
reliably pick up `.editorconfig` for these, so pass all flags
explicitly:
```bash
shfmt -i 2 -s -bn -ci -sr -d <file>    # check
shfmt -i 2 -s -bn -ci -sr -w <file>    # fix
```

If unsure, use the explicit form — it works in both cases.

The same caveat applies to any other tool that reads `.editorconfig`
and is invoked on extension-less files: prefer explicit command-line
options for extension-less scripts.

## Project Overrides

A project that wants different settings can add
`.claude/rules/shfmt-override.md` (project-level rules file, takes
precedence over this user-level rule per `CLAUDE.md`'s resolution
order).

## Docker Wrapper

`bin/shfmt` mounts `$PWD` as `/mnt` in the container. All file arguments
must be relative to the current directory; passing a file outside `$PWD`
exits with an error before docker runs. The `-w` flag writes in place
through the mount, so it modifies files on the host as expected.

The `.editorconfig` at the repo root is visible to the container at
`/mnt/.editorconfig` when `$PWD` is the repo root (or anywhere above
the file being formatted).

## Agent Behavior

- After creating or modifying any shell file matched by the paths above
  (outside of pre-commit context):
  1. Run the appropriate form from **Invocation** above — short form
     (`-s -w`) only for `.sh`/`.bash` files, explicit form
     (`-i 2 -s -bn -ci -sr -w`) for everything else.
  2. Run `shellcheck <file>` to catch any remaining issues.
- In pre-commit context: `.pre-commit-config.yaml` uses `-d` (check
  only, never `-w`); `.pre-commit-config-fix.yaml` uses `-w` (auto-fix).
