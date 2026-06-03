---
name: ship-pr
description: Commit a finished feature branch, push it, open a pull request, watch CI to green, and (with explicit approval) merge it and clean up — using this user's gh credential fallback and the repo's branch-protection merge policy. Use whenever the user wants to land work via a PR: "ship this", "ship it", "land this branch", "commit push and PR", "open a PR and merge", "put up a PR", "get this merged", "create the PR and merge after CI", or any request to take a ready branch through the PR-and-merge sequence. Starts where git-worktree-workflow's "prep for PR" ends; works for plain feature branches too (no worktree required).
---

# Ship PR

**Version:** v1.4.0

Take a finished branch through the standard landing sequence: **QA check** →
commit → push → open PR → watch CI → (approval) merge → clean up.

The deterministic mechanics live in the bundled **`scripts/ship.sh`** (in
this skill's directory). The model owns the judgment: commit messages, PR
copy, CI-failure diagnosis, and the merge decision. This skill orchestrates
the existing rules rather than restating them:

- Local QA pipeline: the **qa-check** skill (`rules/qa.md`).
- Credential fallback and PR conventions: `rules/gh.md`.
- CI monitoring: `rules/github-actions.md`.
- Default-branch derivation, force-push, post-merge prune: `rules/git.md`.
- Pre-commit fix→check ordering: `rules/pre-commit.md`.

## Prerequisites

- `git`, and `gh` authenticated (`gh auth status`).
- Work is functionally complete; **Step 1 runs qa-check** to verify it
  locally before anything is pushed.
- You are on a feature branch, not the default branch.

## Helper script

`scripts/ship.sh` wraps the judgment-free steps. Every gh call inside it
auto-retries with the env tokens cleared on a PAT scope error, so the
`rules/gh.md` fallback is handled for you.

| Subcommand | Does |
|------------|------|
| `default-branch` | Print the repo's default branch. |
| `pr-create --title T --body B [--base BR]` | Open the PR from the current branch; prints the URL. |
| `ci-watch [BRANCH]` | Poll the latest run to completion; print job results **and any warning/error annotations**. Exit `0` clean, `1` failed, `2` passed-with-warnings. |
| `merge-methods` | Print the merge methods the repo/ruleset allows. |
| `merge NUMBER --squash\|--merge\|--rebase` | Merge and delete the branch. |
| `cleanup BRANCH` | Switch to default, pull, prune the merged branch. |

## Guardrails (do not violate)

- **Never** open or merge a PR without the user's go-ahead. Invoking this
  skill is consent to commit/push/open the PR; **merging requires an
  explicit "merge" instruction** for this branch. If the user only said
  "open a PR", stop after CI and ask.
- **Never** push to or merge directly into the default branch.
- **Never** force-push without `--force-with-lease --force-if-includes`,
  and warn first.
- **Never** `--no-verify` or bypass required checks.
- Keep the `Co-Authored-By: Claude ...` footer on AI-authored commits.

## Step 0 — Preconditions

```bash
DEF=$(ship.sh default-branch)
CUR=$(git branch --show-current)
```

If `CUR` equals `DEF`, stop: create a `feature/<name>` branch first (or
use the **git-worktree-workflow** skill), then resume.

## Step 1 — QA check, then commit (model authors)

First run the **qa-check** skill — it executes this repo's local QA pipeline
(format → lint → type-check → code-smell → security → tests → build, scoped
to the change, per the repo's QA doc) and reports each dimension's status.
**Resolve findings before continuing; do not commit on a failing gate.**
(qa-check's CI stage is Step 4 here, not part of this local pass.)

qa-check's format/lint/test stages are the pre-commit sequence — run it ONCE
(per `rules/pre-commit.md`): the fix config, then the check config.

```bash
pre-commit run --all-files --config .pre-commit-config-fix.yaml
pre-commit run --all-files
```

Stage and commit with a Conventional Commit message (subject < 72 chars,
imperative; body explains *why*). Group into logically-themed commits;
don't dump development noise. Keep the `Co-Authored-By` footer.

## Step 2 — Push

```bash
git push -u origin "$CUR"
```

## Step 3 — Open the PR (model writes the body)

Compose the title (< 72 chars) and a body per `rules/gh.md` (`## Summary`
+ `## Test plan`), then:

```bash
ship.sh pr-create --title "<title>" --body "<body>"
```

The script handles the PAT→OAuth fallback. Report the PR URL.

## Step 4 — Watch CI

```bash
ship.sh ci-watch "$CUR"
```

Act on the exit code — it checks **both** the run conclusion **and**
warning/error annotations a green conclusion would otherwise hide:

- **`0` (clean):** proceed.
- **`1` (failed, or error-level annotations):** fetch `gh run view <id>
  --log-failed`, diagnose, and propose a fix before touching files —
  distinguish code failures (fix the source) from infra failures (`gh run
  rerun --failed`). Fix, push, re-watch until green. **Do not merge on red.**
- **`2` (passed, but warnings present):** the printed `annotations:` block
  lists them. **Do not silently merge** — report the warnings to the user
  and get acknowledgment (or fix them) before proceeding to merge.

## Step 5 — Merge (only with explicit approval)

Confirm the user asked to merge this branch. Discover the allowed methods
(rulesets often restrict to squash-only) and choose:

```bash
ship.sh merge-methods
```

| Situation                                   | Flag        |
|---------------------------------------------|-------------|
| Only `squash` allowed                       | `--squash`  |
| Single-theme PR, no restriction             | `--squash`  |
| Multi-theme PR worth preserving as commits  | `--merge`   |

`merge-methods` is **best-effort**: on a repo whose rulesets you can't read
(a fork/upstream you don't control, or a misconfigured repo) it can only
report the repo-level allowances, which may be looser than a ruleset
actually enforces. The merge call is the real authority.

```bash
ship.sh merge <number> --squash   # or --merge / --rebase
```

Read the rejection, if any:

- *Method not allowed* (e.g. "Merge commits are not allowed") — a ruleset
  is stricter than `merge-methods` saw. Retry with an allowed method
  (`--squash` is the safe default).
- *Missing required checks* — CI is not green or a required check name
  doesn't match a job `name:`. Fix that; do not bypass.

## Step 6 — Post-merge cleanup

```bash
ship.sh cleanup "$CUR"
```

Report the merge commit and what landed.

## Notes

- After a merge, a CI workflow that publishes artifacts (images, packages,
  releases) on `push` to the default branch runs again — watch it with
  `ship.sh ci-watch <default-branch>` if the user cares about the publish.
- For upstream/fork PRs, target the upstream repo (`gh repo view --json
  parent`) and prefer rebase for upstream-bound branches (`rules/git.md`).
- Invoke `ship.sh` by its path in this skill's `scripts/` directory.
