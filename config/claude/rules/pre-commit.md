---
paths:
  - ".pre-commit-config.yaml"
  - ".pre-commit-config-fix.yaml"
---

# pre-commit Agent Contract

**Version:** v1.2.0

This document defines **normative agent behavior** for interacting with
**pre-commit** in this repository.

Precedence: `this document` > `WORKFLOW.md` > `CLAUDE.md`

## Purpose

This document specifies how agents must behave when **pre-commit** is in use
within a repository. It does not describe how to configure pre-commit itself,
only how agents are allowed to interact with it.

## Tool Detection

The repository is considered to be using **pre-commit** if:

* `.pre-commit-config.yaml` exists at the repository root.

No other signal is required.

## Hook and Repo Verification

Before adding or updating any hook entry in a pre-commit config file,
verify that the repo and hook ID actually exist. Do not assume a repo
URL or hook ID is correct based on training data — mirrors move, repos
get renamed or deleted, hook IDs change, and version numbers drift.

### Step 1 — Find the repo

**When the owner/repo is unknown**, search GitHub code for repos that
define the hook:

```bash
gh search code --filename .pre-commit-hooks.yaml '<hook-name>' --limit 10
```

This searches repos whose `.pre-commit-hooks.yaml` file mentions the
hook name. It is more targeted than `gh search repos` because it
confirms the hook is actually declared in the repo.

**Choosing from multiple results:** run these checks on each candidate:

```bash
# Activity and popularity
gh repo view <owner>/<repo> --json stargazerCount,updatedAt,description

# Verify the hook ID exists and does what you expect
gh api repos/<owner>/<repo>/contents/.pre-commit-hooks.yaml \
  --jq '.content' | base64 -d | grep -A6 '<hook-id>'
```

Prefer repos that are actively maintained (updated within ~1 year) and
have meaningful star counts. When an official repo from the tool's own
org appears in results, prefer that. For unmaintained or zero-star
repos with no recent activity, keep looking.

### Step 2 — Get the rev

```bash
# Try releases first
gh release list --repo <owner>/<repo> --limit 5

# Fall back to tags if releases returns empty
gh api repos/<owner>/<repo>/tags --jq '.[].name' | head -5
```

Use the latest tag from whichever command returns results. Never
invent or guess a version string.

### Step 3 — Verify runtime compatibility

For hooks that install via npm (`language: node`), check the Node
version before pinning:

```bash
node --version
```

If the latest release requires a newer runtime than is installed, use
the list from Step 2 to find and pin the most recent compatible
release instead.

### Local hooks (`repo: local`)

No remote verification needed, but verify the `entry` command is
available before writing the hook:

```bash
which <command>
```

If the command is not installed, note the missing dependency in a
comment on the hook or add `stages: [manual]` so a missing binary
does not break `git commit` for other contributors.

## Agent Rules

* Agents MUST treat `.pre-commit-config.yaml` as **non-modifying checks only**.
* If `.pre-commit-config-fix.yaml` exists:
  * It defines optional, modifying hooks.
* Agents MUST NOT apply auto-fixes mid-session in response to hook
  failures during development. Report the failure; do not silently fix
  and re-run.
* Default agent behavior during development:
  * Run non-modifying checks only.
* In CI contexts:
  * Agents MUST run checks only.
  * Agents MUST NOT apply or commit fixes.

## Pre-Commit Workflow When Ready to Commit

When all changes are complete and the agent is preparing to commit and
push, run in this order — no additional user approval needed:

1. Run `.pre-commit-config-fix.yaml` (all modifying hooks) to apply
   auto-fixes (formatting, etc.).
2. Run `.pre-commit-config.yaml` (check-only) to confirm everything
   passes cleanly.
3. Proceed with `git commit` and `git push`.

Do NOT run the fix config mid-session in response to individual hook
failures. It is a final preparation step only, run once when the work
is done.

## Branch Protection / Merge Policy Blocks

Some repos enforce that merges to protected branches (e.g., `master`, `main`)
must go through a pull request and pass CI — direct pushes are rejected by
the remote even if all local pre-commit hooks pass.

Signals that this is the situation (not a pre-commit failure):

* `git push` is rejected with `remote: error: GH006: Protected branch update
  failed` or similar GitHub/GitLab remote rejection messages.
* The error references required status checks, required reviews, or
  "push restrictions."

When this occurs:

* MUST NOT attempt to force-push to bypass branch protection.
* MUST NOT suggest workarounds that bypass the repo's merge policy.
* Inform the user that a PR is required and offer to create one via `gh`
  (see `gh.md`), or to use the git-worktree-workflow skill (Operation 4:
  Prep for PR).

## Commit-Blocking Hook Failures

This section applies when a `git commit` is blocked by a failing
pre-commit hook during development (i.e., outside the final
commit-preparation workflow described above). If the failure occurs
during the fix → check → commit sequence, diagnose and fix the
underlying issue before retrying that sequence.

When a `git commit` is blocked mid-session by a failing pre-commit
hook:

* Report the full hook output to the user.
* MUST NOT retry the commit automatically.
* MUST NOT skip hooks (`--no-verify`) without explicit user approval.
* MUST NOT apply fixes and re-commit without explicit user approval.
* Diagnose the failure, propose a fix, and wait for user confirmation
  before proceeding.
