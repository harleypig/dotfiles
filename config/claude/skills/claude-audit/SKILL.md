---
name: claude-audit
description: Run the Claude Code setup audit — review the global config (rules, skills, agents, hooks, commands, plugins, MCP servers, settings) and the current repo's local Claude setup for context economy and right-fit, then apply and record the changes. Use when the user says "/claude-audit", "run the claude audit", "audit my claude setup", "audit the claude code setup", or wants to trim context, re-home a rule, or re-evaluate plugins. Modifies the dotfiles repo (global config) via a PR and sets up the local repo as needed.
---

# Claude Audit

Run the **Claude Code setup audit**: keep the agent's configuration lean
(context economy) and each artifact in the right place and right form
(right-fit) — across **both** the global config and the repo you're invoked
from.

## Two scopes

1. **Global** — the dotfiles repo's `config/claude/` (deploys to `~/.claude/`):
   `settings.json` (plugins, hooks), `rules/`, `skills/`, `commands/`,
   `EXTENDING.md`, `SETUP-AUDIT.md`, plus the repo's `TODO.md` follow-ups.
   Most changes land here — rules and plugins are global.
2. **Local** — the current repo's own Claude setup: its `.claude/` (CLAUDE.md,
   rules, skills) and any per-repo MCP/plugin needs.

## Global is re-evaluated from every repo — by design

The global config is shared across many repos, so the audit re-examines it
**every time it runs, from whatever repo invoked it** — quite possibly several
times in a single day. That repetition is expected, not wasted work:

- Each repo exercises the shared languages/frameworks differently and brings
  its **own quirks**. A gap, rough edge, or missing rule that only one repo
  surfaces is still a **global** gap worth fixing once, for every repo that
  shares that stack.
- So "I already audited the global config earlier today" is **not** a reason
  to skip it. Re-evaluate it from *this* repo's vantage.
- Resolve each quirk to the right scope: **iron it out globally** when it
  helps every repo on that stack (a new or improved rule or skill, landed via
  the dotfiles PR), or **document it locally** in the repo's `.claude/`
  when it is genuinely repo-specific. Either way the quirk becomes a decision,
  not a recurring surprise.

Treat the global config as a living thing many repos keep sharpening — the
more vantage points it is audited from, the better it fits all of them.

## Running from another repo — modify dotfiles, scoped

When invoked outside the dotfiles repo, the audit **modifies the dotfiles
repo** for global changes — but **only audit-relevant files**:
`config/claude/**` and `TODO.md`. Never touch unrelated dotfiles.

- Resolve the dotfiles repo from `$DOTFILES` (fail clearly if unset).
- Its `master` is **protected** — branch first, change only audit files, then
  land via PR (squash; watch CI; merge on explicit approval). Use the
  **ship-pr** skill + `gh.md`. Never edit on `master`.
- Local-repo changes happen in the current repo (its `.claude/`, or a
  local-scope `claude mcp add`), separately from the dotfiles PR.

## Procedure

This procedure **is** the canonical methodology (it used to live in
`SETUP-AUDIT.md`'s "How to run"; that file is now only the record's index). The
living record is in `config/claude/audit/` — `decisions-log.md` (the "why"),
`BACKLOG.md` (open follow-ups), `idea-sources.md` (mined repos) — indexed by
`SETUP-AUDIT.md`. In short:

1. **Measure first** — `/context` for the live baseline, then a **read-only
   inventory agent** (rules + sizes, MCP tool counts, plugins, hooks) so the
   audit's own reading does not consume the context it is protecting.
2. **Classify** every artifact by load tier (always-on / on-demand / isolated)
   and assess right-fit: is it the correct *kind* (rule vs skill vs hook vs
   command), in the right *place*, and — for anything generic — **free of one
   stack's specifics bleeding into it**? A generic primitive should be a thin
   stack-agnostic layer that points to path-scoped per-stack patterns (see
   *Layer the generic over the specific* in `EXTENDING.md`); flag a Python-
   flavored "generic" agent that would mislead a Go-only repo. Also check the
   **categories themselves**: has a top-level category grown **too big or too
   spread out** and need **splitting** (e.g. `qa` shedding `documentation` /
   `troubleshooting`)? Splitting is the counter-move to over-folding.
3. **Recommend** by **cost × (1 − relevance)** — trim weight, never
   guardrails. Apply the placement ladder from `EXTENDING.md` (global+lazy >
   per-repo) and the plugin/MCP rules from `rules/mcp.md` (plugins are global
   → enable only a good global fit; heavy/per-repo MCP via `mymcp` + local
   scope).
