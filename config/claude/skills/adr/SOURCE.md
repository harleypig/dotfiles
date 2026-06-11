# Source / provenance

This skill implements the **industry-standard ADR practice**, not a specific
repo's code. Per policy (cite a per-artifact source only when *implementation
detail* is reused), there is no tracked upstream repo here — the template is
the well-known standard, written in house style.

## Basis (a standard, not a repo)

- **Architecture Decision Records** — Michael Nygard's original pattern
  (<https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions>)
  and the community catalog at <https://adr.github.io/>. The Status / Context
  / Decision / Consequences / Alternatives structure is from there.

## Idea-only influence (NOT tracked)

- `ruslan-korneev/claude-plugins` `plugins/tech-lead/commands/adr.md` (MIT)
  **surfaced ADR as a candidate** during the 2026-06-11 repo mining — recorded
  in `SETUP-AUDIT.md` → *Idea sources*. Its implementation was **not** reused:
  it was a slash *command*; this is a generic **skill** (per the skills-over-
  commands decision, ADR-0001), trimmed of its meeting-centric "next steps"
  and decision-cheatsheet, and given the cross-mechanism boundary section. No
  code
  taken, so it stays in the idea registry, not cited as a tracked source.

## Local shape

House-style trims to the standard template: a single Alternatives section that
foregrounds *why each was rejected* (the part that prevents re-litigation),
4-digit zero-padded numbering, an explicit boundary vs the decisions-log /
memory / `SOURCE.md`, and the dotfiles two-area routing.
