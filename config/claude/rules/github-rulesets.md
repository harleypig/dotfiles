---
# On-demand: auto-loads when a ruleset config JSON is being edited. The
# other trigger (deciding whether to add a ruleset while doing branch-
# protection / platform work) is covered by gh.md — always-on and pointing
# here — so the agent reads this reference when it actually touches a
# ruleset, rather than paying for it every turn.
paths:
  - "**/github-rulesets/**"
  - "**/*ruleset*.json"
---

# GitHub Rulesets Reference

**Version:** v1.0.0

A survey of what GitHub repository rulesets offer, which rules apply where,
the availability constraints that decide whether a rule is even an option,
and a decision lens for picking the few that earn their keep. This is the
**report** half; `gh.md` and `git.md` own the always-on *behaviour* (PR
conventions, protected-branch detection, the apply command). Concrete
ruleset JSON configs live outside the agent config — in
`../private_dotfiles/github-rulesets/` — with their own README.

## The three kinds of ruleset

A ruleset's **kind** is set by its `target` (or, for push rulesets, its
type). Pick the kind first; it determines which rules are even selectable.

| Kind | `target` | Governs | Availability |
|------|----------|---------|--------------|
| **Branch ruleset** | `branch` | refs under `refs/heads/*` — merges, pushes, history, required checks | Any repo, incl. **user-owned public** (proven: this is what protects `master`) |
| **Tag ruleset** | `tag` | refs under `refs/tags/*` — protect release tags from deletion / force-move | Any repo, incl. user-owned |
| **Push ruleset** | `push` | file content *as it is pushed* — path / extension / size limits | **Private or internal repos ONLY** — not available on public repos |

The push-ruleset restriction is the big gotcha: a **public** repo cannot
use file-path / file-extension / file-size push rules at all, regardless of
plan. For a public repo, the secret/large-file job falls to client-side
guards (pre-commit `gitleaks`, `detect-private-key`, a size hook) instead.

Org-owned repos additionally get **organization rulesets** that apply across
many repos at once (GitHub Team / Enterprise) — out of scope for the
user-owned repos here.

## Rule catalog

What each rule does and which kind(s) can carry it. Branch/tag share the
"protect the ref" rules; the merge/quality rules are branch-only; the file
rules are push-only.

### Ref-protection rules (branch + tag)

| Rule (`type`) | Effect |
|---------------|--------|
| `creation` | Restrict who can create matching refs |
| `update` | Restrict who can push to matching refs |
| `deletion` | Block deleting matching refs *(on by default)* |
| `non_fast_forward` | Block force-pushes *(on by default)* |
| `required_linear_history` | Reject merge commits (squash/rebase only) |
| `required_signatures` | Require signed, verified commits |

### Metadata rules (branch + tag)

Pattern-match the metadata of **every commit in the push**. Each takes an
`operator` (`starts_with` / `ends_with` / `contains` / `regex`) and a
`pattern`:

| Rule (`type`) | Matches |
|---------------|---------|
| `commit_message_pattern` | Each commit's message |
| `commit_author_email_pattern` | Author email |
| `committer_email_pattern` | Committer email |
| `branch_name_pattern` / `tag_name_pattern` | The ref name |

Caveat that shapes their usefulness: metadata rules gate **the commits as
pushed to the branch**, not the squash commit GitHub generates at merge. On
a squash-only repo the message that actually lands on the default branch is
authored at merge time and is *not* what these rules check — so using
`commit_message_pattern` to "enforce Conventional Commits" mostly just
rejects work-in-progress / `fixup!` commits on feature branches at push,
which fights the normal workflow rather than improving the merged history.

### Merge / quality rules (branch only)

| Rule (`type`) | Effect |
|---------------|--------|
| `pull_request` | Require a PR; sub-params set approvals, stale-review dismissal, thread resolution, **allowed merge methods** |
| `required_status_checks` | Named CI checks must pass before merge |
| `required_deployments` | Must deploy to named environments first |
| `code_scanning` | Gate merge on code-scanning alert thresholds |
| `workflows` | Require specific workflows to run *(organization repos)* |

### File rules (push rulesets — private/internal only)

