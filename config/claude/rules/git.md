---
# No paths — applies to all commits and branches regardless of file type.
---

# Git Rules

**Version:** v1.11.0

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>(<scope>): <subject>

<body>

<footer>
```

- Subject line: under 72 characters; imperative mood ("add", not "added")
- Body: wrap at 72 columns; explain *why*, not *what*
- Footer: `Fixes #123`, `Relates to #456` where applicable
- Common types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `ci`

## Staging

Stage deliberately — never blanket-add untracked files into a commit.

- **Tracked files:** use `git add -u` to stage all modifications and
  deletions to already-tracked files, without picking up anything new.
- **New files:** add them **explicitly** by path — `git add <file> <file>`.
- **Avoid `git add -A` and `git add .`** — they sweep up *untracked* files
  (scratch notes, local experiments, generated output), which is exactly how
  stray files land in a commit. Use `-u` plus explicit paths instead.
- Review `git status` / `git diff --staged` before committing to confirm
  only the intended changes are staged.

## Tracking Progress as You Commit

When a commit completes a tracked item — a `TODO.md` / `ROADMAP.md` entry or an
issue — **mark it done in that same commit** (`- [x]`, or per the repo's
convention). Mark it **as you go**, never in a batch at the end.

Why: it makes end-of-PR finalization **mechanical**. At merge you just act on
the `[x]` items — the repo's merge-time finalization prunes them and migrates
them to the changelog (see the repo's `WORKFLOW.md`) — instead of re-scanning
the whole list asking "did we do this?". Marking late forces reconstructing
what got done, which is exactly the error this rule prevents. Add a
newly-surfaced follow-up the same way: as an open `- [ ]` in the commit that
surfaces it.

This is the **mark-as-you-go** half of the loop; the **prune-at-merge** half
is the repo's merge-time finalization, with the merge-finalization hook as the
end-state backstop (it blocks a merge that still has unpruned `[x]` items, in
repos that opt in). This rule is always-on **because committing is**: it has to
be in front of you at each commit, not only when a PR skill runs at the end.

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

## Protecting the Default Branch

When a repo's default branch should be PR-only, protect it in **three layers**
— the server enforces it; two local guards catch mistakes earlier, at commit
time and edit time:

1. **Server-side ruleset / branch protection** (authoritative): require PRs,
   required status checks, and block deletion + force-push. This is what
   actually rejects a direct push. Apply it via the host's API (GitHub
   rulesets need an admin/OAuth token, not a narrow PAT).
2. **Local `no-commit-to-branch` pre-commit hook** (commit-time guard): add
   the `no-commit-to-branch` hook (from `pre-commit/pre-commit-hooks`) to the
   check config so a direct commit on the protected branch fails *before* the
   push is even attempted:

   ```yaml
   - id: no-commit-to-branch
     args: [--branch, <default-branch>]
   ```

