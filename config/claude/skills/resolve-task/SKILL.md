---
name: resolve-task
description: Resolve one work item — or a user-requested group — end-to-end from any source: a GitHub issue, this repo's TODO/BACKLOG, or another repo's TODO. Orchestrates existing skills — read the item, reconcile it against current code (skip if already done; route WONTFIX/ICEBOX/LATER), classify the task-type, branch it, investigate (debug-assistant for bugs, a design agent for features, straight to the fix when trivial), apply the change plus the right tests, and land via push-pr (`Closes #N` for issues; mark `[x]`+prune for TODOs). The execution counterpart to github-issues, which triages but never tackles. PR-open is consent by invoking push-pr; merge stays gated unless the repo opts into auto-merge; an opt-in `resolve-task: autonomous` sentinel (default-off, trivial-only, after CI green) can skip the ask gate. Use for "resolve issue #N", "work this task", "do this todo", "work the <section> tasks", "take issue #N". Delegates to github-issues, git-worktree-workflow, debug-assistant, qa-check, push-pr.
---

# Resolve Task

**Version:** v1.0.0

Take a **work item** — from a GitHub issue, this repo's `TODO.md` /
`BACKLOG.md`, or another repo's `TODO.md` — from *selected* to *landed*, by
orchestrating the skills that already own each step. resolve-task owns only
the glue, the analysis, and the gate decisions; it **delegates every heavy
step**
and reimplements none (Rule of Three, `code-style.md`).

Flow:

> select item(s) → read → **reconcile & analyze** (already-done? disposition?
> task-type? decompose / compose / batch) → name + branch the task
> (**git-worktree-workflow**) → investigate by type (**debug-assistant** for a
> bug, a design agent for a feature, skip for trivial) → apply the change +
> the right tests → land via **push-pr** (`Closes #N` or mark `[x]`) → merge
> (gated) → clean up.

This is the **execution counterpart to `github-issues`**, which triages and
**never tackles** ("acting on a mapped issue is a separate, explicit step"):
resolve-task *is* that step, generalized to any work item.

## Sources & granularity

- **A GitHub issue** (`#N`, any repo you can reach).
- **The current repo's `TODO.md` / `BACKLOG.md`** (a bullet).
- **Another repo's `TODO.md`** — a sibling clone at `$PARENT_DIR/<repo>`
  (`git.md` related-repos). Cross-repo tasks operate in the **target** repo:
  the branch, worktree, and PR happen there, not the invoking repo.

Invoke on **one task or a user-requested group** (e.g. a whole TODO section).
A group is an explicit batch — work each — but see *Scope* for when small ones
share one PR. Items arrive **raw**: naming and analysis happen here, at
selection, not when the item was captured.

## Prerequisites

- `git`, and `gh` authenticated (`gh auth status`).
- A specific work item (or group) to resolve, and its **target repo**.
- Start on a non-default branch of the target repo (Step 3); never author on a
  protected default branch (`git.md`).

## Credentials

`gh` uses the dual-credential model in `rules/gh.md` — the env-var PAT by
default, falling back to `GH_TOKEN= GITHUB_TOKEN= gh …` only on a scope error.
**push-pr** already handles that fallback for its gh calls.

## Guardrails (do not violate)

The gate boundary is inherited from `rules/gh.md` and **push-pr**, not invented
here:

- **Investigation is read-only.** The debug-assistant / design agent traces
  and proposes; it does not push, open a PR, or merge.
- **PR-open is consent by invocation.** Invoking **push-pr** (which
  resolve-task does at the landing step) is consent to run through *opening
  the PR* and watching CI.
- **Merge is gated.** It needs a separate explicit instruction for the branch
  ("merge it"), **unless** the target repo has `auto-merge: enabled` on its
  **default branch** — then push-pr merges on green CI.
- **Never** push to or merge a default branch directly; **never** force-push
  without `--force-with-lease --force-if-includes`; **never** `--no-verify` or
  bypass required checks; **never** create a worktree unless asked.
- **One task → one PR** by default. A **group of small/simple tasks** may
  share one PR (*Scope › Batch*); a **user-requested group** works several
  tasks by explicit request — but resolve-task never *autonomously* expands
  scope (decomposition captures extras as TODOs; it doesn't grind a queue).

## Step 0 — Select the work item(s)

Take a chosen issue #N, TODO/BACKLOG bullet, or cross-repo TODO bullet — one
task or a user-requested group. Record each item's **target repo**. For a
group, iterate Steps 1–6 per task; do not expand beyond what was asked.

## Step 1 — Read it

`gh issue view <N> --json number,title,body,state,url` for an issue; for a
TODO, read the bullet and note its **source** (repo, file, location) — that is
the provenance the branch name won't carry.

## Step 2 — Reconcile & analyze (at selection)

The naming/analysis the capture step deliberately skipped. Do this **before**
any real effort:

- **Disposition first (cheap).** Reconcile the task against the target repo's
  **current code / state** — the discipline `github-issues` uses for stale
  issues — and assign a disposition:
  - **already-done** → don't re-do it: close with evidence (issue → close +
    comment on what satisfied it; TODO → mark `[x]` / prune) and stop / next;
  - **do-now** → continue;
  - **WONTFIX / ICEBOX / LATER / flag-for-decision** → route it there with a
    reason (a decisions-log / ICEBOX note, or ask), and stop / next.
