# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source: the implementation is our own (house style, the
skill-spawns-generic-agent pattern, the report shape). The ideas were surfaced
during the 2026-06-11 mining and are recorded in the census.

## Idea sources (NOT tracked)

Recorded in `../../audit/mining/`:

- `ruslan-korneev/claude-plugins` `tech-lead` — `arch-review`, `deps`,
  `dependency-analyzer`, `diagram` (architecture audit, coupling metrics,
  circular-dep detection, Mermaid output). MIT.
- `rafaelkamimura/claude-tools` — `tech-debt`, `database-optimizer`,
  `code-architecture-reviewer` (debt cataloguing, hotspot ideas). MIT.

## Local design decisions

- **Consolidated** four mined items (a command + several agents) into one
  skill — they are facets of one job (Rule of Three).
- **Spawns a generic agent** with the lens in the prompt rather than defining
  a bespoke agent type (generic-in-subject, specific-in-method).
- **Assess-only** — turning findings into a phased plan is the (separate)
  `modernize` skill; acting on them is a confirmed step.
- Positioned as the tool for `qa.md`'s Code-smell/complexity dimension, above
  the diff-level `/code-review` · `/simplify` · `/review`.
