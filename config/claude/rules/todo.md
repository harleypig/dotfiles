---
paths:
  - "**/TODO.md"
  - "**/ROADMAP.md"
  - "**/BACKLOG.md"
---

# TODO / Planning-Doc Organization

**Version:** v1.0.0

How a planning doc (`TODO.md`, `ROADMAP.md`, `BACKLOG.md`) is **structured
and routed** — the section taxonomy every item lands in, and the test for
which section a new item belongs to. This rule owns *organization* only; the
neighbouring concerns live elsewhere and are referenced, not duplicated:

- **Lifecycle** (mark `[x]` as you go, prune at merge) → `git.md`.
- **The doc bar** (currency, form-per-audience, inline-first) →
  `documentation.md`.
- **QA gating** (the Documentation pipeline stage) → `qa.md` dim 13; the
  **qa-check** skill audits a doc against *this* rule's structure.
- **Repo-specific scope routing** — which *files/scopes* a given repo splits
  its tracking into (e.g. a dotfiles-vs-agent-config-vs-cross-repo split) —
  lives in **that repo's `.claude/`** (a *TODO Routing* section), which points
  back here for the universal structure below.

The **todo-organize** skill is the forcing function: it reorganizes an
existing doc into this structure and routes new items.

## A planning doc holds only open work

A `TODO.md` / `ROADMAP.md` / `BACKLOG.md` contains **only active, open
tasks** — what is still to do. It is **not** a record of finished work:

- **No done-list, no retained `[x]` items.** Completed work is *removed*. Its
  record lives in the **changelog** (what shipped); the **why** of a notable
  decision goes to the right decision record — an **ADR** (the `adr` skill)
  for an architectural choice, or a repo's **decisions log** — per
  `documentation.md`'s form-per-audience guidance. A `[x]` marks an item *in
  the commit that completes it* and is pruned when that PR merges (`git.md`) —
  never kept as a "Done" archive.
- **No header / preamble block.** No `**Last Updated:**` line (it is stale the
  moment the next edit lands), no "what this file is / how it is structured"
  boilerplate. That explanatory and routing content belongs in this rule and
  the repo's `.claude/` (its *TODO Routing*), not copied atop every planning
  doc. Keep at most a bare title line; the file *is* the task list.

### Deferred "not now" work is not a TODO item

A considered **"not now / maybe-someday"** decision is, by definition, **not
active work** — so it does not sit in the TODO either. It is an **`ICEBOX:`**
note, whose mechanics `code-style.md` owns: a keyword-dense marker comment at
the nearest relevant **code**, revisited only on request (the agent scans for
`ICEBOX:` when a matching feature request arrives — see `CLAUDE.md`). So:

- **Deferred with a code anchor** → an `ICEBOX:` comment at that code, *not* a
  "someday / maybe / later" pile in the TODO.
- **Declined outright** ("evaluated, won't do") → a **decision record**, not a
  TODO item: an **ADR** (the `adr` skill) for an architectural decision, else
  the repo's **decisions log** (`documentation.md` owns which form fits).

The TODO never becomes a parking lot for work nobody has committed to doing.

## Organize by subject, not by activity

The default failure mode is grouping by **activity** — a "Pre-commit",
"CI/CD", or "Testing" section with each language's work scattered as bullets
inside. That smears one subject across many sections. Instead, group by
**subject**, and treat activity (pre-commit / CI / test / lint) as an *inline
property* of each item, not a section of its own.

## The four section kinds

Every item lands in exactly one of these:

1. **`## <Language> Setup`** — *all* setup/maintenance for one language: its
   QA dimensions (format, lint, type-check, test, security, coverage, docs),
   **tool + version-manager** setup (perlbrew, nvm, pyenv, rustup),
   **testing** (bats, prove, pytest), toolchains, language-specific config,
   and the agent rules/skills for its tools.
2. **`## <Subject> Setup`** — a maintained **non-language** domain you stand
   up and keep in good order: shell-startup, statusline, container/lint
   tooling, the CI/CD pipeline itself, documentation/prose. Holds that
   subject's tooling, testing, and subject-scoped config.
