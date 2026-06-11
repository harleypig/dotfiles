---
name: git-worktree-workflow
description: Manage git worktree-based development for forked and personal repositories. Use this skill whenever the user wants to work on a GitHub issue, set up a worktree, sync a branch with its upstream base, prepare a branch for a PR, clean up a finished issue, merge or rebase between branches, or perform any operation involving git worktrees. Triggers on phrases like "work on issue #N", "let's tackle issue N", "start issue N", "merge main into X", "pull in upstream", "rebase X on main", "update this branch", "prep for PR", "clean up issue N", "remove the worktree for X", "list worktrees", "reconcile gone branches", "clean up gone branches", or any request mentioning worktrees, issue branches, or cross-branch integration in a forked or personal repo context. Also use when the user references a directory like `issueN` as a sibling of the main repo clone.
---

# Git Worktree Workflow

**Version:** v1.1.0

This skill manages development across git worktrees for forked repos and
personal repos. It covers issue setup, syncing, PR prep, cross-branch
integration, and cleanup.

## Prerequisites

- `git` 2.5+ (worktree support)
- `gh` CLI, authenticated (`gh auth status`)

## Directory convention

All worktrees are **siblings** of (or subdirectories relative to) the base
clone. The base is at `$BASE_DIR`; its parent is `$PARENT_DIR`. The skill
never needs to know the absolute prefix — all paths are derived from
`git rev-parse --show-toplevel`.

Example layout (default naming):

```text
~/projects/PROJECT/
    PROJECT/            base clone (origin + optional upstream remotes)
    issue321/           worktree for issue branch issue/321
    pr/feature-name/    worktree for branch pr/feature-name
    mine/               optional personal base branch worktree (fork mode only)
    some-foreign-repo/  related repo cloned as a sibling (see below)
```

### Related/foreign repositories

Repositories that are related to the current project but are not forks of it
— dependency sources, reference implementations, upstream API repos — are
expected to be found as **siblings** of the base clone at:

```text
$PARENT_DIR/<repo-name>/
```

When the skill needs to reference, locate, or clone such a repo, check
`$PARENT_DIR` first before suggesting a location. If the repo is not already
present as a sibling, default to cloning it there:

```bash
git clone <url> "$PARENT_DIR/<repo-name>"
```

Do not assume a specific prefix for the repo directory name — use the
upstream repository's actual name (i.e., the last path component of its clone
URL, without `.git`). Confirm the derived path with the user before cloning.

### Deriving a worktree path

When creating a new worktree, resolve the path in this order:

1. **User supplied an explicit path** — use it as-is.
2. **Existing worktrees present** — infer the pattern by comparing each
   worktree's path to its checked-out branch:

   ```bash
   git worktree list --porcelain | awk '/^worktree/{wt=$2} /^branch/{print wt, $2}'
   ```

   If a consistent mapping is visible (e.g., all worktrees are
   `$PARENT_DIR/<branch-without-prefix>`), apply the same pattern.
3. **No pattern found / first worktree** — default: strip the remote-tracking
   prefix and preserve any remaining slashes as path separators under
   `$PARENT_DIR`. Examples:
   - branch `issue/321`  → `$PARENT_DIR/issue/321`
   - branch `pr/feature` → `$PARENT_DIR/pr/feature`
   - branch `hotfix`     → `$PARENT_DIR/hotfix`

**Always show the derived path and ask for confirmation before creating.**
The user can supply a different path at that prompt.

**Naming note:** Branch names may contain slashes (`issue/321`); the
corresponding worktree directory preserves those slashes as subdirectory
separators. This means `$PARENT_DIR/issue/321` is a directory nested under
`$PARENT_DIR/issue/`, not a flat sibling.

## Detecting repo mode

Run once at the start of any operation:

```bash
if git remote get-url upstream >/dev/null 2>&1; then
    REPO_MODE=fork
else
    REPO_MODE=own
fi
```

