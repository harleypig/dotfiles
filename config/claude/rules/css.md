---
paths:
  - "**/*.css"
---

# CSS Rules

**Version:** v1.0.0

Plain CSS conventions. (For *parsing* existing HTML/CSS into text, see
`html.md`; this file is about *authoring* stylesheets.)

## Detection

Active when any `*.css` file is created or modified.

## Style

- Format with the repo's formatter (Biome formats CSS — see `biome.md`);
  do not hand-align.
- **Custom properties for tokens.** Define theme values (colors,
  spacing) as `:root` custom properties and reference them
  (`var(--paper)`), so the palette lives in one place.
- Keep specificity low and flat: prefer single class selectors; avoid
  deep descendant chains and `!important`.
- Use clear, intent-revealing class names. A simple, consistent scheme
  (e.g. `block__element` or plain semantic names) beats ad-hoc naming.
- Comment the *why* for non-obvious rules (magic numbers, overrides).

## With a component library

- When a component library is in use (e.g. Mantine), prefer its theme
  tokens / CSS variables (`var(--mantine-color-*)`) over hard-coded
  values so custom CSS stays consistent with the theme. See `mantine.md`.
- Reserve hand-written CSS for bespoke surfaces the library does not
  cover; let the library style its own components.

## Agent Behavior

- After creating or modifying any `*.css` file, run the repo formatter
  (Biome) over it.
- Factor repeated literal values into custom properties rather than
  copying them.
