# Code Style

**Version:** v1.2.0

## General Style

Language-agnostic guidance that applies to every repository. Paragraph
spacing, naming, and documentation rules below; language-specific tooling
details live in per-language rules files (see *Language-Specific Notes*
at the bottom).

### Naming

- Use clear, descriptive, intent-revealing names throughout.
- Match the casing convention of the language and surrounding code; do
  not invent a new style for one identifier.
- Private/internal members use the language's idiomatic marker
  (`_prefix` in Python, lowercase package-private in Go, etc.).

### Documentation and Wrapping

- Wrap Markdown prose at **78 columns**.
- Wrap code comments at **72 columns**. Comment wrap is independent of
  the code-line wrap configured for the formatter — even when a repo
  raises its formatter's `column_limit` / `line-length`, comments stay
  at 72. Widen past 72 only when absolutely needed (an unbreakable URL,
  a literal that would mislead if split).
- Use GitHub-flavored Markdown.
- Use reference-style links for readability in Markdown.
- Document complex logic inline; do not write comments that merely
  restate what well-named code already says.
- Public APIs in any language MUST have a docstring / equivalent.

### Error Handling Posture

- **Executables:** fail fast. A binary or CLI may call `exit` / `panic`
  on unrecoverable errors.
- **Libraries:** surface errors by returning or raising; never call
  `exit` / `panic` from library code.
- Validate at the boundary (user input, external API responses); trust
  validated values internally. Do not add error handling for cases that
  cannot occur.

### Abstraction and the Rule of Three

Keep efficiency in mind without optimizing too soon. The working heuristic:

> **If the same code, process, or config appears more than twice, abstract
> it.**

One occurrence is fine. A second is a flag to watch. The **third** confirms a
stable, repeating pattern — extract it into a single source of truth (a
function, helper, module, loop, template, script, or — for a repeated
multi-step procedure — a skill; see *When to Propose a Skill* in `CLAUDE.md`).
The payoff is fewer places to change, fix, and let drift apart, and the intent
named once.

This is a **guideline, not a mandate** — the same caution that applies to
premature optimization applies to premature abstraction:

- **Wait for the third instance.** Abstracting on the first or second risks
  the *wrong* abstraction, which couples things that later diverge and is
  costlier to unwind than the duplication was. Duplication is cheaper than the
  wrong abstraction.
- **Abstract repetition of *meaning*, not just of *characters*.** Three
  fragments that merely look alike but represent different concepts should
  stay separate; merging them couples unrelated code.
- **Don't force it, and don't over-engineer** the abstraction once you do
  extract — the simplest form that removes the real repetition wins (no
  configurability or generality that was not asked for).

Removing genuine repetition is the cheap, high-value kind of efficiency: less
to read and maintain. Reach for it when the pattern is demonstrated, not
merely anticipated.

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
- Python → `python.md`
