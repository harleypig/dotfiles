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
   command) and in the right *place*?
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

## Guardrails

- **Second-class MCP/plugins** — never make a rule/skill depend on one.
- **Protected branch** — branch before editing dotfiles; PR + approval to
  merge.
- **Staging** — `git add -u` + explicit paths; never `-A` / `.`.
- **Confirm** before dropping or moving anything; the user knows their usage.
- **Don't bloat the always-on tier** — prefer on-demand homes (skills,
  path-scoped rules); refs in always-on `qa.md` / `CLAUDE.md` cost every turn.
