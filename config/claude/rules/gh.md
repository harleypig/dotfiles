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

## Agent Rules

- Always return the PR URL after creating.
- Use `gh` for all GitHub operations (issues, PRs, checks, releases).
- Do not create, merge, or close PRs without explicit user approval.
- Use `gh pr view`, `gh issue list`, etc. to check state before acting.
- For full PR prep workflow (sync, push, create), use the
  **git-worktree-workflow** skill (Operation 4).
- In fork mode, PRs target the upstream repo, not origin. Derive the
  correct target from `gh repo view --json parent`.
