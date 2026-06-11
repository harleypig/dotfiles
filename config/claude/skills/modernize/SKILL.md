---
name: modernize
description: Turn an assessment of aging/legacy code into a phased, incremental migration roadmap (Strangler-Fig) — define the target end-state, decompose into independently-shippable phases sequenced by risk and dependency, each with a done-condition, a safety net, and a rollback. Use for "modernize this", "migration plan", "how do we get off X", "phase out the legacy Y", "incremental refactor roadmap". Plans, does not execute. Composes with the arch-review skill (which assesses). qa / maintainability.
---

# modernize

**Version:** v1.0.0

The forward-looking partner to **arch-review**: arch-review says *where the
rot is*; `modernize` says *how to dig out of it — safely, in shippable
increments*. It produces a **plan**, not changes. Subject-agnostic.

## When to reach for it

You have aging code, a framework/library you want off of, or an architecture
that arch-review flagged — and you need a route from here to there that
doesn't require a big-bang rewrite or a long-lived broken branch.

## Type / composition

A **skill** (a planning procedure you invoke and watch). If you don't already
have an assessment, it **invokes the `arch-review` skill** first rather than
re-deriving the analysis (DRY — reuse the skill, don't duplicate its work).

## Procedure

1. **Target end-state.** State concretely what "modernized" means here — the
   new pattern/library/architecture — and tie each part to a specific
   arch-review finding it resolves. One tight paragraph; resist gold-plating
   (no end-state goals that weren't asked for).
2. **Strangler-Fig decomposition.** Carve the work into phases where the **new
   coexists with the old** and usage cuts over incrementally — never a
   flag-day rewrite. Each phase must be **independently shippable and
   reversible** on its own.
3. **Sequence by risk × dependency.** Enabling/low-risk groundwork first
   (extract the seam, add the safety net); the riskiest cutover last, behind a
   flag where possible. Name the hard dependencies (B can't start before A).
4. **Per phase, specify:** scope, an **observable done-condition**, the
   **rollback**, and the **safety net** required *before* touching it — for
   code without tests, characterization tests come first (`testing.md`).
5. **Flag the danger.** Call out the one or two phases most likely to go
   wrong, and the **seam** (the interface/boundary) that makes incremental
   cutover possible at all — if there isn't one, creating it is phase 1.

## Output

A phased roadmap, riskiest steps flagged, each phase shippable and reversible:

```markdown
## Modernization roadmap — <what → what>

**End-state:** <the target, and the arch-review findings it resolves>
**Seam:** <the boundary that enables incremental cutover>

| Phase | Does | Done when | Rollback | Safety net |
|-------|------|-----------|----------|------------|
| 1 | <groundwork> | <observable> | <how> | <tests/flag> |
| … | | | | |

⚠️ Riskiest: phase N — <why, and the mitigation>
```

**Plan only — do not start migrating.** Executing a phase is a separate,
confirmed step.

## Provenance

Adapted (idea-level) from the mining census — `claude-plugins` tech-lead
`modernize` (Strangler-Fig roadmap idea). No upstream code reused. See
`SOURCE.md`.