**Fork mode:** has `upstream` remote. PRs typically go to upstream. Issues may
live in either fork or upstream.

**Own-repo mode:** no `upstream`. All issues and PRs live on origin. Simpler
lifecycle.

## Detecting worktree usage

Check once per session whether this repo is already using worktrees:

```bash
WORKTREE_COUNT=$(git worktree list --porcelain | grep -c "^worktree ")
WORKTREES_IN_USE=$([ "$WORKTREE_COUNT" -gt 1 ] && echo true || echo false)
```

If `WORKTREES_IN_USE=false` and the user triggers a worktree-style operation
(issue setup, sync, prep-for-PR, cleanup), ask before proceeding:

> "This repo doesn't currently use worktrees. Set one up (recommended for
> parallel issue work), or work on a plain branch in the current clone?"

- **Worktree path:** proceed with the full skill as documented.
- **Plain-branch path:** create/checkout the branch in the main clone; skip
  all `git worktree add/remove` commands. Sync, prep-for-PR, and cleanup
  steps still apply — just without the worktree layer.

## Detecting the default branch

Never hardcode `main` or `master`. Derive it:

```bash
# Fork mode — default comes from upstream
DEFAULT_REMOTE=upstream
# Own mode — default comes from origin
DEFAULT_REMOTE=origin

# Try the symbolic ref first (fast, local)
DEFAULT_BRANCH=$(git symbolic-ref "refs/remotes/${DEFAULT_REMOTE}/HEAD" 2>/dev/null | sed "s@^refs/remotes/${DEFAULT_REMOTE}/@@")

# If unset, query via gh and then set it locally for next time
if [ -z "$DEFAULT_BRANCH" ]; then
    # In fork mode query upstream's repo; in own-repo mode query origin
    if [ "$REPO_MODE" = "fork" ]; then
        DEFAULT_BRANCH=$(gh repo view --json parent -q .parent.defaultBranchRef.name)
    else
        DEFAULT_BRANCH=$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
    fi
    git remote set-head "$DEFAULT_REMOTE" "$DEFAULT_BRANCH"
fi
```

If `DEFAULT_BRANCH` cannot be determined, stop and report — do not guess. In
fork mode, if upstream has neither `main` nor `master`, local should not use
them either; use only what upstream uses.

## Getting repo identifiers

```bash
BASE_DIR=$(git rev-parse --show-toplevel)
PROJECT_NAME=$(basename "$BASE_DIR")
PARENT_DIR=$(dirname "$BASE_DIR")

ORIGIN_SLUG=$(gh repo view --json nameWithOwner -q .nameWithOwner)
# Fork mode only — use gh to avoid parsing SSH/HTTPS URL variants:
UPSTREAM_SLUG=$(gh repo view --json parent -q .parent.nameWithOwner 2>/dev/null)
```

## Keeping per-clone tooling out of upstream PRs

In fork-mode repos you don't control, anything tracked by git eventually
risks leaking into a PR diff — especially when topic branches are rebased
on a freshly-synced default branch that contains your local-only config.

The clean solution is to keep per-clone tooling files **untracked
entirely** via `.git/info/exclude`. This file is per-clone, never
committed, and survives every rebase and worktree operation.

### Pattern

For each fork-mode repo where you want local Claude config (or other
per-clone tooling — aider working files, editor metadata, MCP caches):

1. Create the config in a stable out-of-tree location (e.g.,
   `$DOTFILES/.local-claude/<repo>/`) so it's versioned with your
   dotfiles, not the project.
2. Symlink it into the repo at the conventional path:

   ```bash
   ln -s "$DOTFILES/.local-claude/<repo>" "$BASE_DIR/.claude"
   ```

3. Add the symlink's name to `.git/info/exclude` so git ignores it
   everywhere — every branch, every worktree, every rebase:

   ```bash
   printf '\n# Per-clone Claude config (symlinked out-of-tree).\n.claude\n' \
       >> "$BASE_DIR/.git/info/exclude"
   ```

