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

## Related/Foreign Repositories

Repositories related to the current project but not forks of it (dependency
sources, upstream APIs, reference implementations) are expected at
`$PARENT_DIR/<repo-name>/` — siblings of the current clone. Check there
before suggesting a clone location. See the full convention in the
git-worktree-workflow skill under *Related/foreign repositories*.

## Aliases and Configuration

The user maintains git aliases and config tuned to their workflow. Read
them; do not ignore them.

### Discovering aliases

At the start of any non-trivial git work in a repo (onboarding, the first
git-heavy session of the day, or whenever the user invokes an unfamiliar
alias), scan:

```bash
git config --get-regexp '^alias\.'
```

Skim the output, group by category:

- **Trivial shortcuts** — single-letter or two-letter aliases that just
  rename a command (`f`=`fetch`, `s`=`status`, `co`=`checkout`).
- **Convenience** — aliases that bundle a few common flags
  (`remotes`=`remote -v`, `unstage`=`reset HEAD --`).
- **Formatting / complex** — aliases with non-obvious output formatting,
  graph rendering, or multi-step pipelines (`l` for a custom log format,
  `lg` for a graph view, `wip` for a flow that stashes + commits).

### Using aliases

| Category | Default policy |
|----------|----------------|
| Trivial shortcuts | Prefer the full command in agent output. Aliases save the user keystrokes; they cost the user a moment of decoding when reading agent commands. |
| Convenience | Use when the alias's output exactly matches the task. |
| Formatting / complex | **Strongly prefer.** The user designed these for readability; the output usually beats anything you'd assemble ad hoc. Example: `git l` instead of `git log --oneline --decorate --graph`. |

When using a non-trivial alias for the first time in a session, briefly
note what it expands to so the user sees you understand it: "Running
`git l` (your `log --graph --decorate --oneline --all`)."

### Suggesting new aliases

If you find yourself typing the same multi-flag git invocation three or
more times in a session — or notice the user doing the same — surface
it as an alias candidate. Decide its scope via the tier model in
`CLAUDE.md`:

- Generally useful → propose a global `~/.gitconfig` alias.
- Only meaningful in one repo's workflow → propose a repo-local alias
  via `git config --local`.

Don't add the alias unilaterally; propose with the expansion and let
the user decide.

### Reviewing config

Beyond aliases, scan relevant config at onboarding or when the user
asks for a review:

```bash
git config --list --show-origin | grep -vE '^(file:[^[:space:]]+)?\s*(alias\.|user\.email|user\.name)'
```

Categories worth surfacing when they're absent or set to defaults that
fight the user's stated workflow:

- `pull.rebase`, `pull.ff` — affects what `git pull` does silently.
- `rebase.autoStash`, `rebase.autosquash` — quality-of-life during
  rebase.
- `rerere.enabled` — remembers conflict resolutions, huge win for
  long-lived branches in fork-mode repos.
- `branch.sort`, `column.ui` — display-only, but improve `git branch`
  output noticeably.
- `init.defaultBranch` — should match the user's convention.

Suggest changes; don't make them silently. Config changes affect every
repo on the machine.

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
- Keep `Co-Authored-By: Claude ...` footers on commits Claude
  authored or co-authored, including commits destined for upstream
  PRs in third-party repos. The user prefers transparency about AI
  use; do not strip the footer preemptively. Remove it only if the
  user explicitly asks for that specific commit.
- Scan `git config --get-regexp '^alias\.'` at the start of non-trivial
  git work; prefer formatting/complex aliases over equivalent raw
  commands. See *Aliases and Configuration* above.
