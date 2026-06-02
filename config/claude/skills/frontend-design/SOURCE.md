# Source / provenance

This skill is **vendored** (copied in) from an upstream GitHub repo, then
audited to fit this environment's rules. It is not authored here.

| Field          | Value                                            |
|----------------|--------------------------------------------------|
| Upstream repo  | `anthropics/skills`                              |
| Path           | `skills/frontend-design`                         |
| License        | Apache-2.0 (see `LICENSE.txt`)                   |
| Vendored SHA   | `0075614` (full: `00756142ab04c82a447693cf373c4e0c554d1005`) |
| Vendored date  | 2025-12-04 (commit date); installed 2026-06-02   |

Local edits: wrapped to 78 columns, added this provenance and a "Fit with
this environment" section, and overrode the upstream "use a motion library"
default with the repo's bundle-discipline rule. Re-apply these when updating.

## Check for upstream changes

```bash
# Latest upstream commit that touched this skill:
gh api "repos/anthropics/skills/commits?path=skills/frontend-design/SKILL.md&per_page=1" \
  --jq '.[0] | "\(.sha[0:7])  \(.commit.committer.date)"'
```

If the SHA differs from **Vendored SHA** above, upstream has changed.
Compare the diff before pulling:

```bash
gh api "repos/anthropics/skills/commits/00756142ab04c82a447693cf373c4e0c554d1005...main" \
  --jq '.files[] | select(.filename|startswith("skills/frontend-design/")) | .filename'
```

## Update procedure

1. Re-fetch the upstream `SKILL.md` / `LICENSE.txt`
   (`gh api repos/anthropics/skills/contents/skills/frontend-design/<file>
   --jq .content | base64 -d`).
2. Re-apply the local edits noted above (formatting + ecosystem sections).
3. Bump **Vendored SHA** / **Vendored date** here and the matching line in
   `SKILL.md`.
