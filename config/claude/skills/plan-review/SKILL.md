---
name: plan-review
description: Review an implementation plan or proposal BEFORE building it — surface risky or unverified assumptions, missing edge cases and failure modes, sequencing/dependency problems, blast radius, scope creep, testability gaps, and simpler alternatives. The pre-implementation QA gate (the "before" to /code-review's "after"). Use for "review this plan", "poke holes in this approach", "what am I missing before I build this", "is this plan sound", "critique this design". Reviews the plan; does not rewrite it.
---

# plan-review

**Version:** v1.0.0

Critique an implementation plan **before any code exists** — the cheapest
place to catch a wrong approach. Subject-agnostic.

## Altitude (why it's distinct)

- **built-in `Plan`** — *creates* a plan.
- **`plan-review` (this)** — *critiques* a plan, pre-implementation.
- `/code-review` — reviews the *code* after it's written.

A flaw caught here costs a sentence; the same flaw caught in `/code-review`
costs a rewrite.

## Type / agent use

A **skill** (a focused review you invoke). The plan is usually text already in
context, so no agent is needed — **except** for one high-value case: when the
plan makes **claims about the codebase** ("module X is isolated", "nothing
else calls Y"), spawn an agent to **verify those assumptions against the actual
code** and return confirm/refute. That's the textbook agent job — an isolated
check whose *answer* is what matters.

## Review lens

Work the plan against these, hardest-hitting first:

- **Approach soundness** — does it actually solve the stated problem? Is there
  a materially simpler route?
- **Assumptions** — which load-bearing assumptions are unverified? Verify the
  codebase ones (agent, above); flag the rest as risks.
- **Blast radius** — what can it break, is it reversible, what about
  back-compat / data migration?
- **Missing cases** — failure modes, error handling, edge/empty/large inputs,
  concurrency, partial failure.
- **Sequencing** — ordering and dependency hazards; can it ship incrementally
  or is it all-or-nothing?
- **Testability** — how is each step verified — success **and** failure paths
  (`testing.md`)?
- **Scope** — gold-plating / unrequested generality (scope discipline), or the
  opposite: under-scoped, a step hand-waved.
- **Consistency** — does it fit the repo's existing conventions and patterns,
  or invent a foreign one?

## Output

A verdict plus findings ranked by severity — **surface what to fix, don't
rewrite the plan** (the author revises):

```markdown
## Plan review — <plan>

**Verdict:** sound | sound with fixes | reconsider — <one line>

1. 🔴 <the risk/gap> — <why it bites> → <suggested adjustment>
2. 🟡 …
```

Omit categories with nothing to say; don't pad. If a codebase assumption was
agent-verified, mark it (✓ verified / ✗ refuted).

## Provenance

Adapted (idea-level) from the mining census — `claude-tools` `plan-reviewer`.
No upstream code reused. See `SOURCE.md`.
