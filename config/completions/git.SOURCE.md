# Source / provenance: `git`

`config/completions/git` is **vendored** (copied in) from upstream Git's
bash completion script. It is not authored here. `bin/check-vendored` reads
this file to report when upstream has moved on.

| Field          | Value                                                        |
|----------------|--------------------------------------------------------------|
| Upstream repo  | `git/git`                                                    |
| Path           | `contrib/completion/git-completion.bash`                     |
| License        | GPL-2.0 (see the file header)                                |
| Vendored SHA   | `c5a7ee1` (full: `c5a7ee124d491d5fe0e3948532ca8219b3b471c0`) |
| Vendored date  | 2024-03-14 (commit date); installed 2024-04-02               |

The SHA was pinned after the fact (2026-10-01) by blob comparison: with the
local edit below removed, the file's git blob hash
(`75193ded4bdeda01fc440db26b08e40ae2d3a73f`) is exactly the upstream path's
blob at that commit, a merge on `master`.

Local edits: added `# shellcheck shell=bash` as the first line, so the
pre-commit shellcheck hook can lint this extensionless file. Re-apply it when
updating.

## Update procedure

From the repo root:

```bash
sha=$(gh api "repos/git/git/commits?path=contrib/completion/git-completion.bash&per_page=1" --jq '.[0].sha')
{
  echo '# shellcheck shell=bash'
  gh api "repos/git/git/contents/contrib/completion/git-completion.bash?ref=$sha" \
    -H 'Accept: application/vnd.github.raw'
} > config/completions/git
```

Then set **Vendored SHA** and **Vendored date** above to `$sha` and its
commit date, and run `bats tests/shell/test_completions.bats`.
