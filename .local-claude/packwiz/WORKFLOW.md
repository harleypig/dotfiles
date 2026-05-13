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

## Default development flow

Almost every change in this repo is intended to be viable as an
upstream PR, even when its first destination is `mine`. So:

1. **Default**: any feature, bug fix, or non-trivial change starts
   on a `pr/<name>` branch rebased on `upstream/main`. This holds
   regardless of whether we plan to open a PR immediately, or ever.
2. **Experimentation exception**: pure exploration / spike work can
   happen on a throwaway branch with any convenient name. If the
   experiment is to be kept and landed on `mine`, **rewrite it
   into a clean `pr/<name>` branch first** — squash, reorganize,
   drop exploratory commits — then merge that branch into `mine`
   the usual way (`--no-ff`).
3. **`mine`-only work**: rare. A change is genuinely fork-specific
   only if it would never make sense to propose upstream (a
   personal config, a workflow integration tied to this user's
   deployment). The user must explicitly authorize landing such a
   change directly on `mine`. **If unsure which class a change
   belongs to, ask.**

### A `pr/<name>` branch is not automatically a pull request

Creating the branch and opening the PR are two distinct steps.
Don't run `gh pr create` (or git-worktree-workflow Operation 4
"Prep for PR") just because the branch exists. Wait for explicit
user direction. A `pr/<name>` branch can be merged into `mine` and
sit there indefinitely before (or without ever) becoming a public
upstream PR.

**Why this convention:** every change stays reviewable and
upstream-shippable by default, `mine` doesn't drift into territory
that can't be contributed back, and we preserve the option to
upstream the work later without archaeology.

### Check upstream before starting

Before starting any non-trivial change, look for prior art so we
don't duplicate work the community has already proposed:

```bash
gh issue list --repo packwiz/packwiz --search "<keywords>" \
    --state all
gh pr list    --repo packwiz/packwiz --search "<keywords>" \
    --state all
```

Also scan `.claude/TODO.md` — Watched PRs, Planned work, and
Future considerations all carry PR references we've already
catalogued.

If a viable PR exists, prefer reviewing/extending it (the
"PR #391 → CurseForge audit" and "PR #316 → CurseForge
releaseType" entries in TODO.md are existing examples of that
pattern) over starting a parallel effort. Note the search outcome
in the first commit message of the new branch or in TODO.md so
the lookup isn't redone later.

## Tracking unsubmitted upstream candidates

A `pr/<name>` branch can be merged into `mine` without ever being
opened as an upstream PR. When that happens the change is live in
our deployment but invisible to upstream — and other contributors
can unknowingly duplicate it.

To stay good netizens:

- Every time a `pr/<name>` branch is merged into `mine` without
  opening a PR, add an entry to `.claude/TODO.md` under
  "Unsubmitted upstream candidates."
- Periodically (e.g., when picking the next thing to work on),
  walk that list and decide whether each candidate is ready to
  propose upstream.
- When a candidate is opened as a PR, move its TODO entry from
  "Unsubmitted upstream candidates" to "Our own upstream PRs" in
  the watchlist.
- If a candidate is intentionally `mine`-only (rare), document
  the reason in the entry and leave it parked as a record. That
  record both prevents accidental upstreaming and signals to
  future-us not to revisit the decision absent a reason.

## Routine maintenance: keep PR branches current after a main sync

When `main` advances (after pulling new commits from `upstream/main`),
every open upstream PR branch must be refreshed so its PR diff stays
clean and stays mergeable:

1. Fast-forward `main` from `upstream/main`.
2. **Audit what merged upstream.** Before any downstream merge or
   rebase, walk the new commits and reconcile them against
   `.claude/TODO.md`:
   - Watched PRs that just merged — close their entries; the
     branches we owned for them are cleanup candidates.
   - Planned work waiting on (or framed against) an upstream PR
     that merged — update state, re-evaluate scope.
   - Open PR branches whose work may have been subsumed by an
     upstream merge — flag for verification during the rebase
     step below.

   Procedure: see the git-worktree-workflow skill's "Post-sync
   upstream audit" subsection of Operation 2. Surface findings as
   a short summary before continuing.
3. Merge `main` into `mine` (`--no-ff`) so the personal deployment
   absorbs the new upstream work.
4. For each open PR branch (`add-metadata`, `list-pinned`, future
   `pr/*`): **rebase onto `upstream/main`**, not merge. Rebase keeps
   the PR diff tight and review-friendly. Push with
   `--force-with-lease --force-if-includes`. If a rebase produces
   an empty branch (work subsumed by an upstream merge identified
   in step 2), close that PR rather than force-pushing nothing.
5. If a rebase produces conflicts, resolve before pushing — don't
   leave half-rebased branches.

After step 4, each upstream PR shows only the changes it's proposing,
with no stale "merge upstream/main" commits cluttering the diff. This
is the convention upstream reviewers expect.

The git-worktree-workflow skill's Operation 2 ("Sync a branch with
its base") handles individual branch syncs. When more than one
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
