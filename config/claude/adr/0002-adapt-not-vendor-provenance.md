# ADR-0002: Adapt-not-vendor; SOURCE.md only on implementation reuse

- **Status:** Accepted
- **Date:** 2026-06-11

## Context

The config is improved partly by drawing on external repos (skills, agents,
commands). A prior convention was "vendor-and-modify, recording a `SOURCE.md`"
for borrowed material. Mining FastAPI/SQLAlchemy/Python repos exposed two
problems: (1) much upstream code prescribes foreign idioms (e.g.
`dependency-injector`) that clash with house conventions and would fail
QA-by-consistency if copied; (2) we often want only the *idea*, not the code —
yet a `SOURCE.md` implies a tracked upstream to diff against, which is
meaningless when nothing was actually copied.

## Decision

1. **Adapt over vendor.** Default to re-implementing the idea in house idiom,
   not copying upstream files wholesale. Vendor verbatim only when the
   upstream is genuinely lean and idiomatic for us.
2. **Per-artifact `SOURCE.md` only when implementation detail was reused** —
   something concrete to track for upstream updates. Liked the idea but used
   none of the code → no `SOURCE.md` entry.
3. **Idea-only sources go in one registry** — `SETUP-AUDIT.md` → *Idea
   sources* — so future audits know where to look again, without implying a
   tracked dependency.

## Alternatives considered

### Keep "vendor-and-modify everything with a SOURCE.md" — rejected

Simple and uniform. Rejected because it pulls in foreign idioms that violate
the consistency rule, and it attaches update-tracking provenance to artifacts
that share no code with any upstream — provenance theater that rots.

### Pure clean-room (never record sources) — rejected

Avoids all provenance overhead. Rejected: it discards genuinely useful "where
to mine again" knowledge and loses the ability to re-check a source we *did*
borrow implementation from when it updates.

## Consequences

- `fastapi-patterns` / `sqlalchemy-patterns` carry a `SOURCE.md` citing only
  `claude-plugins` (implementation reused); the official FastAPI skill and
  `claude-tools` are recorded as *idea sources* only.
- The `adr` skill, built on the standard Nygard template, cites the standard —
  not the `claude-plugins` command that merely surfaced the idea.
- Two distinct records by design: `SOURCE.md` = tracked code provenance; the
  *Idea sources* registry = inspiration to re-mine. Pairs with the "layer the
  generic over the specific" principle (`EXTENDING.md`): split a borrowed
  mixed artifact, adopt the generic intent in our own idiom.
