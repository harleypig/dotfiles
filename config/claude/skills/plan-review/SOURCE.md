# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source; the implementation is our own (house style, the
review lens, the agent-verifies-codebase-assumptions pattern).

## Idea source (NOT tracked)

Recorded in `../../audit/mining/claude-tools.md`:

- `rafaelkamimura/claude-tools` `plan-reviewer` — pre-implementation plan QA
  (risk and flaw detection before building). MIT.

## Local design decisions

- **Reviews, does not rewrite** — surfaces findings for the author to revise.
- **Agent only for codebase-assumption verification** — the one place
  isolation earns its keep; the review itself runs in the main context.
- Positioned under qa as the "before" gate complementing `/code-review`'s
  "after"; distinct from the built-in `Plan` (which creates plans).