3. **Work-type section** (e.g. `## Features & fixes`) — feature, bugfix, and
   enhancement work, which is organized by *what kind of work it is*, not by
   subject (a feature is a feature, and may cross language/subject
   boundaries). **General** config changes — those tied to no one subject —
   also live here.
4. **Project / audit** (a **descriptive name**, *not* `Setup`) — bounded work
   that **finishes**: a migration, an extraction, a one-off audit, a research
   thread, template creation.

### The discriminator: maintained vs. bounded

Kinds 1–2 (`Setup`) versus kind 4 turn on one question:

> **Is this an ongoing thing I maintain, or a project that ends?**

A maintained subject (a language, the shell-startup, the CI pipeline) →
`## <Subject> Setup`. A bounded project with an end state (a `$HOME` dotfile
audit, carving a subtree into its own repo) → its own descriptively-named
section. "It has a finish line" is the tell for kind 4.

## Routing a new item

1. **Setup / tooling / testing / QA / subject-scoped config** → the relevant
   `## <Subject> Setup` (create it if absent). Version-manager and toolchain
   work goes in **its language's** Setup.
2. **Feature / bugfix / enhancement** (behavioural, possibly cross-cutting) →
   the **work-type** section.
3. **Config change** → by scope: language-specific → that language's Setup;
   subject-specific → that subject's Setup; **general** → the work-type
   section.
4. **Bounded project / audit / migration / research** → its own descriptive
   section.

In every case, note the **activity** (pre-commit / CI / test / lint) and any
**phase dependency** *inline on the item*, not by relocating it to an
activity section.

## Naming & form

- Section heading: `## <emoji?> <Subject> Setup` — match the repo's existing
  heading style (an emoji prefix if the file uses them). Project/audit
  sections keep a plain descriptive name.
- **When you hoist an item out of a cross-cutting area** into its subject
  section, leave a one-line **pointer** where it was (`→ see <Subject>
  Setup`), so the originating task doesn't silently lose the dependency.
- A section's lifetime tracks its items: **add** a `## <Subject> Setup`
  section when its first item arrives, and **remove** it when its last item is
  completed/pruned. Never leave an empty section, and never create one
  speculatively — a subject with no open work simply has no section.

## Sources

House convention — no external source. Grounded in this config's own
framework: the subject-over-activity stance mirrors the three-tier placement
model in `CLAUDE.md` *Configuration Migration* and `EXTENDING.md`, and defers
lifecycle/doc/QA concerns to `git.md`, `documentation.md`, and `qa.md`.

## Agent Behavior

- A planning doc holds **only open tasks**. Never add a "Done" / "Completed"
  section or keep `[x]` items as an archive — completed work is pruned to the
  changelog / decisions log (`git.md`). When you prune the **last** item from
  a section, remove the now-empty section too — no empty `## <X> Setup`
  shells.
- A deferred **"not now / maybe-someday"** item is **not** a TODO item: record
  it as an `ICEBOX:` marker at the relevant code (`code-style.md`), or — if
  declined outright — as a decision record (an **ADR** via the `adr` skill, or
  the decisions log; see `documentation.md`). Don't keep a someday pile in the
  TODO.
- Strip any **header / preamble** (a `**Last Updated:**` line, a
  description / scope / structure boilerplate block) when authoring or
  reorganizing a planning doc, in **any** repo — routing and explanatory
  content lives in this rule and the repo's `.claude/`, not atop the file.
- When **adding** a TODO/ROADMAP/BACKLOG item, route it per *Routing a new
  item*; create the `## <Subject> Setup` section if it doesn't exist yet.
- **Never group by activity.** Pre-commit / CI / testing are inline notes on
  an item, not top-level sections.
- Apply the **maintained-vs-bounded** test to choose `Setup` vs a descriptive
  project/audit name; a thing with a finish line is a project, not a `Setup`.
- When a planning doc has **drifted** from this structure (activity-grouped
  sections, a subject scattered across several), suggest the **todo-organize**
  skill rather than reshuffling ad hoc.
- Defer lifecycle to `git.md` (mark `[x]` as you go; pruning happens at
  merge), the doc bar to `documentation.md`, and the repo's *scope* routing to
  its `.claude/`.
