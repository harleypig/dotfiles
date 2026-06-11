---
name: adr
description: Record an Architecture Decision Record (ADR) — a standalone, numbered document capturing one consequential, hard-to-reverse decision with its context, the decision, the alternatives rejected (and why), and the consequences. Use when a significant architectural/structural choice is being made or has just been made and the *why* must survive: "write an ADR", "record this decision", "document why we chose X over Y", "ADR for the auth model / database choice / module split". Also use to update an ADR's status (Accepted/Superseded). Distinct from a running decisions-log (see the boundary below).
---

# ADR — Architecture Decision Record

**Version:** v1.0.0

An ADR is **one document for one consequential decision**: the context, the
decision, the alternatives you rejected and *why*, and the consequences you
accept. Its job is to keep the *why* from being re-learned or re-litigated —
and, in an agent workflow, to stop a fresh-context agent from re-proposing a
path you already considered and rejected.

This skill is generic — it carries no language/framework assumptions.

## When to write one (the threshold matters)

Write an ADR only for a decision that is **consequential and hard to
reverse**, or **contested / non-obvious**:

- A structural choice that shapes later work (datastore, auth model, module
  boundaries, sync vs async, a framework or pattern you commit to).
- A deliberate *rejection* you don't want re-opened ("we considered X, chose
  not to, because Y").
- A reversal of an earlier ADR (supersede it — see *Status*).

Do **not** write one for routine, easily-reversed, or self-evident choices —
that is noise. When in doubt, ask: "would someone six months from now (or a
fresh agent) waste time re-deriving or re-arguing this?" If no, skip it.

## What goes where — the boundary (read this)

ADRs are **one of several** places "why" is recorded. Keep them distinct so no
two overlap; the failure mode is ADR becoming a second changelog.

| Mechanism | Holds | Shape |
|-----------|-------|-------|
| **ADR** (this) | one *consequential architecture* decision | standalone, numbered, immutable once Accepted |
| **Decisions log** (e.g. `SETUP-AUDIT.md`) | the running, chronological ledger of what changed | lightweight tick-by-tick; **references** ADRs for the big ones |
| **Memory** | project-level "why this work exists" + cross-session facts | not repo-versioned |
| **`SOURCE.md`** | provenance of an adapted/vendored artifact | where it came from + divergences |

So: a decision log entry says *"2026-06-11: adopted X (see ADR-0003)."* The
ADR holds the full context/alternatives/consequences. An ADR **elevates** the
handful of genuinely architectural calls out of the running log — it does not
replace it.

## Where ADRs live

- **Any repo:** `docs/adr/` (created on the first ADR).
- **This dotfiles repo specifically** keeps a *second* area —
  `config/claude/adr/` — for **global-Claude-config / audit** architecture
  decisions, co-located with `SETUP-AUDIT.md` and deployed with the config.
  Route by subsystem: a decision about the Claude config/audit →
  `config/claude/adr/`; any other dotfiles-system decision → `docs/adr/`.
  Two areas because dotfiles is a monorepo with two real subsystems; this is a
  documented dotfiles quirk, not a general rule.

## Procedure

1. **Pick the area** (above) and **find the next number**: glob the chosen
   `adr/` dir for `NNNN-*.md`; next is the highest + 1, zero-padded to 4
   (`0001`, `0002`, …).
2. **Gather the decision** — if context is thin, ask (problem being solved,
   constraints, alternatives weighed, what you're accepting as a downside).
   Don't invent rationale; record the real one.
3. **Write** `<area>/NNNN-<kebab-title>.md` from the template below.
4. **Update the area's `README.md` index** (create it on the first ADR).
5. If this ADR **supersedes** an earlier one, set the old one's status to
   `Superseded by ADR-NNNN` (leave its body intact — ADRs are immutable
   history) and link both ways.

## Template

```markdown
# ADR-NNNN: <Title>

- **Status:** Proposed | Accepted | Superseded by ADR-NNNN | Deprecated
- **Date:** YYYY-MM-DD

## Context

What is true that forces a decision — the problem, constraints, and forces in
tension. Enough that the decision reads as inevitable, not arbitrary.

## Decision

The choice, stated plainly in active voice ("We will …").

## Alternatives considered

### <Alternative> — rejected
Why it was on the table, and the specific reason it lost. Repeat per real
alternative. *This section is the point of the ADR* — it is what stops the
choice being re-opened.

## Consequences

What becomes easier and what becomes harder/accepted as a cost. Include
follow-on work the decision implies. Be honest about the downsides.
```

Keep it proportional — a short ADR for a clear decision is correct; reserve
length for genuinely thorny tradeoffs. Don't pad with empty headings.

## Status lifecycle

`Proposed` → `Accepted` (the decision stands and is in effect) → `Superseded
by ADR-NNNN` (a later ADR reverses it) or `Deprecated` (no longer relevant,
not replaced). **Never rewrite an Accepted ADR's decision** — supersede with
a new one so the history of *why it changed* is preserved.

## Provenance

The ADR format is the industry standard (Michael Nygard). See `SOURCE.md`.
