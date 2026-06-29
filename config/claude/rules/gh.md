---
# No paths — applies to all PRs and issues regardless of file type.
---

# gh (GitHub CLI) Rules

**Version:** v1.3.0

## Pull Requests

**Title:** under 72 characters; describe the change, not the implementation.

**Body format:**

```markdown
## Summary
- Bullet points describing what changed and why (1–3 items)

## Test plan
- [ ] Checklist of how to verify the change works
```

Create with:

```bash
gh pr create --title "title" --body "$(cat <<'EOF'
## Summary
- ...

## Test plan
- [ ] ...
EOF
)"
```

## Commit hygiene

PRs go up as a small, logically-grouped commit set — not the raw
development history. Reviewers shouldn't have to wade through 40
fine-grained "add test for X", "fix typo", "respond to my own review"
commits to follow what's actually being proposed.

Before opening a PR (and before requesting re-review after substantive
changes):

- Squash development noise — typos, intermediate states, `wip` /
  `fixup` commits, follow-ups to your own self-review — into the
  related substantive commit.
- **Single-theme PR** (e.g., one bug fix): aim for one commit.
- **Multi-theme PR** (e.g., test coverage across several packages):
  group by theme — one commit per logical area — so each area's diff
  is independently reviewable.
- Every surviving commit should compile, pass tests on its own, and
  carry a meaningful message.

Use `git rebase -i <base>` (typically `upstream/main`) to consolidate;
mark non-substantive commits as `fixup` or `squash`. After squashing,
push with `--force-with-lease --force-if-includes`. Warn the user
before that push if anyone else may have pulled the branch.

Don't squash blindly to a single commit when a PR genuinely covers
multiple independent areas — that loses reviewability. The goal is a
"tidy story," not "minimum commit count."

Squashing applies equally to a first push and to follow-ups during
review: when the author addresses review comments, the response
should be integrated into the original commit set rather than appended
as `fixup commit 1, fixup commit 2, ...` noise.

## Authentication

This user maintains **two** credentials for `gh`, deliberately:

- **`GH_TOKEN` env var** — a single **wide-open** PAT exported from the
  user's shell environment (loaded by `config/shell-startup/000-loadtokens`
  from `private_dotfiles/api-key/gh`). This is the default credential and
  is intentionally broad so gh works for anything in the user's normal
  workflow. **`GITHUB_TOKEN` is deliberately left unset** — gh falls
  straight through to `GH_TOKEN`. (Per-app tools such as the MCP servers
  in `bin/mymcp` do **not** use these env vars; they read their own
  narrowly-scoped tokens directly from `private_dotfiles/api-key/`.)
- **Stored OAuth credential** — token saved by `gh auth login`, stored at
  `$DOTFILES/config/gh/hosts.yml`. Reserved as a fallback for operations
  the env-var PAT can't reach (commenting on upstream PRs, filing issues
  against other orgs, and similar third-party-repo writes — a fine-grained
  PAT only reaches repos explicitly granted to it).

`gh` precedence: `GH_TOKEN` > `GITHUB_TOKEN` > stored credential. With
`GITHUB_TOKEN` unset, gh uses `GH_TOKEN`; clearing it too (the fallback
prefix below) drops gh to the stored OAuth credential.

### Default: use the PAT (no prefix)

Run `gh` commands normally. The env-var PAT will be used.

```bash
gh pr list
gh repo view --json parent
gh pr create --title "..." --body "..."
```

### Fallback: bypass env vars only when the PAT can't do it

Some `gh` calls will fail because the env-var PAT can't reach the
target repo — even a wide-open fine-grained PAT only covers repos
explicitly granted to it, so upstream/third-party repos are out of
reach. Typical error:

```text
GraphQL: Resource not accessible by personal access token
```

or HTTP 403 on the relevant endpoint. When that happens, retry with
the env vars cleared for that single command:

```bash
GH_TOKEN= GITHUB_TOKEN= gh pr comment 281 --repo packwiz/packwiz --body "..."
```

The empty assignments unset the variables **for that one command
only**, leaving the shell environment intact. Use this prefix when:

- The error message indicates a permission/scope problem and the
  target is a repo the PAT clearly can't write to (upstream, third-
  party org, etc.).
