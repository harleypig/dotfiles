---
name: write-documentation
description: Author or refresh a piece of product/codebase documentation — pick the right form for the audience, derive it from the real code (not from memory), draft it to the documentation bar, wire it into the canonical index + changelog, and lint it. Use for "document this", "write documentation", "write the docs", "update the README", "API docs for X", "the docs are stale". Subject-agnostic; layers stack specifics (e.g. FastAPI auto-OpenAPI) onto generic structure. Composes documentation.md (the bar) and the adr skill (for decisions). documentation.
---

# write-documentation

**Version:** v1.0.0

The procedure that turns "this needs docs" into an accurate, current doc in
the **right form**, derived from the code rather than from memory. The policy
it serves — the bar and the "right form per audience" stance — lives in
`documentation.md`; this skill is the *how*.

## When to reach for it

A behaviour change left its docs stale, a feature shipped without a doc, an
API needs a reference, or a README has drifted from the code. Any time you're
about to **author or refresh a substantial doc** rather than tweak a line.

## Type / composition

A **skill** (an authoring procedure you invoke and watch). It serves
`documentation.md` (the bar + form stance) and takes writing mechanics from
`code-style.md` (78-col wrap, reference links, public-API docstrings). For
**decisions** (the "why") it defers to the **`adr`** skill — don't write an
ADR here. For a large surface, fan the source-reading out to a read-only
agent so accuracy doesn't cost the main context.

## Boundaries — what this is *not*

- **Not ADRs.** A decision record (the "why") → the `adr` skill.
- **Not session/workflow notes.** Handoff, standup, "where I left off" docs
  are session continuity, a different concern — not product documentation.
- **Not spec → plan.** Turning a spec into an implementation plan is the
  built-in Plan / `plan-review`, not a doc deliverable.

## Procedure

1. **Audience + form.** Name who reads it and why, then pick the idiomatic
   form (`documentation.md`): README / usage, API reference, inline
   comment/docstring, or changelog. Prefer **inline over a separate file**;
   add a new file only when the content genuinely needs one (`CLAUDE.md`).
2. **Find the canonical home.** Refresh an existing doc **in place** before
   creating a new one. If the fact already lives somewhere, **link** it —
   don't restate it (Rule of Three for docs, `code-style.md`).
3. **Derive from the source of truth.** Read the actual code/behaviour the
   doc describes — real signatures, schemas, flags, defaults — so the doc is
   *derived*, not inferred. **Layering:** where the stack generates docs (a
   FastAPI app's auto-OpenAPI), point at the generated artifact and the
   stack's patterns (`fastapi-patterns`) instead of hand-writing what the
   framework already produces.
4. **Draft to the bar.** Current and accurate, right form, mechanics from
   `code-style.md`. Every example must actually run/resolve — no invented
   flags or endpoints.
5. **Wire it in.** Link the new/updated doc from its index (README / docs
   index), add a **changelog** entry, and flag any governing rule/skill the
   change makes stale (global *and* local) so it's fixed in the same change.
6. **Lint + verify.** Run `markdownlint` (`markdownlint.md`); confirm every
   reference resolves and every code sample matches the source.

## Output

The documentation itself — inline at the code, or a file in its canonical
home — plus a short note of **what was authored/refreshed**, **what it was
linked from**, and **what else changed** (changelog, a stale rule). If a
decision surfaced that belongs in an ADR, say so and point at the `adr`
skill rather than burying it in prose.

## Provenance

Adapted (idea-level) from the mining census — `claude-tools`
`write-documentation` (multi-format doc generation) and the
`documentation-architect` / `api-documenter` agents (comprehensive,
derive-from-code docs; API-doc mode). No upstream code reused. See
`SOURCE.md`.
