---
paths:
  - ".pre-commit-config.yaml"
  - ".pre-commit-config-fix.yaml"
---

# pre-commit Agent Contract

**Version:** v1.4.0

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

## Recommended Cross-Cutting Hooks

Beyond the obvious language/file-type linters (shellcheck, shfmt, yamllint,
markdownlint, a JS/TS linter, …), pre-commit offers **cross-cutting** hooks
that are easy to forget but cheap to add and catch whole classes of mistakes
independent of language. **Consider** these for any repo (don't add all of
them — pick what fits; verify repo/rev/hook-id per *Hook and Repo
Verification* first):

### Secrets / safety

- `gitleaks` (`gitleaks/gitleaks`) — scan **staged** content for secrets at
  commit time. (Full repo/history scanning is the **security-scan** skill's
  job, not this hook.)
- `detect-private-key` — block committed private keys.
- `detect-aws-credentials` — block AWS keys (when AWS is in play).

### Git hygiene / safety (from `pre-commit/pre-commit-hooks`)

- `no-commit-to-branch` — block direct commits to a protected branch (pair
  with server-side branch protection; see `git.md`).
- `check-added-large-files` — stop accidental large blobs entering history.
- `check-merge-conflict` — catch leftover `<<<<<<<` conflict markers.
- `check-case-conflict` — names that collide on case-insensitive filesystems
  (macOS/Windows).
- `check-symlinks` / `destroyed-symlinks` — broken symlinks, and symlinks
  accidentally turned into regular files.
- `mixed-line-ending` — CRLF/LF mixups.

### Exec-bit / shebang consistency

- `check-executables-have-shebangs` — executables must have a shebang.
- `check-shebang-scripts-are-executable` — shebang'd scripts must be `+x`.

### Whitespace / encoding (fixers — for the fix config)

- `trailing-whitespace`, `end-of-file-fixer`, `fix-byte-order-marker`.

The point is to *consider* the list, not adopt it wholesale: a repo that uses
submodules wouldn't add `forbid-new-submodules`; a repo with no AWS skips
`detect-aws-credentials`. The **qa-check** skill audits a repo's config
against this list and flags applicable hooks that are missing.

## Setup and Maintenance Commands

A config file does nothing on its own. Until the git hook is installed,
hooks run only when invoked manually (`pre-commit run`). Pick the right
setup command:

| Command | What it does | When to use |
|---------|--------------|-------------|
| `pre-commit install` | Installs the `.git/hooks/pre-commit` git hook so the check config runs on every `git commit`. Hook environments build lazily on first run. | The normal one-time setup per clone. **Without this (or a manual `pre-commit run`) the config is inert.** |
| `pre-commit install --install-hooks` | The above **plus** eagerly builds all hook environments now rather than on the first commit. | When the first commit should be fast, or to surface install/build errors immediately — e.g. in an onboarding/setup script. |
| `pre-commit install-hooks` | Builds the hook environments **without** installing the git hook. | Pre-warming environments (CI caches, before going offline) when commits should **not** be gated, or the git hook is installed separately. |

Notes:

- The git hook from `pre-commit install` uses **`.pre-commit-config.yaml`**
  only. A repo's fix config (e.g. `.pre-commit-config-fix.yaml`) is never a
  git hook — run it manually with `--config` (see the fix workflow below).
- `pre-commit run --all-files` / `--files <f>` work without `install`; use
  them for ad-hoc checks and in CI.

### autoupdate — keep revs current

Hook `rev:`s are pinned. When drift is suspected (a hook is stale, or a newer
tool release is needed), bump with autoupdate — **once per config file**,
since a repo may have more than one:

```bash
pre-commit autoupdate                                       # .pre-commit-config.yaml
pre-commit autoupdate --config .pre-commit-config-fix.yaml  # fix config
```

Review the rev changes, then re-run the hooks to confirm nothing broke. Per
*Hook and Repo Verification*, never hand-edit a rev to a guessed value — let
autoupdate resolve it, or verify via `gh`.

### validate-config — after editing a config

After creating or editing a config, validate its schema before relying on it:

```bash
pre-commit validate-config .pre-commit-config.yaml
pre-commit validate-config .pre-commit-config-fix.yaml
```

### gc — reclaim cached environments

autoupdate and rev changes leave old, unused hook environments in the
pre-commit cache. Reclaim that space periodically:

```bash
pre-commit gc
```

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