- A previously-working command starts failing with the same scope
  error after a refactor or repo move.

**Never `unset GH_TOKEN` in the shell session itself.** It is the
load-bearing credential for gh and other tools the user runs; clear it
only inline for a single command (the prefix above).

### Diagnosing further

If the prefixed call also fails, the OAuth credential is the problem,
not the PAT. Check its scopes:

```bash
GH_TOKEN= GITHUB_TOKEN= gh auth status
```

If scopes are insufficient, `gh auth refresh -s <scope>` adds them
without re-doing the full login.

## Issues & triage

When a repo has **automation that opens issues** (e.g. a nightly security
scan that files a findings issue), those issues are only useful if someone
looks at them. So, **at the start of git/gh work in such a repo (and at least
daily)**, check for open issues and surface them:

```bash
gh issue list --state open
gh issue list --state open --label dast   # e.g. auto-filed scan findings
```

Triage is more than "fold into the TODO." Reconcile each issue **against what
the repo already has** before routing it:

- **Reconcile against the planning docs *and* current code** — match it to an
  existing `TODO`/`ROADMAP`/`ICEBOX` item (cross-reference, don't duplicate;
  several issues may bunch onto one task), and check whether the code already
  satisfies it.
- **Stale/done → close with a comment** saying what satisfied it (never a
  silent close).
- **Score complexity** (trivial/small/medium/large) for each open issue —
  reporting only; it does **not** trigger auto-work.
- **Detect duplicates/umbrellas** and **blocking chains** (`Blocked by #N`);
  order the queue so blockers come first.
- **Recommend labels** — apply the right one; when the right label doesn't
  exist, recommend creating it rather than forcing a poor fit.
- **Keep issue ↔ planning-doc references in sync** (issue # in the item; a
  comment on the issue linking the item/PR).
- **Never auto-tackle** — present the worklist and ask; acting on an issue is
  a separate, routed step.

Route each to a disposition (close-done / map-to-TODO / icebox+close / roadmap
/ features-&-fixes / flag-for-decision). Don't let auto-created issues pile up
unseen; a closed/empty queue is the goal.

The **github-issues** skill is the procedure for the above (per-issue depth);
the **github-tasks** skill is the forcing function for the *cadence* — it runs
the issue check as one part of a wider repo sweep (Dependabot PRs, failing
checks, stale branches, release/tag hygiene) and **delegates issue triage to
github-issues**. Reach for github-tasks at the start of git/gh work rather than
running the `gh issue list` calls above piecemeal.

## Agent Rules

- After creating a PR, follow the CI monitoring workflow in
  `github-actions.md` if Actions are configured in the repo.
- Check `gh issue list` at the start of git/gh work (and daily); triage per
  *Issues & triage* — reconcile against planning docs + code, score complexity,
  close stale/done with a comment, route the rest, and **never auto-tackle**.
  Use the **github-issues** skill for the per-issue procedure and the
  **github-tasks** skill to run it as part of a single repo sweep.
- Always return the PR URL after creating.
- Use `gh` for all GitHub operations (issues, PRs, checks, releases).
- Do not create, merge, or close PRs without explicit user approval.
  Invoking the **ship-pr** skill (or an explicit "open a PR" / "ship it"
  request) **is** approval to create and push the PR; **merge and close still
  require their own separate explicit instruction**, never inferred from the
  create approval.
- Use `gh pr view`, `gh issue list`, etc. to check state before acting.
- For full PR prep workflow (sync, push, create), use the
  **git-worktree-workflow** skill (Operation 4).
- In fork mode, PRs target the upstream repo, not origin. Derive the
  correct target from `gh repo view --json parent`.
- Default to running `gh` commands without any prefix. Only fall back
  to `GH_TOKEN= GITHUB_TOKEN= gh ...` when a call fails with a
  scope/permission error the env-var PAT can't satisfy. See
  *Authentication* above.
- For **branch/tag protection rulesets** — the rule-type catalog, the
  three ruleset kinds, availability constraints (push/file rules need a
  private/internal repo; org rulesets need an org), and the decision lens
  for which rules actually add value — see `github-rulesets.md`. Concrete
  ruleset JSON lives in `../private_dotfiles/github-rulesets/`.
