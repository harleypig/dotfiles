---
paths:
  - "**/*.pl"
  - "**/*.pm"
  - "**/*.t"
---

# Perl Style

Builds on the generic `code-style.md`; the Perl-specific points below extend
it — and, for terseness, deliberately **relax** it.

## Tooling

- Format with `perltidy`.
- Lint with `perlcritic --severity 4` (severity 4 = gentle; lower numbers
  are stricter, 1 = brutal).

## Terseness & idioms

Perl's character is concise, expressive terseness, so it **relaxes**
`code-style.md`'s *clarity over brevity* / no-nested-ternary guideline (its
*Prefer elif Over Sequential if Blocks* section). An idiomatic single-line
ternary — `my $x = foo() ? bar() : baz();` — and statement modifiers
(`do_x() if $cond;`) are normal, readable Perl: keep them where they read
cleanly rather than expanding to a full `if`/`else` just to satisfy the
generic rule. What still holds: **no Perl golf** — deliberately cryptic,
character-minimizing code for its own sake is out.

## Agent Behavior

- After creating or modifying any Perl file matched by the paths above:
  1. Run `perltidy -b <file>` to format in place (`-b` backs up the
     original as `<file>.bak`; delete the backup after confirming).
  2. Run `perlcritic --severity 4 <file>` and fix all reported violations.
- Accept idiomatic Perl terseness (ternaries, statement modifiers) where it
  reads cleanly — apply `code-style.md`'s clarity-over-brevity rule less
  strictly here — but never write golf.
- **Prefer pre-commit** when the repo has it (see `pre-commit.md`):
  `pre-commit run --files <file>` to check, and `pre-commit run --config
  .pre-commit-config-fix.yaml --files <file>` to fix. Fall back to the direct
  invocation above only when pre-commit isn't configured or doesn't cover the
  file.