4. **Confirm** drops/moves with the user (never silent), then **apply**:
   global → a dotfiles branch (audit files only) → PR; local → in this repo as
   needed.
5. **Record** decisions in `audit/decisions-log.md` (global) and surface
   per-repo findings. Convert audit-only "evaluate later" items into
   `audit/BACKLOG.md`; route repo-specific follow-ups to that repo's `TODO.md`,
   surfaced by the repo that needs them.

## Working the backlog

The audit *assesses* and *feeds* `audit/BACKLOG.md` (above + the `retrospective`
skill); this is how it also *works it down*. Invoke explicitly — "work the
backlog", "/claude-audit work" — or offer it at the end of an assessment run
when the backlog is non-empty. It is **not** part of the default assess pass;
working an item ships real config changes, so keep it a deliberate, separate
action.

1. **Pick** — read `audit/BACKLOG.md`, present the open `- [ ]` items as a
   ranked worklist (priority × cost × leverage), and confirm which to work. One
   item (or one coherent cluster) at a time.
2. **Decide kind + scope** — for the chosen item, apply the placement ladder in
   `EXTENDING.md` (rule vs skill vs hook vs patterns vs command vs MCP; global
   vs repo-local) and the three-tier model. Verify currency (Context7) and
   grounding before authoring, per the checks below.
3. **Implement** — author/modify the artifact. Run the reference-consistency
   grep (below) for anything renamed/moved/dropped.
4. **Land** — global changes via a dotfiles PR (audit + affected files; squash;
   watch CI; merge on explicit approval) using **ship-pr**.
5. **Finalize** — once green, **remove** the item from `audit/BACKLOG.md` and
   record the outcome in `audit/decisions-log.md` (the same prune-at-merge
   discipline the repo uses for `TODO.md`).

A config task that arrived from the repo `TODO.md` (the "Repo-config follow-ups"
section) is worked the same way — it is now a backlog item like any other.

**Verify currency with live docs (Context7, if available).** Rules and skills
go stale as tools change — deprecations, renamed flags, shifted best practice.
When auditing an existing rule or adopting a new pattern, use **Context7** (the
`context7` MCP, *if it is enabled in this session*) to check the tool /
library / API's **current** documentation before trusting what's written — it
catches drift without cloning a repo (e.g. it surfaced Spotify's now-deprecated
`PUT/DELETE /me/tracks` that older third-party guides still listed as current).
Resolve the library id, then query the specific question. It is **second-class**
(`rules/mcp.md`): a convenience for the audit *process* only — never a
dependency the resulting rules/skills rely on, and the audit must work
without it. Fall back to official docs or a shallow clone when it's absent.

**Evaluate skills with `skill-creator`.** When the audit questions a skill's
quality or whether its `description` triggers on the right requests, use the
**skill-creator** skill — its evals / benchmarks and description-trigger
optimizer *measure* triggering and behaviour rather than eyeballing the
frontmatter. This is the audit's standing tool for the skills dimension; the
more it is used, the sooner we learn whether to leave skill-creator enabled,
vendor it, borrow its ideas, or drop it (`audit/decisions-log.md`). **Caveat (CC
2.1.x):** skill-creator's automated **trigger eval** (`run_eval.py`) is
currently broken — it returns 0% regardless of the description (upstream
issue #2003 plus a command-vs-`Skill` detection gap; verified, see
`audit/decisions-log.md`). Until upstream fixes it, judge triggering **manually**;
skill-creator's value here is its `SKILL.md` *writing* guidance and the
instruction-review pass, not the eval scripts.

**Check reference consistency (cross-impact).** Artifacts cross-reference each
other by greppable name — rules by filename (`git.md`), skills by name, hooks
by path, `[[links]]` in docs. When the audit recommends **changing, moving, or
deleting** an artifact, `grep config/claude/` for references to it and confirm
each referrer is still accurate: a renamed flag, moved section, dropped skill,
or bumped version silently leaves its referrers stale. **Fix or flag the
ripple — never change the target in isolation.** (Where the repo has a
structure map — e.g. a `STRUCTURE.md` of rule/skill/hook edges — it charts
this for humans; the grep is the actual check regardless.)