Verify with `git status` — the symlink should not appear as untracked.

### When to use this

- **Fork-mode repos** where upstream's `.gitignore` doesn't (and may
  never) list your tooling paths.
- **Own-repo mode** where you'd rather not commit Claude config to a
  public repo even though you control it.

In own-repo mode where you're fine committing the config, just add it
to `.gitignore` normally — no symlink needed.

### Candidates for exclusion

Add only what you actually use. Common per-clone tooling paths:

- `.claude` — Claude Code per-repo config
- `.aider*` — aider working files and history
- `.serena/` — Serena MCP project cache
- `.idea/`, `.vscode/` — editor metadata if not shared with the team

Adding paths you don't use is harmless but adds noise. Prefer minimal
and extend on demand.

### Fork-local TODO tracking

Fork-mode repos accumulate work that doesn't belong upstream: PRs to
watch, integration decisions, deferred personal-branch work, notes on
third-party PRs the user is considering pulling into `mine`.

**Pattern:** keep a `.claude/TODO.md` for fork-specific tasks. It
lives inside the symlinked-out-of-tree `.claude/` directory and so
inherits the same properties:

- Excluded from git via `.git/info/exclude`.
- Versioned in `$DOTFILES/.local-claude/<repo>/`.
- Not auto-loaded into Claude context — reference it from
  `.claude/WORKFLOW.md` so Claude reads it when the task makes it
  relevant.

#### Coexistence with an existing repo TODO

Some repos already track work in a root-level `TODO.md` (or
`ROADMAP.md`, `docs/TODO.md`, an issue tracker, etc.). The two purposes
are different and the files should remain separate:

| File | Purpose | Visibility |
|------|---------|------------|
| Root `TODO.md` (if upstream has one) | Shared roadmap / known issues | Tracked, upstream-visible |
| `.claude/TODO.md` | Fork-specific tracking, watched PRs, integration decisions | Untracked, local only |

At onboarding, check for an existing root TODO and decide:

- **No upstream TODO exists** → `.claude/TODO.md` is the only TODO;
  WORKFLOW.md notes this.
- **Upstream TODO exists** → keep both. WORKFLOW.md should briefly
  note what goes where so future sessions don't conflate them or
  write fork-specific items into the tracked file.

The general rule: anything that would be useful to other contributors
goes in the tracked TODO; anything specific to this user's fork or
personal deployment goes in `.claude/TODO.md`.

#### Watched PRs

A common use of `.claude/TODO.md` in fork mode is tracking PRs to
monitor — both the user's own (waiting on review/merge) and
third-party ones being evaluated for inclusion in `mine`. Structure
the watchlist so a session can walk it and report status via
`gh pr view <N>`. WORKFLOW.md should tell Claude how to interpret
phrases like "check watched PRs".

## Onboarding an existing repo: legacy branch names

Conventions in `rules/git.md` (`issue/<N>`, `pr/<name>`, `feature/<name>`,
etc.) are forward-looking. Repos that pre-date Claude integration almost
always have branches that don't match — bare topic names (`add-metadata`),
historical experiments, abandoned exploration branches.

Do not rename branches mechanically. Each non-conforming branch needs a
deliberate decision at onboarding.

### Inventory

```bash
git branch -a
gh pr list --state open --author "@me" \
   --json number,title,headRefName,baseRefName,url
```

For fork-mode repos also check upstream:

```bash
gh pr list --repo "$UPSTREAM_SLUG" --author "@me" --state open \
   --json number,title,headRefName,baseRefName,url
```

### Decision matrix

