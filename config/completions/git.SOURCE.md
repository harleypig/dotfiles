# Source / provenance: `git`

`config/completions/git` is **vendored** (copied in) from upstream Git's
bash completion script. It is not authored here. `bin/check-vendored` reads
this file to report when upstream has moved on.

| Field          | Value                                                        |
|----------------|--------------------------------------------------------------|
| Upstream repo  | `git/git`                                                    |
| Path           | `contrib/completion/git-completion.bash`                     |
| License        | GPL-2.0 (see the file header)                                |
| Vendored SHA   | `f6f2cf3` (full: `f6f2cf39ea21d116302e076a4dab9250553736b2`) |
| Vendored date  | 2026-09-25 (commit date); installed 2026-10-14               |

With the local edit below removed, the file's git blob hash
(`c3a49e2e22fda1e850e90e6f225002228d52eb93`) is exactly the upstream path's
blob at that commit.

Local edits: added `# shellcheck shell=bash` as the first line. It only tells
editors and shellcheck which dialect this extensionless file is; re-apply it
when updating.

The file is deliberately **not linted**. It is upstream code we do not
otherwise edit, so no pre-commit hook selects it: `identify` does not tag a
non-executable, extensionless file as shell, and the sourced-shell path
pattern does not cover `config/completions/`. Linting it would only report
upstream's own findings, and shfmt cannot parse its zsh-only `${(…)}` block.

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
