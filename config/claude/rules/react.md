# React Rules

**Version:** v1.0.0

Conventions for React (with TypeScript — see `typescript.md`). Lint and
format with Biome (`biome.md`).

## Detection

Active when `react` is a dependency in `package.json`, or `*.tsx` files
are present.

## Components

- **Function components only** — no class components.
- One primary component per file; the file is named for it
  (`Reader.tsx`). Small helper components may share a file.
- Props are typed with an `interface` (`interface ReaderProps { … }`);
  destructure them in the signature.
- Keep components focused. When a component grows past one clear
  responsibility, extract a child component.

## Hooks

- Follow the Rules of Hooks: call hooks unconditionally at the top level.
- Provide complete `useEffect` dependency arrays; do not silence the lint
  rule — fix the dependency or restructure.
- Local state with `useState`; complex transitions with `useReducer`.
  Reach for context only when prop-drilling becomes painful — do not add
  global state stores prophylactically (mind the bundle, see `mantine.md`).
- Side effects (fetching, subscriptions, storage) live in `useEffect`,
  with cleanup where applicable (cancel in-flight work on unmount).

## Structure

- `src/main.tsx` mounts the app inside `StrictMode` and any providers.
- `src/components/` for reusable components; co-locate component-specific
  styles.
- Keep the data/fetch layer (typed API client) separate from components.

## Agent Behavior

- Honour `typescript.md` and `biome.md` for every change.
- Prefer composition and small components over large multi-purpose ones.
- After UI changes, build (`npm run build`) to confirm types + bundle.
