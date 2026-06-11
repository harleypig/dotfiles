# Source / provenance

**Adapted, idea-level — no upstream code reused.** Per ADR-0002 there is no
tracked per-artifact source; the implementation is our own (house style, the
batch-and-compat-gate procedure, the security-scan/qa-check composition).

## Idea source (NOT tracked)

Recorded in `../../audit/mining/claude-tools.md`:

- `rafaelkamimura/claude-tools` `deps-update` — dependency auditor with
  compatibility testing + changelog review. MIT.

## Local design decisions

- **Complements Dependabot, doesn't replace it** — `dependabot.md` is the
  automated, scheduled, one-PR-per-bump bot; this skill is the proactive,
  considered, human-driven sweep. A repo can use both.
- **Currency, not vulns** — defers vuln urgency to `security-scan` (don't
  re-derive SCA data); this skill owns "are we behind, and what breaks if we
  catch up?"
- **Compat is proven, not assumed** — every batch is gated by `qa-check`; a
  red batch routes to `debug-assistant` to isolate the offending bump.
- **Majors handled one at a time, changelog-read** — no blind major bumps; no
  silently widened version ranges.
- **Generic over ecosystem** — concrete `outdated`/upgrade commands come from
  the ecosystem rule (`poetry.md`, …), per the layering principle.
- **Folds into the qa / dependency-maintenance orbit** — no new category, no
  new always-on rule; the last Tier-1 mined item.
