---
name: github-issues
description: Deep triage of a repo's open GitHub issues — reconcile each against the repo's existing planning docs (TODO/ROADMAP/ICEBOX) AND its current code, detect already-done/stale issues and recommend closing them with an explanatory comment, score each issue's complexity, spot duplicate/umbrella issues and blocking chains, recommend labels (creating missing ones), and keep issue ↔ planning-doc references in sync. Routes every issue to a disposition (close-done / map-to-TODO / icebox+close / roadmap / features-&-fixes / flag-for-decision) and presents a worklist — it NEVER auto-fixes an issue. Use for "triage the issues", "go through the issues", "map issues to todos", "which issues are already done", "what's still open". The depth skill github-tasks delegates issue triage to.
---

# github-issues

**Version:** v1.0.0

Deep, per-issue triage for a repo you control: take the open issues and turn
them into an accurate, de-duplicated worklist that is **reconciled with what
the repo already plans and already has**. This is the *how* behind `gh.md`
*Issues & triage* and the issue step of the **github-tasks** sweep; that rule
says *when* to triage (start of git/gh work, daily) and the broad sweep routes
to it — this skill is the procedure.

It is **repo-agnostic**: it learns the repo's planning docs, label set, and
code layout from the repo itself.

## Scope — triage, never tackle

Invoking this is consent to **gather, reconcile, label, comment, and (on
approval) close** issues. It is **not** consent to *implement* one. Even a
trivial issue is **presented, not fixed** — there is no auto-tackle. Acting on
a mapped issue is a separate, explicit step routed to the right skill
(`debug-assistant`, `qa-check`, the language skills, …).

## Read first

1. **`gh.md`** — *Issues & triage* (the policy) and the **credential model**:
   run `gh` plain (env PAT); on a scope/permission error retry that one command
   with `GH_TOKEN= GITHUB_TOKEN= gh …`. Never `unset` the tokens.
2. **The repo's planning docs** — `TODO.md`, `docs/ROADMAP.md`, `ICEBOX.md` (or
   the repo's equivalents; `todo.md` defines their structure), and the repo's
   `.claude/` TODO-routing. These are what issues are reconciled against.

## Procedure

### 1. Gather (read-only)

```bash
gh issue list --state open --limit 200 --json number,title,labels,body
gh label list --json name,description
```

### 2. Reconcile each issue against reality (the core step)

For every issue, before routing it, check it **both** ways — this is what the
naive "fold every issue into the TODO" approach skips, and it prevents
duplicating work or tracking what's already done:

- **Against the planning docs** — does it already correspond to a TODO /
  ROADMAP / ICEBOX item? Cross-reference it; do **not** create a duplicate
  entry. It is fine to **bunch several issues onto one task** (e.g. five
  per-module validation issues → one "add validations" item).
- **Against the current code** — is it already satisfied? (the module exists,
  the `validation`/test is present, the feature shipped). If so it is
  **stale/done** (step 3), not open work.

### 3. Detect stale / done → recommend closing with a comment

Any issue satisfied by the current code or already-shipped work is a
**close** candidate. Recommend closing it **with a comment** that says *why*
(what satisfied it — the module/PR/commit), so the close is auditable and not
silent. (Closing itself needs approval — `gh.md`.)

### 4. Score complexity

Give every still-open issue a complexity estimate with its basis:

| Rating | Rough shape |
|--------|-------------|
| **trivial** | a one-line / single-field change |
| **small** | one self-contained unit (one validation block, one rule) |
| **medium** | a module/file's worth of work, or needs a design choice |
| **large** | new subsystem / harness / cross-cutting (e.g. an integration-test rig) |

Report it for **every** open issue — it informs prioritization (it does
**not** trigger auto-tackle; see *Scope*).

### 5. Detect duplicates & umbrellas

Cluster near-identical issues (e.g. several "research tool X" issues) and flag
**umbrella/checklist** issues whose items overlap many other issues and/or the
TODO — recommend closing/superseding the umbrella in favour of the granular
items + the planning doc, rather than tracking the same work twice.

### 6. Record blocking

Parse `Blocked by #N` / `Depends on #N` from bodies, and infer the obvious
order where it exists (e.g. a module's validation precedes its unit tests).
Record the chain, **recommend a `blocked`/`blocked-by` label or note**, and
order the worklist so blockers come first.

### 7. Recommend labels (create missing ones)

Apply the correct **existing** label to anything untriaged. When the *right*
label **does not exist** in the repo's set, **recommend creating it** (name +
purpose) rather than forcing a poor fit or inventing one silently — surface
the label-taxonomy gap (e.g. no `security` / `research` / `<subsystem>` label).

### 8. Route to a disposition

| Disposition | When | Action (on approval) |
|-------------|------|----------------------|
| **Close — done** | satisfied by current code / shipped work | close **with a comment** citing what satisfied it |
| **Map — TODO** | actionable, ongoing maintenance/feature work | cross-reference an existing (or new) TODO item; bunching issues onto one task is fine |
| **Icebox + close** | deferred / redundant (a tool we won't use, a duplicate) | add to `ICEBOX.md`, **close** the issue as iceboxed (comment links the icebox entry) |
| **Map — ROADMAP** | planned / "in the pipeline" but **no committed date** | add to / point at a ROADMAP track; record the issue's stated intent, **invent no date** |
| **Map — Features & fixes** | a bug or discrete enhancement | the work-type section of `TODO.md` |
| **Flag — decide** | genuinely judgment-dependent | **recommend** a home; let the user choose (don't route it yourself) |

### 9. Bidirectional sync

Keep the issue and its planning entry pointing at each other: when an issue
maps to a TODO/ROADMAP/ICEBOX item, add the **issue number** to that item, and
(on close/map) leave the **issue** a comment linking the entry (or the PR that
resolves it). A reader of either side should find the other.

### 10. Present, then ask

Output **one** worklist — per issue: disposition, complexity, blockers, and
the matched planning item. Then **stop and ask** (`AskUserQuestion` is good)
before closing, commenting, icebox/TODO edits, or label creation. Triage is
the deliverable; acting on it is the user's call.

## Relationship to the rest

- **`github-tasks`** — the broad repo sweep (PRs, branches, checks, releases,
  issues); it **delegates** its Open-issues category to this skill.
- **`gh.md`** *Issues & triage* — the standing policy and cadence; this skill
  is its procedure.
- **`todo.md`** — the structure of the planning docs issues are reconciled
  into; **`code-style.md`** — the `ICEBOX:` marker convention.

## Sources

House skill — no external code. Grounded in `gh.md` (*Issues & triage*,
credentials), `todo.md` (planning-doc structure), `code-style.md` (ICEBOX),
and `EXTENDING.md` (the gather-and-delegate architecture it shares with
`github-tasks`).
