# packwiz fork TODO

Fork-specific work. Not upstream-shared. See `.claude/WORKFLOW.md` for
the broader workflow.

## Watched PRs

When the user asks to "check watched PRs" (or similar), walk this
list and report each PR's `state`, `mergeable`, `reviewDecision`, and
most recent `updatedAt` via `gh pr view <N> --repo packwiz/packwiz`.

### Our own upstream PRs

Watch for: review activity, merge events, mergeability changing to
`CONFLICTING` after a `main` sync.

- [ ] **PR #306** — `add-metadata` — CurseForge metadata with
      links/categories. Branch: `add-metadata`.
- [ ] **PR #359** — `list-pinned` — pinned/unpinned mod filtering for
      `packwiz list`. Branch: `list-pinned`.

### Upstream PRs we're tracking but don't own

Watch for: author response, new commits, readiness to merge into
`mine`.

- [ ] **PR #281** — *add slug and provider options for list* by
      @Omay238. Posted review comment 2026-05-13 flagging
      `-g -v` swallow and slug-extraction panic risk. Author has
      previously acknowledged the PR is incomplete (`todo: url` in
      body). When/if author addresses concerns or pushes new commits,
      re-evaluate whether to merge into `mine`.

## Routine maintenance reminders

- After `main` advances from `upstream/main`: rebase each open PR
  branch onto fresh `upstream/main` and force-push (see
  `WORKFLOW.md` "Routine maintenance"). The skill's Operation 2
  handles individual branches.
- After a watched-PR merge upstream: corresponding local branch and
  worktree can be cleaned up (skill Operation 5). The merge gets
  absorbed into `mine` on the next `main` sync.

## Pending decisions

(none open)

## Notes

- This list is fork-local. It's never tracked in git and never sent
  upstream — `.claude/` is excluded via `.git/info/exclude`.
