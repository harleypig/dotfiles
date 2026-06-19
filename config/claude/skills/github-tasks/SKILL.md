---
name: github-tasks
description: Sweep a repo's GitHub state and drive the routine maintenance — open Dependabot PRs, untriaged issues, failing required checks, stale branches, unresolved review threads, release/tag hygiene — then present a ranked worklist and ask before acting on anything ambiguous. The forcing function for rules/gh.md's "start of git/gh work, and daily" cadence. Use for "github tasks", "sweep github", "what needs doing on this repo", "any dependabot PRs / open issues", "triage this repo", "github housekeeping", "check the repo's github state", or at the start of git/gh work in any repo you control. Gathers and triages itself; delegates the heavy lifting to security-scan, ship-pr, git-worktree-workflow, and release-tag.
---

# github-tasks

**Version:** v1.0.0

The recurring **GitHub housekeeping sweep** for a repo you control: gather
the repo's open GitHub state, triage it, and present a single ranked worklist
— then act only on what the user picks. It is the **forcing function** for
the cadence `rules/gh.md` already defines ("at the start of git/gh work, and
at least daily"): that rule says *when* and *what* to check; this skill is the
*how*, run as one pass instead of a scatter of half-remembered `gh` calls.

This skill **gathers and triages**; it **delegates the heavy lifting**. It
does not re-implement what a focused skill already does — landing a PR,
managing branches, scanning dependencies, cutting a tag. Keeping it a
sweep-and-route orchestrator is what stops it from duplicating those skills
(Rule of Three, `code-style.md`).

It is **repo-agnostic**: it learns each repo's specifics (default branch,
required checks, merge method, label set, TODO triage queue) from the repo
itself, not from any hard-coded assumption. Run it in any repo you own.

## Not scheduled — triggered

This runs **regularly but not on a cron**. The natural trigger is the one in
`rules/gh.md`: the **start of git/gh work in a repo, and at least once a
day**. Reach for it then, or on an explicit ask ("sweep github", "anything
open on this repo?"). Do not wire it to a scheduled job — the point is to
surface state *when you sit down to work the repo*, not on a timer that fires
into the void.

## Credentials

Every `gh` call follows the `rules/gh.md` credential model: run plain
(env-var PAT) first; on a scope/permission error (`Resource not accessible by
personal access token`, HTTP 403) retry that **single** command with
`GH_TOKEN= GITHUB_TOKEN= gh …` to fall through to the stored OAuth
credential. Never `unset` the tokens in the session.

## Step 1 — Gather (read-only)

Collect the repo's open state in one pass. These are reads; nothing here
changes anything.

```bash
gh pr list  --state open --json number,title,author,isDraft,labels,statusCheckRollup
gh issue list --state open --json number,title,labels,createdAt
gh run list --branch "$(default-branch)" --limit 5 --json conclusion,status,workflowName
git branch -a --format='%(refname:short) %(upstream:track)'   # stale / gone branches
```

Derive the default branch per `rules/git.md` (never hard-code `main`/
`master`). Separate **Dependabot** PRs (author `app/dependabot`) from human
PRs — they route differently below. Note any PR whose `statusCheckRollup` is
failing, and any open issue with **no** triage label.

## Step 2 — Triage each category

Sort the gathered state into a worklist. For each category, decide and route
— do **not** start executing yet (Step 3 presents first).

- **Dependabot PRs** — group by bump size. Green grouped **minor/patch** are
  usually safe to land; **major** bumps get individual review. The triage
  judgment and the compat gate are the **security-scan** skill's job (which
  reads `rules/dependabot.md`); landing is **ship-pr**'s. Never
  blanket-auto-merge majors. Ties into the repo's Dependabot/auto-merge
  policy if it has one.
- **Open issues** — apply the right label (`bug`, `docs`, `feature`,
  `question`, …) to anything untriaged, then fold actionable issues into the
  repo's **TODO triage queue** (a section in its `TODO.md` or equivalent),
  each with a priority — exactly as `rules/gh.md` *Issues & triage*
  prescribes. Auto-filed scanner issues (e.g. a nightly DAST/CVE findings
  issue) go through **security-scan**.
- **Failing required checks** on an open PR — surface the failing job; a fix
  is a normal debugging task (`debug-assistant`), not something this sweep
  does inline.
- **Stale / gone branches** — branches whose upstream is `[gone]` or long-
  merged are **git-worktree-workflow** cleanup candidates; list them, don't
  delete here.
- **Release / tag hygiene** — an unreleased merge that ships an artifact is a
  **release-tag** candidate; flag it.
- **Unresolved review threads** — surface PRs blocked on open threads.

## Step 3 — Present a ranked worklist, then ask

Output **one** prioritized list — the whole point of the sweep is a single
place to see what the repo needs. Rank by urgency: failing checks on a PR
about to merge and security-relevant Dependabot bumps first; cosmetic issue
labels last. For each item give the one-line what, the suggested route (which
skill), and your read on priority.

Then **stop and ask** before acting on anything ambiguous (`AskUserQuestion`
is good here). Invoking this skill is consent to **gather, triage, and label**
— it is **not** consent to merge a PR, delete a branch, or cut a tag. Those
each need the explicit go-ahead their own skill requires (`rules/gh.md`:
never merge/close PRs without approval). Let the user pick what to work; then
hand each chosen item to its skill below.

## What it delegates to

| Item | Routed to | Source of truth |
|------|-----------|-----------------|
| Dependabot triage / compat gate | **security-scan**, **qa-check** | `rules/dependabot.md`, `rules/qa.md` |
| Landing a PR (commit→PR→CI→merge) | **ship-pr** | `rules/gh.md`, `rules/github-actions.md` |
| Branch cleanup / worktrees | **git-worktree-workflow** | `rules/git.md` |
| Cutting a release tag | **release-tag** | `rules/git.md` *Versioning & tags* |
| Fixing a failing check | **debug-assistant** | `rules/troubleshooting.md` |
| Issue-triage cadence + labels | *(this skill)* | `rules/gh.md` *Issues & triage* |

## Guardrails

- **Gather/triage/label is the default scope.** Merging, closing, deleting,
  pushing, and tagging are **not** — each needs the explicit approval its own
  skill requires. When in doubt, present and ask.
- **Never** blanket-auto-merge Dependabot majors or silence an advisory
  without justification (`security-scan`).
- **Never** hard-code the default branch, required checks, merge method, or
  label set — read them from the repo.
- Do **not** schedule this on a cron; it is triggered by sitting down to work
  the repo (above).
- Don't let auto-filed issues pile up unseen — surface them every sweep
  (`rules/gh.md`).
