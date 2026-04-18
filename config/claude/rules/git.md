---
# No paths — applies to all commits and branches regardless of file type.
---

# Git Rules

**Version:** v1.0.0

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

- Subject line: under 72 characters; imperative mood ("add", not "added")
- Body: wrap at 72 columns; explain *why*, not *what*
- Footer: `Fixes #123`, `Relates to #456` where applicable
- Common types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `ci`

## Branch Naming

- `feature/<name>` — new functionality
- `bugfix/<name>` — bug fixes
- `docs/<name>` — documentation only
- `issue/<N>` — issue branches (managed by git-worktree-workflow skill)
- `pr/<name>` — PR-prep branches (managed by git-worktree-workflow skill)

## Default Branch

**Never hardcode `main` or `master`.** Always derive from the remote:

```bash
git symbolic-ref "refs/remotes/origin/HEAD" | sed 's@^refs/remotes/origin/@@'
```

If unset, query via `gh repo view --json defaultBranchRef -q .defaultBranchRef.name`
and then `git remote set-head origin <branch>` to cache it.

## Worktrees

Use the **git-worktree-workflow** skill for all worktree operations: creating
issue branches, syncing with upstream, prepping PRs, and cleanup. See
`config/claude/skills/git-worktree-workflow/SKILL.md`.

Key defaults from that skill:
- `--no-ff` on all merges unless the user overrides
- Rebase for upstream-bound PR branches; merge `--no-ff` for own-repo branches
- Resolve worktree path from existing patterns before defaulting to
  `$PARENT_DIR/<branch-without-prefix>`

## Agent Rules

- NEVER hardcode `main` or `master` — always derive the default branch.
- NEVER force-push without `--force-with-lease --force-if-includes`; warn
  before doing so. (`--force-with-lease` alone can still lose commits that
  were fetched but not integrated; `--force-if-includes` closes that gap.)
- NEVER force-delete a branch silently — always confirm with the user.
- NEVER amend published commits or skip hooks without explicit user approval.
- NEVER push to the default branch without user confirmation.
- Clean working tree is a precondition for sync, prep-for-PR, and cleanup.
  Report and stop on violations; do not auto-stash.