**Check grounding (author-from-docs).** Each rule/skill should be grounded in,
and cite, an authoritative source where one exists — official docs / man page
(a rule's **Sources** section) or an adapted-from `SOURCE.md` (a skill) — per
`EXTENDING.md` *Grounding & sourcing*. Flag any artifact that asserts a
tool/library/API's behaviour with **no source and not marked a house
convention**: its claims may be memory-based and already stale. This pairs
with the currency check above (Context7) — grounding is *whether* a source
exists; currency is *whether* it is still current.

**Delegated research can over-claim — demand exact doc quotes.** When a
spawned research agent (a `claude-code-guide` lookup, a doc-mining subagent)
reports a **feature or behaviour claim** that would drive an action — a
rename, a new `CLAUDE.md`/rule block, wiring a hook, adopting an API — do
**not** act on the summary alone. Require an **exact quote plus the doc URL**
backing that specific claim, and treat an unsourced specific as
**unconfirmed** until checked against the primary source. Plausible-but-false
specifics have slipped through twice (a skill-name charset rule not in the
spec; a `# Compact instructions` CLAUDE.md heading that doesn't exist), caught
only because they were high-stakes — make the quote-or-it-didn't-happen check
routine, not luck.

## Mining repos for ideas

An audit improves the **whole** dev environment, not just the current repo —
so the strongest finds are *generic* tools that spread everywhere. When the
audit looks to external repos for ideas:

**Finding a source.** If the *Idea sources* registry (`audit/idea-sources.md`)
has no repo covering an aspect of the current repo, go find one. Rank by:

1. **Official / first-party first** — the tool's or framework's own org (e.g.
   `pydantic/skills`, `fastapi/.agents`). Authoritative; tracks the tool's
   versions. Re-mine these on the tool's version bumps.
2. **Otherwise third-party**, ranked by a bundle, not stars alone: **stars**
   (adoption) **+ recency** (last commit) **+ maintenance health** (open-issue
   ratio, contributor count). Stars are laggy and gameable; recency catches
   the popular-but-abandoned repo. Take the top 2–3.
3. **Staleness gate:** last commit **> 1 year** → flag for re-evaluation, do
   **not** auto-discard. Some stable tools rarely change; judge on fit, not
   age alone.

**Charting it — full census, no pre-filtering.** Enumerate the **entire**
surface (every agent / command / hook / skill), not a curated shortlist — a
shortlist hides what was skipped and biases toward the current repo's stack.
Produce a disposition table (ADOPT / CANDIDATE / SKIP + one-line reason) and
record it in `config/claude/audit/mining-census.md`. Fan the enumeration out
to read-only agents so it doesn't consume the audit's own context.

**SKIP is two things.** A permanent **SKIP** (covered/redundant) won't come
back; a conditional **`SKIP-until <trigger>`** (a tool we don't use, a domain
we're not in) **flips to CANDIDATE when the trigger fires** — don't bury it as a
plain SKIP. Every `SKIP-until` goes on the census **Watch list**; check that
list whenever a new dependency/tool is adopted (and each audit run), and
re-promote what the trigger unlocks. Never *rewrite* the original SKIP — it was
right when made; the trigger is what resurfaces it.

**Judging.** Score each item by **generic value to *any* repo** first, then
overlap with existing built-ins/skills/rules, then the layering principle.
Consider an agent or command a CANDIDATE **even if we'd reimplement it as a
skill** (skills over commands — ADR-0001). Don't dismiss a good generic tool
because it arrived in a different form. **Placement:** anything about a
repo-foreign library/tool is built **global**, on first use (ADR-0003) — not
repo-local, not deferred; and **fold a new capability into an existing
top-level category** (`code-style` / `testing` / `qa` / `gh` / `git`) rather
than spawning a new one unless it genuinely doesn't fit. **`qa` is the
umbrella — work it last:** it aggregates the other categories, so build the
category-specific pieces first and touch `qa` (and `qa-check`) last, wiring
the new pieces in (`qa.md` names them, `qa-check` composes them). Record
sources in the *Idea sources* registry; a per-artifact `SOURCE.md` only on
implementation reuse (ADR-0002).

## Guardrails

- **Second-class MCP/plugins** — never make a rule/skill depend on one.
- **Protected branch** — branch before editing dotfiles; PR + approval to
  merge.
- **Staging** — `git add -u` + explicit paths; never `-A` / `.`.
- **Confirm** before dropping or moving anything; the user knows their usage.
- **Don't bloat the always-on tier** — prefer on-demand homes (skills,
  path-scoped rules); refs in always-on `qa.md` / `CLAUDE.md` cost every turn.
