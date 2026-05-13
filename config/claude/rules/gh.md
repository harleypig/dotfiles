---
# No paths — applies to all PRs and issues regardless of file type.
---

# gh (GitHub CLI) Rules

**Version:** v1.0.0

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

## Authentication

This user maintains **two** credentials for `gh`, deliberately:

- **`GH_TOKEN` / `GITHUB_TOKEN` env vars** — a narrowly-scoped
  fine-grained PAT exported from the user's shell environment. This is
  the default credential and serves nearly every gh operation in the
  user's normal workflow. Many of the user's scripts and tools also
  read these env vars; do not assume the PAT can be removed or
  widened.
- **Stored OAuth credential** — broader-scope token saved by
  `gh auth login`, stored at `$DOTFILES/config/gh/hosts.yml`. Reserved
  as a fallback for operations the narrow PAT can't reach
  (commenting on upstream PRs, filing issues against other orgs, and
  similar third-party-repo writes).

`gh` precedence: `GH_TOKEN` > `GITHUB_TOKEN` > stored credential. As
long as either env var is set, the stored credential is ignored.

### Default: use the PAT (no prefix)

Run `gh` commands normally. The env-var PAT will be used.

```bash
gh pr list
gh repo view --json parent
gh pr create --title "..." --body "..."
```

### Fallback: bypass env vars only when the PAT can't do it

Some `gh` calls will fail because the narrow PAT lacks scope for the
target repo. Typical error:

```
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

**Never `unset GH_TOKEN GITHUB_TOKEN` in the shell session itself.**
The env-var PAT is load-bearing for other tools the user runs.

### Diagnosing further

If the prefixed call also fails, the OAuth credential is the problem,
not the PAT. Check its scopes:

```bash
GH_TOKEN= GITHUB_TOKEN= gh auth status
```

If scopes are insufficient, `gh auth refresh -s <scope>` adds them
without re-doing the full login.

## Agent Rules

- Always return the PR URL after creating.
- Use `gh` for all GitHub operations (issues, PRs, checks, releases).
- Do not create, merge, or close PRs without explicit user approval.
- Use `gh pr view`, `gh issue list`, etc. to check state before acting.
- For full PR prep workflow (sync, push, create), use the
  **git-worktree-workflow** skill (Operation 4).
- In fork mode, PRs target the upstream repo, not origin. Derive the
  correct target from `gh repo view --json parent`.
- Default to running `gh` commands without any prefix. Only fall back
  to `GH_TOKEN= GITHUB_TOKEN= gh ...` when a call fails with a
  scope/permission error the env-var PAT can't satisfy. See
  *Authentication* above.
