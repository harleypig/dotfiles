# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source: the recipes (TypedDict, Protocol, generics,
narrowing, NewType, …) are general Python typing knowledge, written in house
style. The `claude-plugins` skill surfaced the *idea* of a typing-depth skill.

## Idea source (NOT tracked)

Recorded in `../../audit/mining/claude-plugins.md`:

- `ruslan-korneev/claude-plugins` python `typing-patterns` — "no
  `type: ignore`" typing depth. MIT.

## Local design decisions

- **Policy lives in `python.md`** (mypy/pyright, justify any `# type:
  ignore`); this skill is the *technique* to avoid needing the ignore.
- Categorized as Python **typing** depth (pairs with `python.md`), not
  testing — distinct from `pytest-patterns` despite both being Python-depth
  skills.
