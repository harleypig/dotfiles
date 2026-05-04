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

# Bash / Shell Style

## Scripts (Executables)

- Shebang: `#!/usr/bin/env bash` for bash; `#!/bin/sh` for POSIX sh.
- Use `set -euo pipefail` near the top (fail fast on errors, unset
  variables, and pipe failures).
- Even with `pipefail`, add explicit error handling wherever the failure
  message would be unclear or the recovery path matters:
  `mkdir -p "$dir" || { echo "cannot create $dir" >&2; exit 1; }`
  Silent failures that kill the script with no context are hard to debug.
- Lint with `shellcheck` (no errors or warnings permitted).
- Format with `shfmt` (see `shfmt.md` for flags and invocation).
  `shfmt` does not add blank lines between statements — apply paragraph
  style manually (see `code-style.md`).
- Return meaningful exit codes: 0=success, 1=general error, 2=usage error.
- Provide clear error messages to stderr.
- Include a usage/help function.

## Capturing Command Output

Avoid piping directly into loops or `read`. Instead, capture output into
a variable or array first, then operate on it separately.

**Why:** a `cmd | while read` pipeline runs the loop body in a subshell —
variable assignments inside do not persist to the outer shell. Capturing
first keeps processing in the current shell, separates data production
from data processing, and enables early failure checks before any
processing begins ("die early, die often" — check the array count or
variable content and bail out if it is empty or unexpected).

```bash
# Avoid — loop runs in a subshell, variables don't escape
some_command | while IFS= read -r line; do
  process "$line"
done

# Prefer — capture into array, check before processing
mapfile -t lines < <(some_command)
((${#lines[@]} > 0)) || { echo "no output from some_command" >&2; exit 1; }
for line in "${lines[@]}"; do
  process "$line"
done

# For a single value, prefer command substitution over piping to read
# Avoid
some_command | read -r value

# Prefer
value=$(some_command)
[[ -n $value ]] || { echo "some_command produced no output" >&2; exit 1; }
```

Use `mapfile -t` (bash 4+) for multi-line output into an indexed array.
Use `read -r -a` when the output is a single line of whitespace-separated
fields you want split into an array. Associative arrays are rarely a
natural fit for `mapfile`/`readarray` output; prefer them only when the
data has a clear key/value structure that justifies the complexity.

**Memory trade-off:** `cmd | while` processes output line-by-line without
holding it in memory; capturing into an array holds the full output. This
is only a concern with very large data sets — if that is the case,
consider refactoring the code rather than working around it. If you must
use `cmd | while` for memory reasons, add a comment explaining why.

**Line length:** When the process substitution `< <(command)` would cause
the line to exceed the column limit (78 by default; defer to the project's
`CONVENTIONS.md` if it sets a different limit), break the command inside
onto continuation lines. The `< <(` opener stays on the same line as the
assignment; the command body is indented 2 spaces per level (or per project
settings); the closing `)` sits on its own line at the indentation level
of the outer statement.

```bash
# Fits on one line — leave it alone
mapfile -t words < <(grep 'pattern' file.txt)

# Too long — break the command out
mapfile -t ips < <(
  ip -o addr show scope global 2> /dev/null \
    | awk '{split($4,a,"/"); print $2": "a[1]}'
)

# Same rule applies to read and readarray
read -r value < <(
  some_long_command --with-flags \
    | filter_command
)
```

*(The extra indent on pipeline continuations is what `shfmt -bn -i 2`
produces — the `\` continuation adds one more level at 2 spaces.)*

**Operator per line:** Each `|`, `&&`, and `||` operator should be on its
own continuation line, with the operator at the start (per `shfmt -bn`).
Exception: the entire expression is very short and simple — single brief
commands on each side that fit within the column limit.

```bash
# Short and simple — acceptable on one line
grep 'pattern' file | sort
[[ -f config ]] || exit 1

# Each operator on its own line
find /boot -maxdepth 1 -name 'vmlinuz-*' \
  | sort -V \
  | tail -1 \
  | sed 's|.*/vmlinuz-||'

# Same rule inside command substitutions
value=$(
  some_command \
    | grep 'pattern' \
    || true
)
```

## Libraries (Sourced Files)

- Do NOT use `set -e` or `set -euo pipefail`; it affects the sourcing shell.
- Surface errors by returning non-zero exit codes.
- Do NOT call `exit`; document error conditions and return codes.

## Agent Behavior

- After creating or modifying any shell file matched by the paths above,
  follow the pipeline defined in `shfmt.md` (format) then `shellcheck.md`
  (lint).
- In pre-commit context: `.pre-commit-config.yaml` checks only;
  `.pre-commit-config-fix.yaml` applies fixes.
