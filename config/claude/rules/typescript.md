---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---

# TypeScript Rules

**Version:** v1.0.0

## Detection

Active when the repository contains a `tsconfig.json`, or any `*.ts` /
`*.tsx` file is being created or modified.

## Toolchain

| Concern           | Tool                                 |
|-------------------|--------------------------------------|
| Type checking     | `tsc` (`tsc -b --noEmit`)            |
| Lint + format     | Biome — see `biome.md`              |
| Build / dev       | the repo's bundler (e.g. Vite)       |

Lint/format is **Biome**, not ESLint + Prettier. `tsc` is the only type
checker; Biome does not type-check.

## tsconfig

- `strict: true`. Also enable `noUnusedLocals`, `noUnusedParameters`,
  `noFallthroughCasesInSwitch`.
- `moduleResolution: "bundler"` for Vite/modern bundlers.
- Keep `noEmit` for app code the bundler compiles.

## Style

- **No `any`.** Use `unknown` at boundaries and narrow. Do not add
  `// @ts-ignore` / `// @ts-expect-error` without a comment explaining why.
- Use `import type { … }` for type-only imports.
- Prefer `interface` for object/props shapes; `type` for unions,
  intersections, and mapped/utility types.
- Annotate exported functions' return types when not trivially inferred;
  internal helpers may rely on inference.
- Validate external data (HTTP responses, config) at the boundary; trust
  it internally. Define response types next to the fetch layer.

## Naming

- **Types / interfaces / components / classes:** PascalCase.
- **Variables / functions / methods:** camelCase.
- **Constants:** UPPER_SNAKE_CASE for true module-level constants.
- **Files:** components `PascalCase.tsx`; other modules `camelCase.ts` or
  match the surrounding repo convention.

## Agent Behavior

- After creating or modifying any `*.ts` / `*.tsx`:
  1. Run Biome (`biome check --write` / `npm run format`).
  2. Run `tsc` (`npm run typecheck`) and resolve type errors.
- Do not introduce new untyped public APIs or `any`.
