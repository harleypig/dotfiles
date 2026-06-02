# Vitest Rules

**Version:** v1.0.0

Vitest is the unit/integration test runner for JavaScript/TypeScript
projects (Vite-native). It covers pure logic and, with a DOM environment,
component logic — but it is **not** a browser. Real end-to-end testing uses
Playwright (see a project's e2e setup), not Vitest. Pairs with
`typescript.md` and `biome.md`; for React see `react.md`.

## Detection

Active when `vitest` is a dependency in `package.json`, a `vitest.config.*`
exists, or `*.test.ts(x)` / `*.spec.ts(x)` files are present.

## Invocation

Prefer the project's npm scripts when present:

```bash
npm test          # vitest run   (one-shot; CI/pre-commit)
npm run test:watch  # vitest      (watch mode, local dev)
```

Direct: `vitest run` (one-shot), `vitest` (watch), `vitest run <file>`
(single file), `vitest run -t "<name>"` (by test name).

## Configuration

- Keep a small `vitest.config.ts` (`defineConfig` from `vitest/config`), or
  add a `test` block to the Vite config. Do not duplicate both.
- **Environment:** default `node` for pure logic. Use `jsdom` (or
  `happy-dom`) only when the code under test touches DOM/browser APIs
  (`localStorage`, `window`, rendering). `jsdom` is just the environment —
  it does not need its own rules file.
- Scope tests with `include` (e.g. `src/**/*.test.ts`).
- Prefer **explicit imports** — `import { describe, it, expect } from
  "vitest"` — over `globals: true`, so no extra tsconfig `types` entry is
  needed and the source stays obvious. If you do enable `globals`, add
  `"vitest/globals"` to tsconfig `types`.

## Conventions

- **Co-locate** tests as `<name>.test.ts` next to the source.
- **Extract to test.** Logic worth testing that is trapped inside a
  component (or behind build-time globals like Vite's `define`) should be
  lifted into a plain module and imported by both the component and the
  test. Keep such modules free of framework/build-global imports so tests
  load fast and clean (type-only imports are fine — they are erased).
- **Test the stable, valuable core:** parsing/migration, persistence
  round-trips, reducers/pure transforms, edge cases and failure paths.
- **Don't test throwaway code.** If logic is about to be rewritten (a known
  upcoming refactor), don't invest in tests that will be discarded; note it
  and revisit once the shape stabilizes.
- Mocking: prefer real implementations; use `vi.fn()` / `vi.mock()` only at
  genuine boundaries. Reset state between tests (`beforeEach`).
- Component tests (React Testing Library) are allowed for component logic,
  but they are still not e2e — keep browser/interaction flows in Playwright.

## Agent Behavior

- After creating or modifying tested logic, run `npm test` (or
  `vitest run <file>`) and make it green before moving on.
- Run Biome and `tsc` separately (Vitest does not lint or type-check).
- In pre-commit context: add a check-only `frontend-test` (or equivalent)
  local hook running `vitest run` in `.pre-commit-config.yaml`; there is no
  fix variant.
- When adding Vitest to a project that lacks a runner, surface the new dev
  deps (`vitest`, and the DOM env if used) per the rule-coverage policy.