- **Classify the task-type** (drives Step 4): **trivial** · **bug** ·
  **feature/change**. The set is **open** — if a task fits none, name a **new
  type**, handle it sensibly, and capture a `TODO` to add it to this
  classifier. Don't force a star into a square hole.
- **Scope — decompose, compose, or batch:**
  - **Decompose** (one → many): capture the extra tasks as TODO items (routed
    per `rules/todo.md`) and resolve **one** (ask which if ambiguous). The item
    isn't done until its last task lands.
  - **Compose** (many → one) — **opportunistic only, never a hunt.** Don't
    scan sources for merges (expensive, usually wasteful); but if you
    **notice** two selected tasks are the same/combinable, merge them into one
    task/PR and reconcile both source items.
  - **Batch** — a group of **small/simple** tasks (e.g. a TODO section of
    trivial items) may share **one PR** rather than pay a full CI run per tiny
    change. Keep it theme-grouped and reviewable; QA still gates it.

## Step 3 — Name & branch the task (in the target repo)

The branch name is the task's **stable handle** (immune to TODO-file churn).
Use **git-worktree-workflow**:

- **Issue** → Operation 1 (`issue/<N>`).
- **TODO / decomposed task** → a `feature|bugfix|docs/<slug>` branch per
  `git.md` (git-worktree-workflow's non-issue task path — same worktree/plain
  setup, no `gh issue view`).

Cross-repo: operate in the sibling clone at `$PARENT_DIR/<repo>`.

## Step 4 — Investigate, routed by task-type (read-only agent)

- **trivial** → skip investigation; go straight to the change.
- **bug / failure** → **debug-assistant** (fanned to a read-only agent):
  reproduce → root cause → the regression test it should pin.
- **feature / change** → a read-only **design/plan agent** → the approach and
  the new tests it needs (debug-assistant's boundaries exclude generative
  work — don't misuse it there).

If the investigation hits a dead end or ambiguity, **or the work reveals** the
task should be **WONTFIX / ICEBOX / LATER**, route it to that disposition
(with a reason) and **stop** — the Step-2 call can also be reached here,
mid-work. Don't force a task to completion.

## Step 5 — Apply the change + the right tests

Keep the change scoped to the task; grep for sibling occurrences of a fixed
cause. Match the test bar to the type (`testing.md`):

- **bug** → the regression test that fails-before / passes-after;
- **feature/change** → new success **and** failure coverage;
- **pure docs** → none.

## Step 6 — Land via push-pr

Invoke **push-pr** for the whole tail: `qa-check` → commit → push → **open the
PR** → watch CI → (gated) merge → tag → cleanup. Close the item by source:

- **issue** → **`Closes #N`** in the PR body (auto-closes on merge, push-pr
  Step 4.5 — no manual close);
- **TODO** → mark the item **`[x]`** in the fix commit; merge-finalization
  prunes it.

Record **provenance** in the PR body (the issue URL, or the TODO's repo, file,
and text). A **decomposed** item stays open with a "Part of …" reference until
its final task lands; a **batched** PR closes every item it covers.

## Autonomous variant (opt-in, default-off)

A repo may authorize resolve-task to **skip its Step-2 present-and-ask gate**
by declaring the sentinel **`resolve-task: autonomous`** in its
`.claude/WORKFLOW.md` / `.claude/CONVENTIONS.md`, read **from the target repo's
default branch** — never the working tree (a PR that *adds* the sentinel must
not autonomize itself):

```bash
DEF=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
git show "origin/$DEF:.claude/WORKFLOW.md" "origin/$DEF:.claude/CONVENTIONS.md" \
  2>/dev/null | grep -q 'resolve-task: autonomous'
```

When set, auto-proceed **only if every guardrail holds**: the disposition is
**do-now**; the task-type is **trivial or small**; a bug was **reproduced**
(or a feature's approach is clear) with no dead end / clarifying question; the
change passes **`qa-check`**; CI is green (push-pr `ci-watch` exit **0** —
never on 1; stop on 2 / warnings). **Merge autonomy is still push-pr's**
`auto-merge: enabled` (also read from the target repo) — a repo needs **both**
sentinels for a zero-touch resolve. Every push-pr guardrail (ruleset-obeying
`push.sh merge`, required checks, the `merge-finalization.py` hook) still
applies. Any failure, non-trivial verdict, or ambiguity → **fall back to
gated**: stop and ask. Still **one task → one PR** — no queue-draining loop.

## What it delegates to

| Step | Routed to | Source of truth |
|------|-----------|-----------------|
| Triage / choose the work | **github-issues** (issues) · the repo's TODO/BACKLOG | `gh.md`, `todo.md` |
| Branch the task (worktree or plain) | **git-worktree-workflow** | `git.md` |
| Investigate a bug | **debug-assistant** (read-only agent) | `troubleshooting.md` |
| Verify the change | **qa-check** | `qa.md` |
| Commit → PR → CI → merge → tag → cleanup | **push-pr** | `gh.md`, `git.md` |

## Notes

- resolve-task is **thin** — if you find yourself reimplementing a delegate's
  logic (branch mechanics, the QA pipeline, the merge), stop and call the
  skill instead.
- For a **fork**, the PR targets upstream (`gh repo view --json parent`); the
  delegates already handle fork mode.
- Invoke `push.sh` by its path in the **push-pr** skill's `scripts/` directory.