| Branch state | Recommended action | Reason |
|--------------|-------------------|--------|
| Has an open PR (any remote) | **Grandfather** — leave as-is | Renaming breaks the PR's head ref; contributor would have to repush from a new branch and reviewers lose review-thread continuity. |
| Personal integration branch (e.g., `mine`) | **Grandfather** | `mine` is conventional for personal base branches. |
| Local-only, actively used, no PR | **Rename to convention** | Cheap; aligns history going forward. |
| Local-only, stale / experimental | **Propose deletion separately** (Operation 5) | Don't rename then delete; just delete. |
| Tracks an upstream branch you don't own | **Grandfather** | You can't rename someone else's branch. |

### Record the decision

Once decided, record the outcome in the repo's `.claude/WORKFLOW.md` so
future sessions don't re-evaluate:

```markdown
## Branch naming

Going forward: follow `rules/git.md` conventions (`pr/<name>` for
upstream PRs, `feature/<name>` for own-repo features, etc.).

Grandfathered (do not rename):
- `add-metadata` — open upstream PR #306
- `list-pinned` — open upstream PR #359
- `mine` — personal integration branch
```

### Renaming, when chosen

If the user does want to rename a branch that has no open PR:

```bash
git branch -m <old-name> <new-name>
git push origin :<old-name> <new-name>          # delete old, push new
git push origin -u <new-name>                    # set upstream
```

If the branch has been pushed but no PR opened yet, this is safe. Warn
before deleting the remote side.

---

## Operation 1: Work on issue #N (setup or resume)

Triggered by: "work on issue #N", "let's tackle N", "start issue N", "open
issue N", etc.

### Step 1: Resolve the issue

```bash
# Fork mode: try origin first, then upstream
gh issue view N --repo "$ORIGIN_SLUG" --json number,title,body,state,url 2>/dev/null \
  || gh issue view N --repo "$UPSTREAM_SLUG" --json number,title,body,state,url
```

In own-repo mode, skip the upstream fallback. If neither finds it, stop and
tell the user.

Record which repo the issue came from — this drives the merge-vs-rebase
default later.

### Step 2: Check worktree state

```bash
BRANCH_NAME="issue/${N}"

# Derive WORKTREE_PATH using the "Deriving a worktree path" rules above.
# For a plain issue branch with no existing pattern the default is:
WORKTREE_PATH="${PARENT_DIR}/issue/${N}"
# Always confirm the derived path with the user before creating.

# Does the worktree already exist?
if git worktree list --porcelain | grep -q "^worktree ${WORKTREE_PATH}$"; then
    WORKTREE_EXISTS=true
fi

# Does the branch exist?
if git show-ref --verify --quiet "refs/heads/${BRANCH_NAME}"; then
    BRANCH_EXISTS=true
fi
```

### Step 3: Act based on state

| Worktree | Branch | Action |
|----------|--------|--------|
| exists   | exists | cd in, report current branch and tree state, hand off |
| missing  | exists | `git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"` |
| exists   | missing | unusual — report and let user sort it out |
| missing  | missing | create both (fresh setup) |

Fresh setup:

```bash
git fetch "$DEFAULT_REMOTE"
# -b creates the branch and worktree atomically; avoids orphaned branch on failure
git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "${DEFAULT_REMOTE}/${DEFAULT_BRANCH}"
# Set tracking so git status shows ahead/behind
git -C "$WORKTREE_PATH" branch --set-upstream-to="${DEFAULT_REMOTE}/${DEFAULT_BRANCH}" "$BRANCH_NAME"
```

### Step 4: Report and hand off

Subsequent commands should run with `cwd=$WORKTREE_PATH`. Report:

- Issue title and URL
- Worktree path
- Branch name
- Current tree state (clean / dirty files)
- Whether the worktree was pre-existing

**If the existing worktree's state doesn't match expectations** (different
branch checked out, dirty tree, etc.): cd in, report what's actually there,
stop. Do not auto-fix.

---

## Operation 2: Sync a branch with its base

Triggered by: "merge main into this", "pull in upstream", "sync", "update this
branch", "rebase on main", "pull from upstream", etc.

### Parse source and target

