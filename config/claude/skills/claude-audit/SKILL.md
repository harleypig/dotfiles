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

Follow `$DOTFILES/config/claude/SETUP-AUDIT.md` ("How to run" + the Decisions
log) — the canonical methodology and living record. In short:

1. **Measure first** — `/context` for the live baseline, then a **read-only
   inventory agent** (rules + sizes, MCP tool counts, plugins, hooks) so the
   audit's own reading does not consume the context it is protecting.
2. **Classify** every artifact by load tier (always-on / on-demand / isolated)
   and assess right-fit: is it the correct *kind* (rule vs skill vs hook vs
   command), in the right *place*, and — for anything generic — **free of one
   stack's specifics bleeding into it**? A generic primitive should be a thin
   stack-agnostic layer that points to path-scoped per-stack patterns (see
   *Layer the generic over the specific* in `EXTENDING.md`); flag a Python-
   flavored "generic" agent that would mislead a Go-only repo.
3. **Recommend** by **cost × (1 − relevance)** — trim weight, never
   guardrails. Apply the placement ladder from `EXTENDING.md` (global+lazy >
   per-repo) and the plugin/MCP rules from `rules/mcp.md` (plugins are global
   → enable only a good global fit; heavy/per-repo MCP via `mymcp` + local
   scope).
4. **Confirm** drops/moves with the user (never silent), then **apply**:
   global → a dotfiles branch (audit files only) → PR; local → in this repo as
   needed.
5. **Record** decisions in `SETUP-AUDIT.md` (global) and surface per-repo
   findings. Convert "evaluate later" items into `TODO.md` follow-ups,
   surfaced by the repo that needs them.

## Mining repos for ideas

An audit improves the **whole** dev environment, not just the current repo —
so the strongest finds are *generic* tools that spread everywhere. When the
audit looks to external repos for ideas:

**Finding a source.** If the *Idea sources* registry (`SETUP-AUDIT.md`) has no
repo covering an aspect of the current repo, go find one. Rank by:

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
than spawning a new one unless it genuinely doesn't fit. Record sources in the
*Idea sources* registry; a per-artifact `SOURCE.md` only on implementation
reuse (ADR-0002).

## Guardrails

- **Second-class MCP/plugins** — never make a rule/skill depend on one.
- **Protected branch** — branch before editing dotfiles; PR + approval to
  merge.
- **Staging** — `git add -u` + explicit paths; never `-A` / `.`.
- **Confirm** before dropping or moving anything; the user knows their usage.
- **Don't bloat the always-on tier** — prefer on-demand homes (skills,
  path-scoped rules); refs in always-on `qa.md` / `CLAUDE.md` cost every turn.
