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

**Version:** v1.1.0

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

## Enforcement (PostToolUse hook)

A global **`PostToolUse` hook** — `config/claude/hooks/shell-check.py`, wired
into `settings.json` on `Edit|Write|MultiEdit` — runs `shellcheck` on a shell
file **right after the agent edits it** and surfaces any findings (via
`additionalContext`), so the "run shellcheck" rule below is *enforced*, not
merely remembered. It is:

- **Check-only** — never modifies the file; fix what it reports with a normal
  edit (formatting / `shfmt` is **not** in the hook — that stays at commit
  time, per `pre-commit.md`'s fix-once discipline).
- **shellcheck-only** — the bug-catching linter, not the formatter (one
  container per edit via the docker wrapper).
- **Fail-open** — skips silently for a non-shell file, a file outside the
  project, or when `shellcheck` is absent; it can never block an edit.

A shell file is detected by a `.sh`/`.bash` extension or a shell shebang
(so extension-less `bin/`, `lib/`, `config/shell-startup/` scripts are
covered). Tested by `tests/python/test_shell_check.py`.

## Agent Behavior

The full pipeline (format then lint) is owned by `shfmt.md`. shellcheck is
always the final step:

- Run `shellcheck <file>` after any shell file change.
- Fix all reported issues before continuing. Inline disables require a
  reason comment.
- **Prefer pre-commit** when the repo has it (see `pre-commit.md`):
  `pre-commit run --files <file>` to check, and `pre-commit run --config
  .pre-commit-config-fix.yaml --files <file>` to fix. Fall back to the direct
  invocation above only when pre-commit isn't configured or doesn't cover the
  file.
