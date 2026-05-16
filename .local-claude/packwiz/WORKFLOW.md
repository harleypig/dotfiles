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

### Squash to a clean commit set before opening / re-pushing

Per `~/.claude/rules/gh.md` *Commit hygiene*, upstream PRs go up
as a small, logically-grouped commit set — not the raw
development history. For a single-theme PR: one commit. For a
multi-theme PR (e.g., tests across several packages): one commit
per logical area so each is independently reviewable.

The merges into `mine` are unaffected by this — `mine` keeps the
fine-grained development history. The squash happens on the
`pr/<name>` branch before `gh pr create` runs (and again before
force-pushing review-feedback updates).

For branches that get merged into `mine` AND then later opened as
an upstream PR: do the squash on the `pr/<name>` ref, then
force-push. The earlier merge into `mine` retains the pre-squash
history, which is fine — `mine` never goes upstream.

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

## Test companion branches for grandfathered PRs

Some branches cannot be modified because they have open upstream PRs:
changing them would break the PR head ref and destroy review-thread
continuity. Currently: `add-metadata` (PR #306) and `list-pinned`
(PR #359).

We still want test coverage for the code those PRs introduce. The
solution is a **test companion branch** for each: a branch that merges
in the feature code, the test infrastructure, and the error-handling
fixes so tests can be written and run locally without touching the
grandfathered branch.

Active test companion branches:

- `pr/list-pinned-tests` — tests for `list-pinned` (PR #359)
- `pr/add-meta-tests` — tests for `add-metadata` (PR #306)

### Branch topology

Each test companion branch is a **multi-way merge**, not a linear
stack. For `pr/list-pinned-tests` the shape is:

```
upstream/main (dfd8b68)
    ├─ list-pinned              (feature code)
    ├─ pr/testing               (test infrastructure, PR #402)
    └─ pr/error-handling-*      (library error-posture fixes)
              ↓ merged in this order ↓
         pr/list-pinned-tests   (new tests live here)
```

`pr/add-meta-tests` has the same shape with `add-metadata` as the
feature branch.

**Merge order:** feature branch → `pr/testing` →
`pr/error-handling-library-exits`. Merging `pr/testing` before the
error-handling branch means git recognises the test-infra commits as
already present when the error-handling branch is merged, so they are
not duplicated.

### Why these branches cannot be rebased

`git rebase` on a merge-topology branch silently drops merge commits
and re-linearises history, erasing the record of where each set of
changes came from. **All maintenance on these branches is done by
merging, never rebasing.**

### Maintenance

#### When `upstream/main` advances

```bash
# After fast-forwarding main from upstream/main:
git -C /path/to/test-branch merge --no-ff main
```

Resolve any conflicts, then push.

#### When `pr/testing` is rebased (upstream review feedback)

```bash
git -C /path/to/test-branch merge --no-ff pr/testing
```

Git will bring in only the new/changed commits. If the rebase was
purely a squash (same content, new hashes), the merge may fast-forward
or produce a trivial merge commit. Resolve if needed.

Also re-merge the error-handling branch(es) after they are rebased
onto the new `pr/testing` tip:

```bash
git -C /path/to/test-branch merge --no-ff pr/error-handling-library-exits
```

#### When `pr/testing` AND the feature PR both merge upstream

At this point `upstream/main` contains both the test infrastructure
and the feature code. The test companion branch needs to be rebuilt
so the eventual upstream PR shows only the new tests.

Procedure (one-time, per branch):

1. Fetch and fast-forward `main` from `upstream/main`.
2. Create a new branch off the updated `main`:
   ```bash
   git checkout -b pr/list-pinned-tests-v2 main
   ```
3. Identify the test commits from the old test branch (the commits
   that add actual test code, not the merge commits):
   ```bash
   git log --no-merges --oneline pr/list-pinned-tests ^upstream/main
   ```
4. Cherry-pick those commits onto the new branch:
   ```bash
   git cherry-pick <sha> [<sha> ...]
   ```
5. Merge any remaining error-handling branches (if they have not yet
   merged upstream), after they have been rebased onto new `main`.
6. Push the new branch and open the upstream test PR from it.
7. The old `pr/list-pinned-tests` branch and worktree can be cleaned
   up (git-worktree-workflow skill Operation 5) once the new branch
   is confirmed good.

### Upstream PR timing

Do **not** open a test companion PR upstream until **both** conditions
are met:

1. The feature PR (e.g. `list-pinned` → PR #359) has merged upstream.
2. `pr/testing` (PR #402) has merged upstream.

Until then, upstream reviewers cannot evaluate the tests against code
that exists in their `main`.

### Merging test companion branches into `mine`

Once the tests pass and the branch is ready, merge into `mine` with
`--no-ff` in the main clone:

```bash
git merge --no-ff pr/list-pinned-tests
```

These branches **do** belong on `mine` even though they are
merge-topology branches — `mine` is already a collection of
`--no-ff` merges and the topology is expected there.

When the upstream PR is eventually opened and merged, the test
companion branch and its worktree become cleanup candidates. The
content will have been absorbed into `upstream/main`, and the next
`mine` sync (fast-forward `main` → merge `main` into `mine`) will
pick it up naturally.

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
