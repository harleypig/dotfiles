---
name: git-worktree-workflow
description: Manage git worktree-based development for forked and personal repositories. Use this skill whenever the user wants to work on a GitHub issue, set up a worktree, sync a branch with its upstream base, prepare a branch for a PR, clean up a finished issue, merge or rebase between branches, or perform any operation involving git worktrees. Triggers on phrases like "work on issue #N", "let's tackle issue N", "start issue N", "merge main into X", "pull in upstream", "rebase X on main", "update this branch", "prep for PR", "clean up issue N", "remove the worktree for X", "list worktrees", or any request mentioning worktrees, issue branches, or cross-branch integration in a forked or personal repo context. Also use when the user references a directory like `issueN` as a sibling of the main repo clone.
---

# Git Worktree Workflow

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

```
~/projects/PROJECT/
    PROJECT/            base clone (origin + optional upstream remotes)
    issue321/           worktree for issue branch issue/321
    pr/feature-name/    worktree for branch pr/feature-name
    mine/               optional personal base branch worktree (fork mode only)
```

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

```
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
3. Run any project-standard checks if obvious from the repo (tests, linters) — but do not guess; if unclear, ask the user whether to run them
4. Push to origin:
   ```bash
   # Detect whether branch has been pushed before
   if git rev-parse --verify "refs/remotes/origin/${BRANCH_NAME}" >/dev/null 2>&1; then
       PREVIOUSLY_PUSHED=true
   fi
   ```
   - If rebase just ran OR `PREVIOUSLY_PUSHED=true` with diverged history:
     warn user, then `git push --force-with-lease -u origin "$BRANCH_NAME"`
   - Otherwise: `git push -u origin "$BRANCH_NAME"`
5. Determine target: in fork mode with upstream issue, PR targets `${UPSTREAM_SLUG}:${DEFAULT_BRANCH}`. In own-repo mode, PR targets `${ORIGIN_SLUG}:${DEFAULT_BRANCH}`.
6. Offer to run `gh pr create` — but only after confirming PR title and body with the user

Don't auto-create the PR without confirmation. Creating a PR is a user-facing action against a public repo and deserves an explicit nod.

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
