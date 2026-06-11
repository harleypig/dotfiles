---
paths:
  - "**/vite.config.*"
---

# Vite Rules

**Version:** v1.0.0

Conventions for the Vite build tool / dev server.

## Detection

Active when a `vite.config.ts` (or `.js`) exists at the project root.

## Configuration

- Keep `vite.config.ts` typed and minimal.
- **Dev proxy:** proxy the API path (e.g. `/api`) to the backend in the
  `server.proxy` config so the frontend uses relative URLs and avoids
  CORS in development; make the target overridable via an env var.
- **Build-time constants:** inject values like the app version and build
  commit via `define` (e.g. `__APP_VERSION__`, `__GIT_HASH__`); declare
  them in a `global.d.ts`. When shelling out for a value (git hash), use
  `execFileSync` (no shell), not `execSync`, and wrap it in try/catch so
  a non-git build still works.

## Environment variables

- Runtime env exposed to the client must be prefixed `VITE_` and read via
  `import.meta.env`. Never expose secrets to the client bundle.

## Agent Behavior

- After changing `vite.config.ts`, run `npm run build` to confirm the
  config and the production build are valid.
- Keep `define` constants in sync with their `global.d.ts` declarations.
