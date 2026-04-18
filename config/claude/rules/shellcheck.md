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

shellcheck resolves config by walking from the checked file's directory up to
the filesystem root, then falls back to `$XDG_CONFIG_HOME/shellcheck/shellcheckrc`
and `~/.shellcheckrc`.

**Open question:** whether to use `~/.shellcheckrc` for personal global defaults
or rely solely on per-repo `.shellcheckrc` files.

Tradeoffs:

- **`~/.shellcheckrc` (global):** one place for personal preferences; applies to
  all repos including ones without their own config. If used, must be managed via
  dotlinks. Risk: may impose preferences on repos that don't want them.
- **`.shellcheckrc` at repo root:** repo-specific, overrides global fallback for
  all files in the repo. Explicit and portable. Preferred when repo has known
  conventions.
- **Both:** global sets safe personal defaults; repo-local overrides where needed.

**Current state:** no `.shellcheckrc` exists in this repo or globally. Until a
decision is made, pass any needed options directly on the command line.

When the decision is made, update this file and create `.shellcheckrc` and/or
manage `~/.shellcheckrc` via dotlinks accordingly.
