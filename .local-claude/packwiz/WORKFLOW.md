# packwiz Workflow

This is a fork of `packwiz/packwiz` (upstream) at `harleypig/packwiz`
(origin). Upstream is slow to review and merge, so this fork doubles
as a personal-deployment line: selected PRs are pre-merged into `mine`
for local use before upstream accepts them.

## Branches

- `main` — tracks `upstream/main` exactly. Never modified locally.
  Sync via fast-forward only.
- `mine` — personal integration branch. `main` plus my own
  upstream-bound topic branches merged with `--no-ff`, plus selected
  third-party PRs. **Never push upstream.**
- Upstream PR branches — clean topic branches off `upstream/main`,
  rebased before each push. Active:
  - `add-metadata` — upstream PR #306 (open)
  - `list-pinned`  — upstream PR #359 (open)

## Branch naming

- Grandfathered (do not rename — PRs already open against these
  names): `add-metadata`, `list-pinned`.
- `mine` — conventional personal integration branch name.
- Going forward: follow `~/.claude/rules/git.md`. New upstream PR
  branches use `pr/<name>`; new own-fork features use
  `feature/<name>`.

## Routine maintenance: keep PR branches current after a main sync

When `main` advances (after pulling new commits from `upstream/main`),
every open upstream PR branch must be refreshed so its PR diff stays
clean and stays mergeable:

1. Fast-forward `main` from `upstream/main`.
2. Merge `main` into `mine` (`--no-ff`) so the personal deployment
   absorbs the new upstream work.
3. For each open PR branch (`add-metadata`, `list-pinned`, future
   `pr/*`): **rebase onto `upstream/main`**, not merge. Rebase keeps
   the PR diff tight and review-friendly. Push with
   `--force-with-lease --force-if-includes`.
4. If a rebase produces conflicts, resolve before pushing — don't
   leave half-rebased branches.

After step 3, the upstream PR shows only the changes the PR is
proposing, with no stale "merge upstream/main" commits cluttering the
diff. This is the convention upstream reviewers expect.

The git-worktree-workflow skill's Operation 2 ("Sync a branch with
its base") handles this for individual branches. When more than one
branch needs it, just repeat per branch.

## Local-only tooling

`.claude/` is a symlink to `$DOTFILES/.local-claude/packwiz/`,
excluded from git via `.git/info/exclude` so it never leaks into
upstream PRs. Versioned inside the dotfiles repo.

## Fork-local TODO

Fork-specific tasks (PRs to watch, integration decisions, deferred
work) live in `.claude/TODO.md`. Claude should read it when working in
this repo and when the user asks about pending work.

There is no upstream-tracked TODO in this repo; if one is ever added,
keep the two distinct: upstream-shared work goes in the repo-root
TODO, fork-specific work stays in `.claude/TODO.md`.

## Watched PRs

The watchlist (which PRs to monitor and what to look for) lives in
`.claude/TODO.md` under "Watched PRs". When the user asks "check the
watched PRs" or similar, walk that list and report state via
`gh pr view <N> --repo packwiz/packwiz`.

## Authentication note

Most `gh` operations work with the env-var PAT. Writes against
upstream (PR comments, etc.) require the OAuth fallback documented in
`~/.claude/rules/gh.md` — prefix with `GH_TOKEN= GITHUB_TOKEN= `.
