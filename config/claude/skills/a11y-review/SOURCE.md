# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source; the implementation is our own (house style, the
applicability gate, WCAG manual-pass framing).

## Idea source (NOT tracked)

Recorded in `../../audit/mining/claude-tools.md`:

- `rafaelkamimura/claude-tools` `accessibility-specialist` —
  WCAG/ARIA/keyboard audit. MIT.

## Local design decisions

- **Applicability gate** — N/A for headless/CLI/library repos (most of this
  user's work); only runs against a real UI.
- **Manual pass** per `qa.md` (automated checkers miss most issues); judgment
  calls stay in-context, bulk component reads delegated to a subagent.
- **Assess only**; positioned as the tool for `qa.md`'s UI/UX & accessibility
  dimension.
