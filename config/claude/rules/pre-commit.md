---
paths:
  - ".pre-commit-config.yaml"
  - ".pre-commit-config-fix.yaml"
---

# pre-commit Agent Contract

**Version:** v1.0.0

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

## Agent Rules

* Agents MUST treat `.pre-commit-config.yaml` as **non-modifying checks only**.
* If `.pre-commit-config-fix.yaml` exists:
  * It defines optional, modifying hooks.
* Agents MUST NOT apply auto-fixes without explicit user approval.
* Default agent behavior:
  * Run non-modifying checks only.
* When explicitly approved by the user:
  * Agents MAY run modifying hooks.
* In CI contexts:
  * Agents MUST run checks only.
  * Agents MUST NOT apply or commit fixes.

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

When a `git commit` is blocked by a failing pre-commit hook:

* Report the full hook output to the user.
* MUST NOT retry the commit automatically.
* MUST NOT skip hooks (`--no-verify`) without explicit user approval.
* MUST NOT apply fixes and re-commit without explicit user approval.
* Diagnose the failure, propose a fix, and wait for user confirmation
  before proceeding.
