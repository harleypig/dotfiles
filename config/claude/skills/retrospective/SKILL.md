---
name: retrospective
description: Run a pre-merge retrospective on the agent's OWN tooling — after a piece of work (typically the last step before merging a PR), evaluate the friction hit with rules, skills, hooks, patterns files, commands, or mymcp/MCP setup, decide whether any need creating or updating, and capture each as a detailed TODO (routed global vs repo-local). Use for "run a retrospective", "retro this", "did any rules/skills/hooks need updating after this", "config retrospective", or as ship-pr's near-final step. It CAPTURES follow-ups; it does not implement them.
---

# Retrospective

A short, structured reflection on the **agent's own tooling** after a piece of
work — *not* a retro of the product code. The question it answers: **did
anything about how I'm configured get in the way, and should a rule, skill,
hook, patterns file, command, or MCP entry be created or changed because of
it?** Each answer becomes a **detailed TODO**, not an edit — capturing the
follow-up keeps the current PR focused (`CLAUDE.md` *Scope Discipline*).

This is the lightweight, in-the-moment, **per-PR** complement to the deeper
periodic **`claude-audit`** skill: the retrospective *feeds* the audit's
backlog; the audit is where the accumulated items get worked. Don't duplicate
the audit here — surface and record.

## When to run

- As **ship-pr Step 4.6** — a near-final step, after CI is green and after the
  Step 4.5 doc finalization, before the merge. It is **advisory, not a gate**
  (the only merge gate is the merge-finalization hook).
- On request: "run a retrospective", "retro this", "any rules/skills/hooks
  need updating after this work?".

## Step 1 — Reflect: where did the *tooling* create friction?

Look back over the work just done and name concrete pain points with the
agent's configuration. Useful lenses (skip any that didn't bite):

- **Missing guidance** — worked in a language/tool/framework with **no
  `rules/<name>.md`**, or added a dependency with no rule (`CLAUDE.md`
  *Missing or Conflicting Tool Rules*; the `rule-coverage.py` hook may have
  already flagged it).
- **Stale or wrong rule** — an existing rule contradicted how the repo
  actually works, named a file/flag that no longer exists, or fought current
  best practice.
- **A repeated multi-step procedure** — the same 3+ step sequence with
  decisions was done more than once (here or in a past session): candidate for
  a **skill** (`CLAUDE.md` *When to Propose a Skill*).
- **A rule that should have been enforced** — a rule was easy to forget and a
  slip was only caught late: candidate for a **hook** (forcing function).
- **Repeated judgment calls** — the same flag/group/scope decision made 3+
  times: candidate to encode (Rule of Three, `code-style.md`).
- **Recipe depth** — a rule kept needing the same concrete how-to: candidate
  for a **patterns** skill (cf. `*-patterns`).
- **Friction in an existing skill/command/MCP** — a step was unclear, missing,
  or wrong; mymcp/MCP setup needed a tweak.

If nothing bit, say so and stop — a clean retrospective is a valid outcome.

## Step 2 — Decide: what artifact, and where?

For each pain point, decide the **kind** and the **scope**:

- **Kind** — update an existing artifact, or create a new one? Choose rule vs
  skill vs hook vs patterns vs command vs MCP using `EXTENDING.md` *Choosing
  between them* and its placement ladder. (Reference, don't restate it.)
- **Scope** — apply the three-tier model (`CLAUDE.md` *Configuration
  Migration*): language/tool-agnostic or language-specific-but-repo-agnostic →
  **global** (the dotfiles `config/claude/`); only-meaningful-here →
  **repo-local** (the current repo's `.claude/`).

Prefer *promotion to global* when in doubt (it helps every repo on that
stack); keep only genuinely repo-specific items local.

## Step 3 — Capture: a detailed TODO per finding (do not implement)

Write each finding as an **open** `- [ ]` item (never `- [x]` — open items
don't trip the merge-finalization hook). Make it actionable later without
re-deriving the context now. Each entry states:

- **The pain** — what happened, concretely, that exposed the gap.
- **The proposed artifact** — kind (rule / skill / hook / patterns / command /
  MCP) and a working name.
- **The scope** — global (dotfiles) or repo-local, with the target path.
- **A pointer** — the file/commit/line that motivated it.

Route by scope:

- **Repo-local** → the current repo's `TODO.md` (its triage queue / relevant
  section).
- **Global agent-config** → the dotfiles backlog: `TODO.md` (the Claude
  rules/skills/hooks sections) or the `SETUP-AUDIT.md` *Audit backlog*, which
  `claude-audit` reads. When the retrospective runs **outside** the dotfiles
  repo, do not silently edit dotfiles inline — capture the item the way
  `claude-audit` does (scoped dotfiles branch + PR), or hand it to the user to
  run `/claude-audit`. Surface it either way; never drop it.

## Step 4 — Fold into the merge flow

When run as ship-pr Step 4.6, include any TODO additions in the **same
doc-only finalization commit** as Step 4.5 (or a quick follow-up doc commit),
then **re-watch CI** once before merging. The additions are documentation, so
they belong with the finalization, not with code.

## Output

A short report:

- the pain points found (or "none — clean retrospective"),
- for each: the decided kind + scope + target,
- the TODO entries written and where.

Then proceed with the merge (Step 5). This skill never blocks.
