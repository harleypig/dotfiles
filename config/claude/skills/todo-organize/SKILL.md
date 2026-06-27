---
name: todo-organize
description: Reorganize a planning doc (TODO.md / ROADMAP.md / BACKLOG.md) into the subject-based structure from rules/todo.md, and route new items to the right section. Use this whenever a planning doc needs restructuring or an item needs placing — "organize the TODO", "reorganize TODO.md", "clean up the todo", "where does this item go", "this TODO is a mess / scattered across sections", "restructure my roadmap", "the todo has a stale header" — and proactively when you notice a planning doc grouped by activity (Pre-commit / CI / Testing sections) instead of by subject, completed `[x]` items lingering, or a `Last Updated:` / preamble header. The forcing function for rules/todo.md.
---

# todo-organize

**Version:** v1.0.0

Reorganize a planning doc into the structure `rules/todo.md` defines, and route
new items into it. This skill is the **procedure**; **`rules/todo.md` is the
source of truth** — read it first and defer to it on every specifics question
(the four section kinds, the maintained-vs-bounded test, the routing decision,
the active-only / no-header / no-empty-shells invariants).

## Read first

1. **`rules/todo.md`** — the convention this skill applies. Everything below is
   *how to carry it out*, not a restatement of the policy.
2. **The repo's `.claude/` TODO routing** (a *TODO Routing* section in
   `WORKFLOW.md` / `CONVENTIONS.md`, if present) — the repo-specific **scope**
   split (e.g. which files/scopes this repo tracks separately). The global rule
   owns structure; the repo owns scope.

## When to use

- A planning doc is **grouped by activity** (a "Pre-commit", "CI/CD", or
  "Testing" section with each language's work scattered inside) rather than by
  subject — the signature problem the rule fixes.
- A doc carries a **header/preamble** (`Last Updated:`, a description / scope /
  structure block) or **completed `[x]` / "Done" items** that should have been
  pruned.
- A subject's work is **smeared across several sections**.
- You're **adding an item** and need to place it (single-item routing).

## Mode A — reorganize an existing planning doc

Work in passes so the result is reviewable, not a blind rewrite:

1. **Inventory.** List every `##`/`###` section and its items. Note which
   sections are activity-grouped, which items are misfiled, any header block,
   and any completed/`[x]` items.
2. **Classify each item** by the rule's four kinds — `## <Language> Setup`,
   `## <Subject> Setup`, a work-type section (features/fixes + general config),
   or a bounded project/audit (descriptive name). Apply the
   **maintained-vs-bounded** test for Setup-vs-project. Route per *Routing a new
   item* in the rule.
3. **Plan the target sections** before moving anything. Create a
   `## <Subject> Setup` section only when it will hold at least one item; reuse
   the repo's heading style (emoji prefix if the file uses them).
4. **Hoist items** into their target sections. **When an item leaves a
   cross-cutting area, leave a one-line pointer** where it was
   (`→ see <Subject> Setup`) so the originating task doesn't silently lose the
   dependency.
5. **Enforce the invariants** (`rules/todo.md`): strip the header/preamble;
   remove completed work (its record belongs in the changelog / decisions log /
   an ADR, not the TODO); move a deferred "not now" item to an `ICEBOX:` marker
   at the relevant code (`code-style.md`); delete any section left empty.
6. **Verify** — `markdownlint` clean, prose ≤ 78 **display** columns (count
   characters, not bytes — e.g. `perl -CSD` / `wc -L`, since an em-dash is one
   column but multiple bytes), and every cross-reference / pointer resolves.

Surface the soft calls (where a shared concern could sit in more than one
Setup) rather than silently choosing — the same judgment the rule leaves open.

## Mode B — route a single new item

Apply the rule's *Routing a new item* decision directly:

- Setup / tooling / testing / QA / subject-scoped config → the relevant
  `## <Subject> Setup` (create it if absent; version-manager and toolchain work
  goes in **its language's** Setup).
- Feature / bugfix / enhancement, or **general** config → the work-type section.
- Bounded project / audit / migration / research → its own descriptive section.
- A deferred "not now" item is **not** a TODO item → `ICEBOX:` marker
  (`code-style.md`); a declined one → a decision record.

Note the item's **activity** (pre-commit / CI / test) and any **phase
dependency** *inline*, never by relocating it to an activity section.

## After organizing

- Leave the doc holding **only open work** — the proof you applied the rule.
- `qa-check`'s Documentation dimension audits a planning doc against
  `rules/todo.md`; this skill is what fixes what that audit flags.
