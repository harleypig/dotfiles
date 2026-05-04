# Code Style

**Version:** v1.0.0

## Paragraph Style

Write code in paragraphs. Every distinct statement at a given nesting level
is separated from the next by a blank line, regardless of how simple the
statement is. This applies at every level — inside `if` blocks, loops, and
functions, not just at the top level.

### Rules

- After a section comment, put a blank line before the first statement.
- Between every distinct statement or block at the same nesting level, put
  a blank line — simple assignments included.
- Do NOT put a blank line immediately after an opening keyword (`then`,
  `do`, `else`, `{`, `:`). The first statement inside a block sits flush
  against its opener.
- The last statement before a closing keyword (`fi`, `done`, `}`) does not
  need a trailing blank line.
- Put a blank line **before** `else` and `elif` to mark the branch
  boundary. This is structural spacing — it signals a shift in direction,
  the same way a paragraph break does in prose.

### Condensed Groups

Several consecutive statements can be condensed (no blank lines between
them) when they are all short, structurally parallel or tightly related,
and together constitute a single named sub-task. The whole group is one
paragraph.

Test: can you give the group a single descriptive name? If yes, condense.

**Candidates:** parallel assignments, a set of related `export`/`readonly`
declarations, initializing a group of variables for the same purpose.

**Not candidates:** statements where each transforms the previous in a
non-obvious way, or where simple assignments mix with multi-line blocks.

### Goal

A reader scanning vertically should see discrete "thoughts." Dense,
unspaced code is a wall; paragraph-spaced code is a legible sequence of
steps. The cost is vertical space; the benefit is that the structure of
the logic is immediately visible without parsing every token.

### Example

```bash
# Set up colors
c_warn='\033[0;33m'
c_alert='\033[0;31m'
c_ok='\033[0;32m'
c_off='\033[0m'

# Resolve the config path
config_file="${XDG_CONFIG_HOME:-$HOME/.config}/app/config"

# Load and validate
raw=$(cat "$config_file")
[[ -n $raw ]] || { echo "empty config" >&2; exit 1; }

# Extract the target value
result=$(jq -r '.target' <<< "$raw")

if [[ -z $result ]]; then
  echo "missing target in config" >&2
  exit 1

elif [[ $result == "skip" ]]; then
  echo "nothing to do"
  exit 0

else
  echo "target: $result"
fi
```

### Prefer `elif` Over Sequential `if` Blocks

When multiple `if` blocks test the same data and assign to the same
variable (or perform the same kind of action), collapse them into a
single `if`/`else-if` chain. Sequential blocks imply independence;
`else-if` makes the mutual exclusivity explicit.

When severity or priority differs between branches, check the most
severe condition first — the `else-if` branch is only reached when the
preceding branch did not fire.

```bash
# Avoid: two blocks that silently override each other
load_color=$c_ok
if ((load > threshold)); then
  load_color=$c_warn
fi
if ((load > threshold * 2)); then  # stomps the previous assignment
  load_color=$c_alert
fi

# Prefer: one chain, explicit ordering, most severe first
load_color=$c_ok
if ((load > threshold * 2)); then
  load_color=$c_alert
elif ((load > threshold)); then
  load_color=$c_warn
fi
```

*(Syntax varies by language: `elif`, `elsif`, `elseif`, `else if` — use
whatever the language spells it.)*

When a chain grows to four or more branches testing the same variable,
consider refactoring: a `case`/`switch` statement for discrete values,
a threshold table with a loop, or a small helper function.

### Language-Specific Notes

The general rule above applies to all languages. Per-language tooling
details — whether auto-formatters enforce or fight this style, and how to
handle it — live in each language's rules file:

- Bash → `bash.md`
