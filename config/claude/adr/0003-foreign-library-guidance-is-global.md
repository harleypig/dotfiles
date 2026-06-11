# ADR-0003: Guidance for repo-foreign libraries is global, front-loaded

- **Status:** Accepted
- **Date:** 2026-06-11

## Context

`EXTENDING.md` says global+lazy beats per-repo copies, and "layer the generic
over the specific." But the *placement and timing* for a library used by only
**one** repo today was left ambiguous, and the mining census mislabeled such
items "adopt per-repo-need" — implying repo-local, or deferral until several
repos need them. The Rule of Three (`code-style.md`) also nudges "wait for the
third instance" before abstracting, which seems to argue for deferral. The
user works across many repos in different languages, and the same external
libraries recur across them.

## Decision

Guidance (a skill, rule, etc.) about anything **foreign to the current
repo** — a third-party library/framework/tool, **or our own code hosted in a
different repo** — lives in the **global generic layer**, **even if only one
repo uses it today**, and is authored the **first** time it is needed, not
deferred.

"Foreign to this repo" = shared by nature: it already exists outside this repo
and will recur in another. Repo-local `.claude/` is reserved for *this repo's
own* code, architecture, and quirks — never for an external dependency. The
build/skip decision is still "do we use it at all"; but when we build, the
placement is global and the timing is now.

## Alternatives considered

### Defer to repo-local until more repos need it (Rule of Three) — rejected

The "third instance" is effectively guaranteed for a shared library, so
deferral only means re-discovering the need later and redoing the work
out-of-context. The Rule of Three guards against speculatively abstracting
*our own* code before a pattern is proven; an external library is not
speculative — it is already stable, and "foreign to the repo" is itself the
signal that it will recur.

### Keep it global but build lazily (only when a 2nd repo appears) — rejected

Same remember-and-redo-later cost. Front-loading while already doing the grunt
work for the first repo is strictly cheaper than context-switching back to it
later.

## Consequences

- On first use of an external library in any repo, its guidance is authored as
  a global artifact (path-scoped rule / on-demand skill) — as already done for
  FastAPI, SQLAlchemy, pydantic.
- The mining census "Tier 3" is about *whether/when* to build (when first
  used), not *where* (always global).
- Our-own-repo patterns stay repo-local and continue to follow the Rule of
  Three — this decision applies only to repo-foreign things.
- Accepted cost: a little up-front work for a library that might never recur.
  Cheaper than deferred re-work and the risk of forgetting. Recorded in
  `EXTENDING.md` → *Foreign to the repo → global, and front-loaded*.