```text
if user says "X into Y":
    SOURCE = X; TARGET = Y
    cd to Y's worktree (resolve via git worktree list --porcelain)
elif user says "from X" or "sync from X" or names a bare branch:
    SOURCE = X; TARGET = current branch (git rev-parse --abbrev-ref HEAD)
else:  # no args
    TARGET = current branch (git rev-parse --abbrev-ref HEAD)
    SOURCE = natural base (see table below)
```

If TARGET's worktree can't be located, stop and ask.

### Natural base by branch type

| Branch pattern | Natural base |
|----------------|--------------|
| `issue/*` in fork mode, issue from upstream | `upstream/$DEFAULT_BRANCH` |
| `issue/*` in fork mode, issue from origin only | `origin/$DEFAULT_BRANCH` (or user's personal base if they have one) |
| `issue/*` in own-repo mode | `origin/$DEFAULT_BRANCH` |
| personal base branch in fork (e.g. `mine`) | `upstream/$DEFAULT_BRANCH` |
| default branch itself | `upstream/$DEFAULT_BRANCH` (fork) or nothing to sync (own) |

If the issue's origin isn't already known from this session, re-resolve it via `gh issue view` before deciding.

### Merge vs rebase decision

Explicit user verb wins. Otherwise:

| Target | Default operation |
|--------|-------------------|
| Upstream-bound issue branch (fork mode, issue from upstream) | **rebase** — clean linear history for PR review |
| Origin-only issue branch (fork mode, issue from origin only) | **merge --no-ff** |
| Own-repo issue branch | **merge --no-ff** |
| Personal base branch (`mine`) | **merge --no-ff** |

Before rebasing, check `CONTRIBUTING.md`, `.github/CONTRIBUTING.md`, and
`.github/PULL_REQUEST_TEMPLATE.md` for upstream conventions. If they specify
a different integration approach (e.g., "squash and merge only"), follow that
instead and tell the user what you found.

### Execute

```bash
# Preconditions
git diff --quiet && git diff --cached --quiet || { echo "Target worktree has uncommitted changes"; exit 1; }

git fetch "$SOURCE_REMOTE"   # upstream or origin as appropriate

# Merge
git merge --no-ff "$SOURCE_REF"

# Rebase
git rebase "$SOURCE_REF"
```

On conflicts: stop, report the files, leave the repo in the conflict state for
the user to resolve. Do not invoke `--abort` automatically.

After a successful rebase, if the branch has been pushed previously, warn the
user that the next push will require `--force-with-lease`.

### Post-sync upstream audit

When the sync target is the default branch (or a personal base branch
that tracks the default) AND the sync brought in new commits AND the
repo uses the fork-local TODO pattern (`.claude/TODO.md`): audit the
new commits against the TODO before continuing with downstream work
(merging into a personal base, rebasing PR branches, etc.).

The point: keep the TODO and the open PR branches honest about what
upstream just established. A merged-upstream PR shouldn't still be in
the "watched" list; a planned-work item conditional on an upstream
merge may have just unblocked.

Capture the previous tip of the target branch before the sync (or
derive from `@{1}`), then list what came in:

```bash
git log @{1}..HEAD --oneline             # all new commits
git log @{1}..HEAD --merges --oneline    # merges (carry PR refs)
```

For each new commit, especially merges referencing `(#NNN)`, walk
`.claude/TODO.md` and reconcile:

| TODO entry refers to PR #NNN as ... | Action when #NNN just merged |
|---|---|
| **Watched PR we own** | Close the entry. Local branch + worktree are cleanup candidates (Operation 5). |
| **Watched PR we don't own** | Close the entry. The merged behavior is now in our base; verify it matches expectations. |
| **Planned work waiting on #NNN** | Item just unblocked (or was completed by the merge). Update state. |
| **Planned work to "extend #NNN"** | Re-evaluate scope — the base shifted. |
| **PR branch of ours that overlaps** | Subsequent rebase may produce an empty branch (work subsumed). Close those PRs. |

#### Watch for un-cited equivalent work

PR-reference matching is necessary but **not sufficient**. Upstream
maintainers sometimes implement a tracked PR's idea independently,
or merge it with substantial modifications, without citing the
original PR. A watched PR can remain `state: OPEN` in `gh` while its
underlying ask has already shipped in a different commit.

For each new non-merge commit (and each merge commit whose body
doesn't cite a PR we're tracking), skim its diff and message
against `.claude/TODO.md` entries by *topic*, not just PR number:

- Same file(s) touched as a tracked PR's diff → check whether the
  change overlaps that PR's intent.
- Commit subject/body mentions a feature, fix, or function name
  also named in a TODO entry → flag for human review.
- An entry phrased as "we want feature X" where X just appears in
  the commit log → likely just shipped, even if not by the PR
  we'd been watching.

When in doubt, surface the candidate to the user with both the
commit and the TODO entry, and let them decide whether to close or
keep watching. False positives are cheap (a quick "no, that's
different"); a missed equivalent is expensive (we keep watching a
PR whose ask has already shipped, or we duplicate work).

This is one-time per sync, not an ongoing watch. Surface findings to
the user as a short summary before continuing into rebase/merge work
downstream.

---

## Operation 3: Cross-branch integration

Triggered by: "merge issue321 into mine", "pull issue456 into my branch",
"rebase mine on issue321", etc.

### Resolve worktree paths

```bash
git worktree list --porcelain
```

Parse output to map branch → worktree path. If target branch has no worktree,
stop and ask whether to add one or check it out somewhere.

### Execute

1. Verify target worktree is clean
2. cd to target worktree
3. Apply merge-vs-rebase decision from Operation 2 based on the target branch type
4. Use `--no-ff` on merges so the integration point stays visible in history
5. Report result

Cross-branch merges into a personal base especially benefit from `--no-ff`
— it keeps the per-issue grouping readable in `git log`.

---

## Operation 4: Prep for PR

Triggered by: "ready to submit", "prep the PR", "get this ready for a PR",
etc.

### Steps

1. Verify current worktree is clean
2. Sync with the correct base (Operation 2 logic)
3. **Squash development noise to a clean commit set.** Per
   `rules/gh.md` — *Commit hygiene*: a PR goes up as a small,
   logically-grouped commit set, not the raw development
   history. Run `git rebase -i <base>` (typically
   `upstream/$DEFAULT_BRANCH`) and consolidate. Skip this step
   only if the branch already presents a tidy story.

   Show the proposed squash plan to the user before executing
   the rebase — the choice of how granular to keep things (one
   total commit vs. one per logical area) is a judgement call
   that benefits from explicit confirmation.

4. Run any project-standard checks if obvious from the repo
   (tests, linters) — but do not guess; if unclear, ask the
   user whether to run them
5. Push to origin:

   ```bash
   # Detect whether branch has been pushed before
   if git rev-parse --verify "refs/remotes/origin/${BRANCH_NAME}" >/dev/null 2>&1; then
       PREVIOUSLY_PUSHED=true
   fi
   ```

   - If rebase (or squash) just ran OR `PREVIOUSLY_PUSHED=true` with
     diverged history: warn user, then
     `git push --force-with-lease --force-if-includes -u origin "$BRANCH_NAME"`
   - Otherwise: `git push -u origin "$BRANCH_NAME"`
6. Determine target: in fork mode with upstream issue, PR targets `${UPSTREAM_SLUG}:${DEFAULT_BRANCH}`. In own-repo mode, PR targets `${ORIGIN_SLUG}:${DEFAULT_BRANCH}`.
7. Offer to run `gh pr create` — but only after confirming PR title and body with the user

Don't auto-create the PR without confirmation. Creating a PR is a user-facing action against a public repo and deserves an explicit nod.

The same squash-then-push step applies for follow-up pushes during
review — when the author addresses review comments, the response
should be integrated into the original commit set rather than
appended as "address review feedback" fix-up noise.

---

## Operation 5: Cleanup

Triggered by: "issue N is done", "clean up issue N", "remove the worktree for
X", etc.

### Preconditions

1. User is NOT currently inside the worktree being removed:

   ```bash
   # Use git rather than pwd — pwd can differ from toplevel due to symlinks or subdirectory CWD
   [[ "$(git rev-parse --show-toplevel 2>/dev/null)" != "$WORKTREE_PATH" ]]
   ```

2. Worktree has a clean tree
3. Branch's PR status — use `gh pr list --head "$BRANCH_NAME"` to check if there's an open/merged PR; warn if no merged PR is found but don't block

### Execute

```bash
git worktree remove "$WORKTREE_PATH"
git branch -d "$BRANCH_NAME"   # -d refuses unmerged; upgrade to -D only with user confirmation
git worktree prune              # remove stale metadata for any manually deleted worktree dirs
```

If `git branch -d` fails because commits aren't merged, report clearly and ask
whether to force-delete. Never force-delete silently.

After local cleanup, check for a remote branch and offer to delete it:

```bash
if git ls-remote --exit-code --heads origin "$BRANCH_NAME" >/dev/null 2>&1; then
    REMOTE_BRANCH_EXISTS=true
fi
```

If the remote branch exists:

- Note whether GitHub auto-deleted it already (check if the ref just
  disappeared since `git fetch` earlier in this operation).
- Ask the user: "Remote branch `origin/$BRANCH_NAME` still exists. Delete
  it?" — never delete silently.
- If confirmed: `git push origin --delete "$BRANCH_NAME"`

---

## Operation 6: Housekeeping

Triggered by: "list worktrees", "show worktrees", "prune worktrees", "what's
the state of my worktrees", etc.

```bash
git worktree list              # basic listing
git worktree list --porcelain  # parseable
git worktree prune             # clean up metadata for directories that were manually deleted
```

Recovery cases the skill should recognize:

- **Directory exists but git doesn't know about it** — not a worktree, just a stray directory. Report and let user decide.
- **Git tracks a worktree but directory is gone** — `git worktree prune` fixes this.
- **Branch exists but no worktree** — offer to add a worktree or leave as-is.
- **Worktree exists, branch was deleted** — worktree is in detached HEAD. Report state; usually means removing the worktree.

---

## Operation 7: Reconcile gone branches

Triggered by: "reconcile gone branches", "clean up gone branches", "prune
local branches whose remote is gone", "remove the [gone] branches", etc.

The bulk counterpart to Operation 5. After PRs merge and their remote branches
are deleted — and the targeted `git branch -dr origin/<branch>` prune from
`git.md` runs, or GitHub auto-deletes — the local branches that tracked them
show as `[gone]`. This sweeps them, and their worktrees, with the **same
guards** as Operation 5: confirm each deletion, skip dirty worktrees, never
bulk-`--force`.

It does **not** run `git fetch --prune` (this repo prunes remote-tracking refs
targeted, per `git.md`); it reconciles whatever `[gone]` state already exists.
Note: with squash merges (this repo's only merge method) a merged branch is
**not** an ancestor of the default branch, so `git branch -d` will refuse it —
the **merged-PR** check is the reliable "safe to delete" signal, after which
deletion needs a confirmed `-D`.

### Step 1: Detect (read-only)

```bash
mapfile -t GONE < <(
  git for-each-ref --format='%(refname:short) %(upstream:track)' refs/heads/ \
    | awk '$2 == "[gone]" { print $1 }'
)
((${#GONE[@]})) || echo "No [gone] branches — nothing to reconcile."

CURRENT=$(git rev-parse --abbrev-ref HEAD)
DEFAULT=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null \
            | sed 's@^refs/remotes/origin/@@')

for b in "${GONE[@]}"; do
  wt=$(git worktree list --porcelain \
         | awk -v ref="refs/heads/$b" \
             '/^worktree /{p=substr($0,10)} $0=="branch "ref{print p; exit}')
  if [[ -n $wt && -n $(git -C "$wt" status --porcelain) ]]; then
    wtstate="DIRTY worktree ($wt) — skip"
  elif [[ -n $wt ]]; then
    wtstate="clean worktree ($wt)"
  else
    wtstate="no worktree"
  fi

  pr=$(gh pr list --head "$b" --state merged --json number \
         -q '.[0].number' 2>/dev/null)
  prstate=${pr:+PR #$pr merged}

  printf '  %-28s %s; %s\n' "$b" "$wtstate" "${prstate:-no merged PR — verify}"
done
```

### Step 2: Present and confirm

Show the list, then exclude from any offer:

- the **current branch** (`$CURRENT`) and the **default branch** (`$DEFAULT`);
- branches with a **DIRTY worktree** — skipped (clean-tree precondition);
  report them so the user can deal with the changes first.

Default the proposed set to branches with a **merged PR** and a clean (or no)
worktree. Call out any **"no merged PR"** branch explicitly — those need a
deliberate decision. Never delete silently.

### Step 3: Remove (guarded, per confirmed branch)

```bash
# For each CONFIRMED $b (never $CURRENT / $DEFAULT, never a dirty worktree):
[[ -n $wt ]] && git worktree remove "$wt"   # no --force; refuses dirty/locked
git branch -d "$b"                          # refuses unmerged…
# …which squash-merged branches are. With a confirmed merged PR, upgrade to
#   git branch -D "$b"   — only after the user OKs that specific branch.
git worktree prune                          # tidy metadata once, at the end
```

If `git worktree remove` or `git branch -d` refuses, report and ask — a dirty
worktree is left untouched, and `-D` is used only with explicit per-branch
confirmation.

---

## Rules and defaults

- **Never hardcode `main` or `master`.** Always derive from the appropriate remote's default.
- **Never invent a default branch** if upstream doesn't have one. Stop and ask.
- **`--no-ff` on all merges** unless the user explicitly overrides. Keeps history legible.
- **Rebase for upstream-bound PR branches** unless upstream's CONTRIBUTING.md says otherwise.
- **Merge (`--no-ff`) for personal/own-repo branches** — preserves the story of integration points.
- **Never force-push without `--force-with-lease`.** Even then, warn first.
- **Never force-delete a branch silently.** Always confirm.
- **Preconditions matter:** clean tree before sync, prep, or cleanup. Report and stop on violations.
- **Ambiguity → ask.** If source, target, or verb is unclear, one clarifying question beats a wrong action.
- **Never create the PR automatically** — confirm title/body with the user first.
- **`gh` calls are cheap** — re-resolve issue source rather than caching across sessions.

## Common trigger phrases and mappings

| User says | Operation |
|-----------|-----------|
| "work on issue 321" / "let's tackle 321" / "open issue 321" | Operation 1 |
| "sync this" / "update this branch" / "pull in main" | Operation 2 |
| "rebase on main" / "merge main into this" | Operation 2 (verb override) |
| "merge issue321 into mine" / "pull X into Y" | Operation 3 |
| "ready to submit" / "prep for PR" | Operation 4 |
| "issue 321 is done" / "clean up 321" | Operation 5 |
| "list worktrees" / "prune worktrees" | Operation 6 |
| "reconcile gone branches" / "clean up gone branches" | Operation 7 |

## When to ask vs proceed

Proceed without asking when:

- Trigger is clear and arguments are unambiguous
- Preconditions are met
- Operation is reversible or low-risk (fetch, listing, adding a worktree)

Ask first when:

- Source or target branch is ambiguous
- Tree is dirty and operation needs clean state
- About to force-delete or force-push
- About to create a PR
- About to run project checks whose command isn't obvious
- Worktree state doesn't match expectations (different branch, unexpected files)
