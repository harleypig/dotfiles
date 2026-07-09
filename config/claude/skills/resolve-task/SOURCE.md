# Source / provenance

**Authored from house conventions — no upstream code reused.** Per ADR-0002
there is no tracked per-artifact source; the skill is our own orchestration of
existing skills and rules.

## Idea source (NOT tracked)

House-planned, not mined: began as the long-standing `resolve-issue` backlog
item (the execution counterpart to `github-issues` triage), then generalized
to a **work-item resolver** (`resolve-task`) during its design review —
because this repo's work is TODO-driven, so an issue-only skill can't be
dogfooded here.

## Local design decisions

- **Thin orchestrator, delegates every heavy step** — github-issues (choose),
  git-worktree-workflow (branch), debug-assistant / a design agent
  (investigate), qa-check (verify), push-pr (land). It owns only the glue, the
  analysis, and the gate decisions; it reimplements nothing (Rule of Three).
- **Work item, not just an issue.** Sources are a closed set — GitHub issues,
  the current repo's `TODO.md` / `BACKLOG.md`, and another repo's `TODO.md`
  (cross-repo, operating in the target repo). The Rule of Three does **not**
  gate this: it's one concept over a known 2-source union, not speculative
  duplication of our own code.
- **Naming + analysis at *selection*, not capture.** Items are recorded raw;
  the branch name (created at selection) is the task's **stable handle**,
  immune to TODO-file churn. Provenance (the source) is recorded in the PR
  body, since the branch names the task, not where it came from.
- **Task-type-routed investigation** (trivial / bug / feature/change, an
  **open** set) — `debug-assistant` only on the *bug* branch (its reproduce-
  first method fits a failure, not generative work); a design agent for
  features; skip for trivial. This corrected an early flaw where the skill
  hard-wired debug-assistant for *every* item.
- **An item may decompose into many tasks; tasks may (opportunistically)
  compose into one.** The atomic unit is a **task** (one branch/PR).
  Composition is *notice, don't hunt* — scanning all sources for merges is
  wasteful. Small tasks may **batch** into one PR to avoid a full CI run per
  tiny change.
- **Disposition-first reconciliation** (mirroring `github-issues`):
  already-done / do-now / WONTFIX / ICEBOX / LATER / flag-for-decision —
  reachable at analysis **and** mid-work; don't force a task to completion.
- **Two gate points, inherited not invented** (`gh.md`, push-pr): PR-open is
  consent by invoking push-pr; **merge stays gated** unless `auto-merge:
  enabled` on the target repo's default branch.
- **Autonomous variant (v1.0.0, default-off)** — a per-repo `resolve-task:
  autonomous` sentinel, read **from the target repo's default branch** (never
  self-granting), skips only this skill's present-and-ask gate, for
  trivial/small do-now tasks after CI green. Merge autonomy remains push-pr's;
  every guardrail still applies; one task → one PR (no grind loop).
- **Boundaries drawn** — not triage (`github-issues`), not the sweep
  (`github-tasks`), not whole-codebase health (`arch-review`) or performance
  (`perf-review`).