| Rule (`type`) | Effect |
|---------------|--------|
| `file_path_restriction` | Block commits touching matching paths (≤200 entries) |
| `max_file_path_length` | Reject over-long paths |
| `file_extension_restriction` | Block matching extensions (≤200 entries) |
| `max_file_size` | Reject oversized files |

## Decision lens — which actually add value

Most rule types are **redundant, premature, or unavailable** for a small
solo/public repo. Before adding one, run it past these:

- **Already covered?** If squash-only merges are enforced, the history is
  already linear — `required_linear_history` adds nothing. If
  `non_fast_forward` + `deletion` + `pull_request` + `required_status_checks`
  are in place, the ref is already well protected.
- **Premature?** A **tag ruleset** only earns its place once the repo
  actually cuts release tags. A repo with **zero tags** that versions via a
  `CHANGELOG` has nothing to protect yet — defer it until the first tag, and
  couple it to the `release-tag` skill's first use there.
- **Not yet ready?** `required_signatures` blocks *every* commit until commit
  signing (gpg/SSH) is configured for all the accounts that push. Adopt it
  *with* the signing rollout, never before.
- **Available at all?** Push (file) rules need a **private/internal** repo —
  off the table for anything public. Org rulesets and `workflows` need an
  organization.
- **Friction vs. payoff?** `commit_message_pattern` for Conventional Commits
  reads tempting but gates feature-branch WIP commits while *not* gating the
  squash message that lands (see the metadata caveat) — net friction on a
  solo repo whose author already follows the convention.

The honest default for a solo, public, untagged, trunk-based repo is:
**the base branch ruleset is enough; add nothing speculative.** Re-open the
tag ruleset when tagging begins and `required_signatures` when signing lands.

## Applying a ruleset

Rulesets are JSON, applied via the REST API. Creating or editing them needs
an **admin-scoped** credential — the narrow PAT will 403; use the OAuth
fallback (`GH_TOKEN= GITHUB_TOKEN= gh ...`, per `gh.md` *Authentication*).

```bash
# List what's applied (read its id from here)
gh api repos/{owner}/{repo}/rulesets

# Create from a JSON file
gh api repos/{owner}/{repo}/rulesets --method POST --input <file>.json

# Update an existing ruleset (admin token)
GH_TOKEN= GITHUB_TOKEN= gh api repos/{owner}/{repo}/rulesets/{id} \
  --method PUT --input <file>.json
```

The `id` and `source_type` fields the API returns are read-only — never
include them in the input JSON. The reusable config templates and the
solo-vs-team / beta-prod variants live in
`../private_dotfiles/github-rulesets/` (see that README).

Example — a ready-to-apply **tag ruleset** that protects semver release tags
from deletion and force-moves (stage it when a repo starts tagging):

```json
{
  "name": "Protect Release Tags",
  "target": "tag",
  "enforcement": "active",
  "conditions": {
    "ref_name": { "include": ["refs/tags/v*"], "exclude": [] }
  },
  "rules": [
    { "type": "deletion" },
    { "type": "non_fast_forward" }
  ],
  "bypass_actors": []
}
```

## Sources

Grounded in the official GitHub rulesets docs (fetched 2026-06-26), not
memory — re-check when GitHub changes ruleset capabilities:

- Available rules for rulesets:
  <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets>
- About rulesets:
  <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/about-rulesets>
- Creating rulesets for a repository (push-ruleset private/internal note):
  <https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository>

## Agent Behavior

- Before proposing a ruleset rule, **check it against the decision lens** —
  most are redundant (linear history under squash-only), premature (tag
  ruleset with no tags), not-yet-ready (`required_signatures` before signing),
  or unavailable (push/file rules need private/internal; `workflows` needs an
  org). Surface the constraint instead of silently adding the rule.
- **Verify capability against the current docs**, never memory — GitHub
  changes ruleset features; the *Sources* above are the re-check list.
- Editing/creating a ruleset needs an **admin** credential: use the
  `GH_TOKEN= GITHUB_TOKEN= gh ...` OAuth fallback (`gh.md`) when the PAT 403s.
- Keep concrete ruleset JSON in `../private_dotfiles/github-rulesets/`, not in
  the agent config; this file is the rule-type reference, not a config store.
