---
paths:
  - "biome.json"
  - "biome.jsonc"
  - "**/*.ts"
  - "**/*.tsx"
---

# Biome Rules

**Version:** v1.0.0

Biome is the single formatter + linter (+ import sorting) for
JavaScript/TypeScript projects in place of ESLint + Prettier — one fast
tool, near-zero config. Biome does **not** type-check; `tsc` still owns
that (see `typescript.md`).

## Detection

Active when `biome.json` (or `biome.jsonc`) exists at the project root,
or `@biomejs/biome` is a dependency in `package.json`.

## Invocation

```bash
biome check <path>          # lint + format check (no writes)
biome check --write <path>  # apply safe lint fixes + format + organize imports
biome format --write <path> # format only
biome lint <path>           # lint only
biome ci <path>             # CI mode (check, non-zero on any issue)
```

Prefer the project's npm scripts when present:

```bash
npm run check    # biome check .
npm run format   # biome check --write .
npm run typecheck # tsc -b --noEmit
```

## Configuration

`biome.json` is the source of truth. House defaults:

- `formatter.indentStyle: space`, `indentWidth: 2`.
- `javascript.formatter.quoteStyle: double`.
- `linter.rules.recommended: true`.
- `assist.actions.source.organizeImports: on`.
- `vcs.useIgnoreFile: true` so `.gitignore`d paths are skipped; `dist`
  excluded explicitly.

Pin Biome to an exact version (`--save-exact`) so formatting is stable
across machines and CI.

## Agent Behavior

- After creating or modifying any `*.ts` / `*.tsx` / `*.json` / `*.css`
  file: run `biome check --write <file>` (or `npm run format`) to format
  and apply safe fixes, then resolve any remaining lint findings.
- Run `tsc` (or `npm run typecheck`) separately — Biome does not type
  check.
- In pre-commit context: `.pre-commit-config.yaml` runs `biome check`
  (no writes); `.pre-commit-config-fix.yaml` runs `biome check --write`.
- Do not reintroduce ESLint/Prettier alongside Biome in the same repo;
  pick one (see `typescript.md`).