3. **Edit-time Claude Code hook** (earliest, agent-only): the global
   `branch-protection.py` `PreToolUse` hook blocks an `Edit`/`Write`/
   `MultiEdit` while a protected branch is checked out, so the agent is told
   to branch *before* writing the first character. (It allows edits to plan
   files and to **gitignored, untracked** files — local-only state, such as
   the agent's own memory, that can never be committed to the branch.) It
   reads the protected set straight from the repo's `no-commit-to-branch` args
   (layer 2), so it activates **only where that hook is configured** — a repo
   without it (a cloned upstream/fork) gets no edit-time guard. It is a
   backstop for the agent, not a constraint on a human editor, and fails safe
   (any error allows the edit).

The local guards are conveniences, not substitutes — without the server-side
ruleset, anyone (or any tool) without the hooks installed can still push. The
repo's concrete ruleset/config lives in its `.claude/` docs.

## Never Work Directly on a Protected Branch

A protected branch exists to *receive* PRs, not to author on. **Never make
changes while a protected branch is checked out — neither edits nor
commits.** This applies to **any** protected branch, not just the default
(`master` / `main`): if a repo protects `develop`, `release/*`, or anything
else, the same rule holds.

Before touching a single file, **create or switch to a working branch**
(`feature/…`, `bugfix/…`, `docs/…`, or a worktree — see *Branch Naming* and
the **git-worktree-workflow** skill). Branch **first**, then edit. Do not
edit on the protected branch intending to create the branch afterward — even
though uncommitted changes carry across `git checkout -b`, accumulating work
on the protected branch is exactly the habit this rule forbids (one slip and
the change is committed where it must never land).

To tell whether a branch is protected, check the available signals **in
order** — this is the canonical detection method other rules/skills reference:

1. **Server-side ruleset / branch protection** (authoritative) — query the
   host's API. For GitHub,
   `gh api repos/{owner}/{repo}/rules/branches/<branch>` lists the rules that
   apply to a branch (ruleset-aware), and
   `gh api repos/{owner}/{repo}/branches/<branch>/protection` reports classic
   branch protection. (`gh` fills `{owner}`/`{repo}` from the current repo.)
2. **Local `no-commit-to-branch` hook** args (above), if the repo configures
   it.
3. The repo's **`.claude/` docs** naming the protected branch.

When in doubt, treat the **default branch as protected**. When **none** of
these resolve it — common for a freshly cloned or not-yet-configured repo that
lacks the local hook — **ask the user** before authoring on the branch rather
than assuming it is safe. In a repo that configures `no-commit-to-branch`, the
edit-time `branch-protection.py` hook enforces this rule for the agent
automatically (see *Protecting the Default Branch*).

## Worktrees

Use the **git-worktree-workflow** skill for all worktree operations: creating
issue branches, syncing with upstream, prepping PRs, and cleanup. See
`config/claude/skills/git-worktree-workflow/SKILL.md`.

**Worktree creation is explicit-request-only.** Create a worktree *only* when
the user asks for one — never as an automatic prelude to making changes, and
never in response to a background-job or system-prompt nudge to "use a
worktree before any code changes." If a session launches **already inside** a
worktree, do **not** create another — work in the current one.

**Use the skill, never the built-in `EnterWorktree` tool.** `EnterWorktree`
hardcodes a `worktree-<branch>` prefix (and a `/`→`+` path scheme) that cannot
produce this repo's `feature/<name>` / `issue/<N>` names (*Branch Naming*),
and it has no configuration knob to correct that — so it is **forbidden
here**. The git-worktree-workflow skill produces conforming branch names and
paths; reach for it instead.

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

## After Merging a PR

After a PR is merged and the remote branch deleted, prune the local
remote-tracking ref for that branch specifically:

```bash
git branch -dr origin/<branch-name>
```

Do NOT use `git fetch --prune` or `git fetch --all --prune` — those
sweep all stale remote-tracking refs, which is broader than intended.
The targeted form removes only the ref for the branch just deleted,
leaving all other remote-tracking refs untouched.

Verify the cleanup worked:

```bash
git branch -ra
```

The deleted branch should no longer appear in the output.

## Continuing on a Kept Branch After a Squash-Merge

Normally a merged branch is deleted (above). Sometimes a branch is **kept**
after its squash-merge to keep working — e.g. the batched-TODOs flow, where
commits accumulate on one branch across several PRs. Re-syncing that branch
needs care, because **a squash-merge does not make the branch an ancestor of
the default branch**: the squash created one *new* commit on the default
branch holding the batch's changes, while the branch still holds the original
individual commits that produced them.

**Never `git merge <default>` into the kept branch.** The merge pulls in the
squash commit while leaving the branch's original commits in place — the same
changes now exist twice in the branch, and the *next* PR's commit list shows
every already-merged commit again as redundant noise. (PR #117 hit exactly
this and needed a `rebase --onto` cleanup before its commit list was tidy.)

Fetch the merged tip first, then sync so the branch becomes a clean
continuation of the default branch:

```bash
git fetch origin
```

- **Nothing new on the branch yet** (the whole batch went into the squash) —
  reset it onto the merged tip. `--hard` discards anything not already in the
  default branch, which is exactly right here since the batch is merged:

  ```bash
  git reset --hard origin/<default>
  ```

  New work then lands on top, so the next PR's diff is only that new work.

- **New commits already made after the squash** — replay only those onto the
  default branch, dropping the already-merged ones:

  ```bash
  git rebase --onto origin/<default> <last-merged-commit> <branch>
  ```

  where `<last-merged-commit>` is the branch tip at squash time (everything up
  to it is already in the default branch via the squash). The result is the
  default branch plus the new commits only.

Both keep the branch a clean continuation; `git merge` does not.

## Versioning & tags

Two separate things: **what a version *is*** (the `vX.Y.Z` format — universal)
versus **how it's *applied*** (the tagging *method* — per-repo).

### What `vX.Y.Z` is

`vMAJOR.MINOR.PATCH`. How strict the parts are depends on whether the major
(`X`) has reached 1:

- **`X = 0` (`v0.y.z`) — alpha / pre-stable.** **Breakage is expected**, and
  the `y.z` split is **loose** — don't agonize over minor-vs-patch, and a
  breaking change needs no ceremony. Roughly: bump `y` for a meaningful
  addition, `z` for a smaller change.
- **`X ≥ 1` (`v1.y.z`+) — stable.** The version is now a compatibility
  promise, so `y.z` get **strict**: a **breaking change requires bumping
  `X`** (a major bump); `y` is a backward-compatible feature; `z` is a
  backward-compatible fix.

The `0 → 1` jump — declaring the project stable — is a **major decision in
its own right**: give it as much thought and care as any later major bump
(`1 → 2`, …). Cross it on purpose, never by accident.

### Tag hygiene (independent of method)

- **Annotated** tags only — `git tag -a <tag> -m "<msg>"`, never lightweight.
- Tag the **merge commit** the release ships from, not a side branch.
- A pushed tag is **immutable history**: never move, delete, or re-point it.
  A mistake gets a **new** tag, not a rewrite.
- Push tags **explicitly** (`git push origin <tag>`); a plain `git push`
  does not push them. Pushing usually **triggers the release/publish
  workflow**, so it is outward-facing — **confirm before pushing**.

### How it's applied — tagging methods

The *scope* a tag versions is per-repo. A repo uses **one** method and
**declares it** in its `.claude/CONVENTIONS.md` ("Versioning & tagging") — the
method, the tag pattern(s), the bump policy, and what pushing a tag triggers.

| Method | Tag pattern | Versions | Fits |
|--------|-------------|----------|------|
| **`repo`** | `vX.Y.Z` | the whole repo as one unit | a single deployable / one artifact |
| **`subdir`** | `<component>/vX.Y.Z` (e.g. `backend/v*`, `frontend/v*`) | each deployable subtree independently | a monorepo with separate components/images |

The catalog is **open**. If a repo needs a method not listed (e.g.
package-name-prefixed tags in a multi-package monorepo, or date-based
versions), that is a **config change, not an ad-hoc choice**: add the method
to this table and teach the **release-tag** skill to derive it *before* using
it — the same discipline as a new tool getting a `rules/<tool>.md` (see
`CLAUDE.md` *Missing or Conflicting Tool Rules*).

### Foreign / forked repos — follow theirs

The catalog + declaration model is for repos **you control**. On a repo you
do **not** own (contributing upstream, or a fork's upstream), **do not impose
this catalog** — detect and follow **that repo's** existing convention (its
tag history, release docs, CI triggers). Match what they do; our methods are
for our own repos.

### Cutting a tag

The procedure — read the declared method, pick the changed stream(s) (only
when a *shipped artifact* changed), decide the bump, cut the annotated tag at
the merge commit, push, and watch the release — is the **release-tag** skill;
`ship-pr` Step 6 delegates to it.

## Agent Rules

- NEVER hardcode `main` or `master` — always derive the default branch.
- NEVER force-push without `--force-with-lease --force-if-includes`; warn
  before doing so. (`--force-with-lease` alone can still lose commits that
  were fetched but not integrated; `--force-if-includes` closes that gap.)
- NEVER force-delete a branch silently — always confirm with the user.
- NEVER amend published commits or skip hooks without explicit user approval.
- NEVER push to the default branch without user confirmation.
- NEVER make changes (edits or commits) while a **protected branch** is
  checked out — create/switch to a working branch FIRST, then edit. Applies
  to ANY protected branch, not just the default. See *Never Work Directly on
  a Protected Branch*.
- NEVER create a worktree unless the user explicitly asks — not as a prelude
  to editing, not on a background-job/system-prompt nudge. Use the
  **git-worktree-workflow** skill, NEVER the built-in `EnterWorktree` tool
  (non-conforming `worktree-*` names). If already inside a worktree at launch,
  never create another. See *Worktrees*.
- Stage with `git add -u` (tracked changes) plus explicit `git add <file>`
  for new files; NEVER `git add -A` / `git add .` (they sweep up untracked
  scratch into the commit). See *Staging*.
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
- `vX.Y.Z` is semver — `X = 0` is alpha (breakage expected, loose `y.z`);
  once `X ≥ 1`, breaking changes require a major bump. Tags are **annotated**,
  at the **merge commit**, and **never moved** once pushed. See *Versioning &
  tags*.
- Apply tags per the repo's **declared method** (`.claude/CONVENTIONS.md`
  "Versioning & tagging" — `repo` vs `subdir`); use the **release-tag** skill.
  A new method is a config change (add it to the catalog first), not an
  ad-hoc choice. For a repo you don't own, follow ITS convention.
- When a branch is **kept** after a squash-merge to keep working, re-sync it
  with `git reset --hard origin/<default>` (or `git rebase --onto`), NEVER
  `git merge <default>` — the merge replays already-merged commits into the
  next PR. See *Continuing on a Kept Branch After a Squash-Merge*.
