---
name: arch-review
description: Assess the architecture and health of an existing codebase as a whole — structure and layering, module coupling and circular dependencies, architecture anti-patterns, and tech-debt hotspots (complexity, duplication, stale TODOs) — with an optional Mermaid diagram. Use for whole-codebase questions, not line-level diff review: "review the architecture", "is this codebase healthy", "find circular dependencies", "what's the coupling like", "where's the tech debt", "map/diagram the modules", "are the layers clean". The tool for qa.md's Code-smell/complexity/maintainability dimension. Distinct from /code-review (diff bugs), /simplify (diff cleanup), /review (a PR).
---

# arch-review

**Version:** v1.0.0

Assess an **existing codebase as a whole** — its structure, dependencies, and
debt — and return an actionable health report. This is the concrete tool for
`qa.md`'s **Code-smell / complexity / maintainability** dimension (dimension
4), which otherwise says "if nothing covers it, name the gap." It is
**subject-agnostic**: it works on any language/stack and pulls in what it
needs from the target.

## What this is (and isn't)

Altitude matters — this sits *above* the diff-level tools, and they don't
overlap:

- **`arch-review` (this)** — the *whole repo's* structure, coupling, and debt.
- `/code-review` — correctness bugs in the *current diff*.
- `/simplify` — reuse/efficiency cleanups in *changed code*.
- `/review` — a specific PR.

Reach for this when the question is "how healthy/where is the rot," not "is
this change correct."

## Why a skill that spawns an agent

This is one **skill** (the entry point you invoke and watch) that consolidates
what upstream split across a command + several agents (`arch-review`,
`dependency-analyzer`, `tech-debt`, `diagram`) — they are all facets of one
job, so they are one skill, not four micro-skills.

The **scan itself is read-heavy** (potentially dozens of files), so delegate
it to a **subagent** — the isolation keeps that intermediate reading out of
this conversation; only the structured findings come back. Use the **generic**
`Explore` / `general-purpose` agent with the sharp lens below supplied in the
prompt; do **not** author a bespoke agent type for it (generic-in-subject,
specific-in-method — the method lives in the prompt, not a new agent
definition). For a large repo, fan out **several** analysis agents in parallel
(one per top-level area) and merge — that parallelism is the other reason to
use agents here.

## Procedure

1. **Scope.** Identify the source roots and the language(s)/build system
   (manifest files, entry points). State what's in and out of scope.
2. **Delegate the scan.** Spawn one (or, for a large repo, several parallel)
   analysis agent(s) with this lens, and have each **return structured
   findings only**, not file dumps:
   - **Structure & layering** — the real module/layer boundaries, and whether
     dependencies flow one way (e.g. api → service → data) or leak across
     (layer violations, a UI module importing the DB driver).
   - **Coupling & cycles** — which modules are highly fanned-in/out; **import
     cycles** (A→B→A) — call these out explicitly, they're the highest-signal
     finding.
   - **Anti-patterns** — god modules, duplicated subsystems, a "utils" junk
     drawer, business logic in the wrong layer.
   - **Tech-debt hotspots** — outsized files/functions (complexity),
     duplicated blocks, stale `TODO`/`FIXME`, dead code, pinned-and-rotting
     deps. Rank by *impact × churn* where git history is available, not raw
     size.
3. **Synthesize** the agents' findings into one report (below). Deduplicate;
   resolve disagreements by re-reading the specific spot yourself.
4. **Diagram (optional).** If asked, or if the structure is non-obvious, emit
   a **Mermaid** diagram of the module/layer graph (mark cycles in red). Keep
   it to the top ~2 levels — a diagram of everything is noise.
5. **Report and stop.** Do **not** start refactoring. This skill *assesses*;
   acting on it is a separate, confirmed step (and turning the findings into a
   phased plan is the `modernize` skill's job).

## Report shape

Lead with the verdict, then the evidence, ordered by leverage:

```markdown
## Architecture review — <repo/scope>

**Health:** <one-line take> — biggest risk: <the single worst thing>

### Structure
- <the real layering, and whether it holds>

### Coupling & cycles
- ⚠️ Cycle: a → b → a  (<why it bites>)
- Hotspot: <module> — fanned-in by N modules

### Anti-patterns
- <pattern> @ `path` — <why it's a problem>

### Tech-debt hotspots (by impact × churn)
1. `path` — <complexity/duplication/…>, <suggested direction>

### Diagram   (if requested)
<a Mermaid module/layer graph, per step 4>
```

Keep it proportional — a small repo gets a short report. Don't pad sections
with "none found"; omit empty ones.

## Scaling

- **Small repo** (a few modules): scan inline, no agent needed — the isolation
  buys nothing.
- **Medium**: one analysis agent.
- **Large / monorepo**: fan out parallel agents by top-level area, then merge.

State which you did, and flag anything you sampled rather than read in full —
never let a bounded scan read as exhaustive coverage.

## Provenance

Adapted (idea-level) from the mining census — `claude-plugins` tech-lead
(`arch-review`/`deps`/`diagram`/`dependency-analyzer`) and `claude-tools`
(`tech-debt`/`database-optimizer` ideas). No upstream code reused. See
`SOURCE.md`.
