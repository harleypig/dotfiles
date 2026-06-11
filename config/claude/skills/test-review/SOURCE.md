# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source; the implementation is our own (house style, the
testing.md bar, the agent-maps-coverage pattern).

## Idea source (NOT tracked)

Recorded in `../../audit/mining/claude-plugins.md`:

- `ruslan-korneev/claude-plugins` python `test-reviewer` — coverage + test
  quality (AAA, naming, responsibility). MIT.

## Local design decisions

- The quality bar is **`testing.md`** (success **and** failure paths,
  regression-per-bug); not a raw coverage %.
- **Assess only** — runs nothing (that's `qa-check`) and writes nothing (the
  runner / `bats-setup` do that).
- Large-suite read delegated to a subagent.
- Positioned as the tool for `qa.md`'s Tests dimension (quality), distinct
  from qa-check (execution) and `/code-review` (diff).
