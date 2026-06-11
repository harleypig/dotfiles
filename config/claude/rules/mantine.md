---
paths:
  - "**/*.tsx"
  - "**/*.jsx"
---

# Mantine Rules

**Version:** v1.0.0

Conventions for the Mantine React component library. Used with React and
TypeScript (`react.md`, `typescript.md`).

## Detection

Active when `@mantine/core` is a dependency in `package.json`.

## Keep it lean

The goal is a fast web app, not framework bloat:

- Depend on **`@mantine/core` + `@mantine/hooks` only** unless a specific
  feature genuinely needs another `@mantine/*` package. Each extra package
  is bundle weight — justify it.
- Import components from `@mantine/core` (tree-shaken). If the CSS bundle
  becomes a concern, switch from the global `@mantine/core/styles.css`
  import to per-component CSS imports.
- Check the gzip bundle size after adding components; flag notable jumps.

## Setup

- Wrap the app once in `<MantineProvider theme={theme}>` at the root and
  import `@mantine/core/styles.css` before app styles.
- PostCSS is required: `postcss-preset-mantine` + `postcss-simple-vars`
  in `postcss.config.cjs` with the Mantine breakpoint variables.
- Keep the theme in a dedicated `theme.ts` via `createTheme(...)`.

## Versioning

Mantine's major version is tied to React:

- **Mantine 7** supports React 18.
- **Mantine 8/9** require React 19.

Match the major to the project's React version; do not upgrade Mantine
past what React supports without also upgrading React.

## Usage

- Use Mantine components for app **chrome** (AppShell, navigation,
  buttons, inputs). Use bespoke CSS for content surfaces the design wants
  to feel custom (see `css.md`).
- Theme via `theme.ts` and Mantine CSS variables; avoid scattering
  hard-coded colors/spacing.

## Agent Behavior

- Default to `@mantine/core` + `@mantine/hooks`; surface any new
  `@mantine/*` dependency and its bundle cost before adding it.
- After adding components, run `npm run build` and note the bundle size.
