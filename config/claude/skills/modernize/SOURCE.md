# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source; the implementation is our own (house style, the
arch-review composition, the roadmap shape).

## Idea source (NOT tracked)

Recorded in `../../audit/mining/claude-plugins.md`:

- `ruslan-korneev/claude-plugins` `tech-lead` `modernize` — legacy assessment
  + phased Strangler-Fig migration roadmap. MIT.

## Local design decisions

- **Composes with `arch-review`** (invokes it for the assessment) rather than
  re-deriving structure analysis — DRY across skills.
- **Plan-only**, with an explicit safety-net + rollback per phase and a
  characterization-tests-first rule (`testing.md`); execution is a separate,
  confirmed step.
- Positioned under qa / maintainability — the forward-looking partner to
  `arch-review`.
