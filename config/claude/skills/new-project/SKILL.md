---
name: new-project
description: Initialize a new repository, or convert an existing one to these dotfiles' conventions (the "claude setup"). Greenfield mode scaffolds git + default branch, a pinned pre-commit baseline, README/TODO/DEVELOPER docs, a test harness, CI, and branch protection, delegating language bootstrapping to the per-language rule. Brownfield mode inventories an existing repo, gap-analyzes it against the conventions, and wires the missing layers without clobbering what's there — including the CLAUDE.md/.claude/ decision and promoting repo-local rules to global. Use when setting up or onboarding a repo: "set up a new project", "scaffold a repo", "start a new project", "convert this repo to my claude setup", "onboard this repo", "bring this repo up to my conventions", "add the claude config here", "adopt the dotfiles setup".
---

# new-project

**Version:** v1.0.0

The procedure for **standing up a new repository** or **converting an existing
one** to these conventions. `rules/new-project.md` is the standing **policy**
— read it first and apply it throughout; this skill is the **steps**. It
orchestrates the existing rules and setup skills rather than restating them:

- Git init / default branch / branch protection / sibling repos → `git.md`.
- PR flow → `gh.md`, the `ship-pr` skill.
- Pre-commit baseline (phased) → `pre-commit.md`.
- Test harness → `testing.md` + the language's setup skill (`bats-setup`,
  `pytest-patterns`, …).
- Language bootstrapping (Poetry, npm, cargo, MDK) → the **per-language rule**
  (`poetry.md`, …) — this skill **delegates**, never inlines it.

Grounding: house convention (no external source) — see the rule's *Sources*.

## Pick the mode

- **Greenfield** — an empty or brand-new repo with nothing set up yet.
- **Brownfield** — an existing repo that works but doesn't yet follow these
  conventions / lacks the claude setup. **Inventory first, never clobber.**

## Mode A — Greenfield (new repo)

Run in order; skip a step only with a stated reason.

1. **Git.** `git init`, set the default branch to the user's convention
   (`git.md` *Default Branch* — don't hardcode `main`/`master`), make the
   first commit. Decide early whether the default branch will be PR-only
   (step 7).

2. **Language bootstrap.** Identify the stack and run **its** rule's
   scaffold steps (e.g. `poetry.md` for a Python package). If that language
   has no rule, surface the gap (`CLAUDE.md` *Missing or Conflicting Tool
   Rules*) before improvising.

3. **Pre-commit baseline.** Add `.pre-commit-config.yaml` (check) and
   `.pre-commit-config-fix.yaml` (fix) per `pre-commit.md`'s phased strategy,
   **version-pinned to current stable**. Include `no-commit-to-branch` for the
   protected branch (step 7). `pre-commit install`.

4. **Docs scaffold** (`WORKFLOW.md` *Documentation Philosophy* — inline-first,
   minimal):
   - `README.md` — minimal: setup + navigation only.
   - `TODO.md` — the task/triage queue.
   - `DEVELOPER.md` — the full build/test workflow incl. platform quirks
     (e.g. build in WSL2, test in Windows); may *note* the maintainer's editor
     but not prescribe editor setup (per the rule).

5. **Test harness.** Stand it up via the language's setup skill (`bats-setup`
   for shell, the pytest pattern for Python, …); a starter test proving the
   wiring, covering a success and a failure path (`testing.md`).

6. **CI.** A minimal workflow that runs pre-commit and gates the test suite.
   Required checks come later once the suite is green.

7. **Branch protection** *(if the default branch is PR-only)*. Apply the three
   layers from `git.md` *Protecting the Default Branch* — server-side ruleset
   (authoritative), the `no-commit-to-branch` hook (step 3), and the
   edit-time `branch-protection.py` guard (automatic where the hook is
   configured).

8. **`.claude/` scaffold — defer.** Do **not** create it reflexively. Add
   `CLAUDE.md` / `.claude/` only once the repo has repo-specific conventions
   the global config doesn't already cover (per the rule). Until then the
   global config carries it.

9. **Capture gaps.** Log any global-config gaps setup exposed as `- [ ]`
   follow-ups (repo `TODO.md`, or the dotfiles audit backlog for agent-config
   gaps) — don't block setup on them.

## Mode B — Brownfield (convert an existing repo)

The goal is to bring an existing repo up to these conventions / onto the
claude setup **incrementally and non-destructively**.

1. **Inventory what exists.** Check each layer before touching it: default
   branch + protection, `.pre-commit-config*.yaml`, test layout + runner, CI
   workflows, `README` / `DEVELOPER.md` / `TODO.md`, and any `CLAUDE.md` /
   `.claude/`. Read what's there; a working setup that differs from ours is a
   reconcile, not a rip-and-replace.

2. **Gap-analyze** against Mode A's layers. List what's missing, what's stale,
   and what already conforms. Surface conflicts (e.g. a different test layout)
   rather than silently overwriting.

3. **Wire the missing layers**, each via its own rule/skill (steps 3–7
   above), smallest-first. Match the repo's existing idioms where they're
   sound; only change what genuinely diverges from the conventions.

4. **The `.claude/` decision.** If the repo has no agent config, rely on the
   global config and add a local `.claude/` only for genuinely repo-specific
   content (same defer rule as Mode A, step 8). If it *has* one, reconcile it
   with the global set.

5. **Promote, don't duplicate.** If the repo carries repo-local rules/skills
   that are actually language- or repo-agnostic (tier 1/2 of `CLAUDE.md`
   *Configuration Migration*), flag them for promotion to the global config
   instead of leaving a divergent copy — this is the inbound half of the
   "Audit Project .claude/ Dirs for Promotable Rules/Skills" backlog item.

6. **Land via PR.** All changes go through the repo's normal workflow — branch
   first, PR, approval (`ship-pr`); never edit a protected branch directly
   (`git.md`).

## What this skill does not do

- It does **not** carry language-specific scaffold commands — those live in
  the per-language rules it delegates to.
- It does **not** force a `.claude/` scaffold — deferral is the default.
- It does **not** merge or push to a protected branch — landing is the repo's
  PR workflow.
