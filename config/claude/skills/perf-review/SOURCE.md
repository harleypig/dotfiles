# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source; the implementation is our own (house style,
measure-first framing, agent-for-profiling pattern).

## Idea sources (NOT tracked)

Recorded in `../../audit/mining/claude-tools.md`:

- `rafaelkamimura/claude-tools` `perf-check` / `performance-engineer` —
  profiling, bottleneck detection, load. MIT.
- `rafaelkamimura/claude-tools` `database-optimizer` — the data-access / N+1
  lens. MIT.

## Local design decisions

- **Measure-first is the governing rule** (`qa.md` optimization stance):
  baseline before claiming or fixing; separate measured findings from
  hypotheses.
- **Assess-only** — an actual optimization is a separate, measured
  before/after step, not part of this pass.
- The profiling step is delegated to a subagent (read/output-heavy).
- Positioned as the tool for `qa.md`'s Performance & load dimension; distinct
  from `arch-review` (structure vs runtime).
