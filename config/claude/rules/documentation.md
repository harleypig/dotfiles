---
# No paths — the documentation bar applies whenever behaviour changes,
# which is triggered by code edits, not by editing a `.md` file.
---

# Documentation Rules

**Version:** v1.0.0

What a change must satisfy for documentation, and the stance on what *form*
a doc should take. Deliberately **non-prescriptive** about writing mechanics
and tooling — those live elsewhere (see *Where the specifics live*).
`code-style.md` owns how docs are *written*; `qa.md` owns the Documentation
*pipeline* stage that gates them.

## The bar

A change that alters behaviour but not its documentation is **incomplete**.
When behaviour changes, update every documentation layer it touches, in the
**same change**:

- **User-facing** — README / usage / API reference, and the **changelog**.
- **In-repo planning** — the `TODO` / roadmap the change advances or closes.
- **Governing rules / skills** — the rules, skills, or `.claude/` docs the
  change makes stale, **global *and* local**.
- **Inline** — comments and docstrings at the code itself; public APIs MUST
  carry one (`code-style.md`).

Docs must be **current** and **accurate**: they describe the code as it is
*now*, with no stale or broken references. Currency beats completeness — a
short true doc beats a thorough stale one.

## Form — be idiomatic to the audience

Pick the **right kind** of doc for who reads it and why, the way `testing.md`
picks the idiomatic test layout per language:

- **The "why" behind a decision** → an ADR (the `adr` skill), not a buried
  code comment.
- **How to *use* a thing** → README / usage / API reference.
- **Why a line of code is the way it is** → an inline comment that explains
  *why*, never one that restates *what* well-named code already says
  (`code-style.md`).
- **What changed** → the changelog.

Prefer **inline documentation over separate doc files**; add a separate file
only when asked (`CLAUDE.md`). And follow the Rule of Three for docs: a
repeated *fact* lives in **one** canonical place and is linked, but
*explanatory* prose rightly overlaps where its job is to explain in its own
context — dedupe the source of a fact, not understanding (`code-style.md`).

## Where the specifics live

| Layer | Holds |
|-------|-------|
| This rule (`documentation.md`) | the doc bar + the "right form per audience" stance |
| `code-style.md` | writing mechanics — 78-col wrap, 72-col comments, reference links, public-API docstrings, dedupe-the-fact |
| `markdownlint.md` (+ prose linters) | the linter that gates Markdown |
| `qa.md` | the Documentation pipeline stage that gates docs pre-merge (dim 13), incl. generated-changelog prep |
| `adr` skill | decision records (the "why") |
| `write-documentation` skill | the procedure that authors / refreshes a doc |
| repo `.claude/` | that repo's concrete doc set, changelog command, and any local doc conventions |

## Agent Behavior

- When a change alters behaviour, update the docs in the **same change**,
  across **every** affected layer above. A behaviour change with no doc
  change is incomplete — say so rather than ship it silently.
- Choose the idiomatic **form** for the audience; prefer inline over separate
  files; never duplicate a reference fact (link the canonical source).
- Reach for the **`write-documentation`** skill to author or refresh a
  substantial doc, and the **`adr`** skill to record a decision.
- Lint Markdown (`markdownlint.md`) and let the **qa** Documentation stage
  gate it; get the repo's concrete doc set + changelog command from its
  `.claude/`.
