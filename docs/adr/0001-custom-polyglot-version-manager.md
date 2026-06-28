# ADR-0001: Build a custom polyglot version-manager orchestrator that wraps native managers

- **Status:** Accepted
- **Date:** 2026-06-28

## Context

This repo needs a consistent, idempotent way to **install, update, and
remove** per-language toolchains on a fresh machine — Node (`nvm`), Perl
(`perlbrew`), Python (`pipx` + `uv`), with Ruby and Rust to follow. `TODO.md`
already defines the shared *Tool/Version Manager Setup* pattern: one
documented, XDG-aware install + shell-init per manager, lazy-loaded at runtime
in `config/shell-startup/<lang>`. What is missing is the **lifecycle** half —
a single entry point to drive install/update/remove across languages.

A whole category of off-the-shelf tools already manages multiple language
runtimes under one command: mise, asdf, proto, vfox, aqua, Hermit, pkgx,
devbox (and the single-language Volta). They are mature and capable. The
question this ADR settles is whether to adopt one or build our own.

Two forces are in tension:

- **Unified CLI across languages** — what every off-the-shelf tool offers:
  one tool installs Node, Python, Perl, etc., under one abstraction.
- **Native-manager fidelity** — keeping each language in *its own
  ecosystem's* idiomatic manager (nvm, perlbrew, pipx, uv), with that
  manager's own features, plugins, and community workflows intact, rather
  than behind a generic abstraction that installs runtimes directly.

The repo's existing design (`config/shell-startup/<lang>` lazy-loads each
*native* manager) has already committed to native-manager fidelity. An
off-the-shelf unified tool would either replace that investment or sit
awkwardly beside it.

## Decision

We will **build a small, custom polyglot orchestrator**: a Bash entry point
in `bin/` that accepts `install` / `update` / `remove` plus a list of
languages (or lists what's available), dispatching to per-language code in
`lib/version-managers/<lang>`. Each language module wraps that language's
**native** manager(s) — including the multi-manager case (Python →
`pipx` + `uv`).

The orchestrator owns only the **install/update/remove lifecycle**. The
**runtime lazy-load** stays in `config/shell-startup/<lang>`, unchanged. The
two halves remain separate.

## Alternatives considered

### mise (ex-rtx) — rejected

The strongest off-the-shelf option: fast (Rust), asdf-plugin-compatible, with
env-var and task-runner features. Rejected because it installs runtimes
directly under its own abstraction, displacing the native managers
(nvm/perlbrew/pipx/uv) this repo deliberately standardized on, and because its
env-var/task-runner scope duplicates things this repo already does its own
way — a bigger, more generic tool than the problem needs.

### asdf — rejected

The original plugin-based polyglot manager. Same core mismatch as mise
(unified runtime install, not native-manager wrapping), with a shim-based
model that
adds per-invocation overhead and its own shell integration competing with the
repo's `config/shell-startup/<lang>` approach.

### proto, vfox, aqua, Hermit, pkgx, devbox — rejected

Surveyed as the lesser-known field. Each is competent in its space (vfox is
notably cross-platform incl. Windows; aqua is declarative; Hermit is
per-project; pkgx/devbox lean package-runner / Nix). All share the same
disqualifier: they unify runtime installation under one tool instead of
wrapping each language's native manager, and several bring substantial extra
scope (project envs, Nix, registries) the repo neither needs nor wants.

### Volta — rejected

Well-regarded but **JavaScript-only** (node/npm/yarn/pnpm); it cannot satisfy
the polyglot requirement at all.

### Do nothing / per-language ad-hoc scripts — rejected

Leaving each language's install as a separate ad-hoc script reproduces the
inconsistency the *Tool/Version Manager Setup* pattern exists to remove, and
gives no single `install node python perl` entry point.

## Consequences

**Easier:**

- One consistent verb-based entry point (`install` / `update` / `remove`)
  across all languages, matching the repo's existing dispatcher idiom
  (`bin/docker_wrapper`).
- Each language keeps its native manager and that ecosystem's full feature
  set — no lowest-common-denominator abstraction.
- Clean separation of concerns: lifecycle in `bin/` + `lib/`, runtime
  lazy-load in `config/shell-startup/<lang>`.

**Harder / accepted costs:**

- We own and maintain the orchestrator and every per-language module —
  including update/remove paths, which differ per native manager and must be
  verified against each manager's actual capabilities (e.g. clean uninstall
  support).
- We forgo the off-the-shelf tools' breadth (declarative pinning files,
  cross-platform Windows support, project-scoped envs). If cross-platform
  parity later becomes a hard requirement, `vfox` is the closest fallback and
  this decision should be revisited (supersede this ADR).
- "Yet another polyglot version manager" exists in the world — deliberately
  scoped to *only* orchestrating native managers, nothing more.

## Follow-on work

- Build the orchestrator (`bin/`) + the per-language module contract
  (`lib/version-managers/<lang>`), tracked under *Tool/Version Manager Setup*
  and *Node Setup* in `TODO.md`.
- Each new language module verifies its native manager's install/update/remove
  support before implementation.
