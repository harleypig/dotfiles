---
name: a11y-review
description: Audit a user interface for accessibility (WCAG) — semantic markup, keyboard navigation and focus order, ARIA correctness, color contrast, screen-reader labelling, accessible forms/error messaging, and reduced-motion. Use for "accessibility review", "a11y audit", "is this accessible", "WCAG check", "keyboard navigation", "screen reader support", "contrast check". The tool for qa.md's UI/UX & accessibility dimension. UI repos only — N/A for headless/CLI/library code.
---

# a11y-review

**Version:** v1.0.0

Audit a **user interface** for accessibility against WCAG. The tool for
`qa.md`'s **UI/UX & accessibility** dimension, which says to do the manual
pass **even when no tooling exists yet**. Framework-agnostic (any UI stack).

## Applicability — check first

This applies only to repos that render a **UI**. For a headless service, CLI,
or library, say "**N/A — no UI**" and stop. (A terminal UI has its own
constraints; treat WCAG as inspiration, not a literal checklist, there.)

## What it checks

A manual pass — automated checkers catch ~30% of issues; the rest is judgment:

- **Semantic structure** — real landmarks/headings/lists/buttons, not
  `div`-soup; one logical reading order.
- **Keyboard** — every interactive element reachable and operable by keyboard;
  a visible focus indicator; no traps; **focus order** matches visual order;
  focus managed on route/modal changes.
- **ARIA** — only where semantics fall short, and *correct* (right role/state,
  `aria-*` that matches reality) — wrong ARIA is worse than none.
- **Names & labels** — every control/image/icon has an accessible name; form
  fields have associated labels; errors are announced and tied to their field.
- **Contrast** — text and meaningful UI meets WCAG AA contrast; information is
  not conveyed by **color alone**.
- **Motion/media** — respects `prefers-reduced-motion`; media has
  captions/alternatives.

## Type / agent use

A **skill** you invoke. Reading a large component tree can be delegated to a
**subagent** that returns the violations; the judgment calls (is this ARIA
*right*? is the focus order sane?) stay with you.

## Output

```markdown
## Accessibility review — <scope>   (WCAG 2.x AA)

1. 🔴 `component` — <barrier, e.g. icon button has no accessible name> → <fix>
2. 🟡 <contrast/focus-order/…> → <fix>
```

Rank by **barrier severity** — a keyboard trap or an unlabelled control blocks
users entirely; a minor contrast miss degrades. **Assess only**; applying
fixes is a separate step. Note what needs a real assistive-tech / manual
check you couldn't fully perform from the code.

## Provenance

Adapted (idea-level) from the mining census — `claude-tools`
`accessibility-specialist`. No upstream code reused. See `SOURCE.md`.
