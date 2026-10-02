# Source / provenance: `tmux_mode_indicator`

`bin/tmux_mode_indicator` is **vendored** (copied in, then modified) from
upstream tmux-mode-indicator's plugin script. It is not authored here.
`bin/check-vendored` reads this file to report when upstream has moved on.

| Field          | Value                                                        |
|----------------|--------------------------------------------------------------|
| Upstream repo  | `MunifTanjim/tmux-mode-indicator`                            |
| Path           | `mode_indicator.tmux`                                        |
| License        | MIT (notice reproduced below)                                |
| Vendored SHA   | `7027903` (full: `7027903adca37c54cb8f5fa99fc113b11c23c2c4`) |
| Vendored date  | 2023-03-24 (commit date); installed 2025-10-12               |

The SHA is confirmed by content, not only by date: the `custom_prompt` and
`custom_style` lines match `7027903` ("fix session option reading for custom
indicator", which dropped `-t #S`), not its predecessor `1152082`.

## Local edits

Diffing against `mode_indicator.tmux` at `7027903`, the local copy:

- **Prints the indicator instead of rewriting the status line.** Upstream
  substitutes its `#{tmux_mode_indicator}` placeholder into `status-left`
  and `status-right` with `tmux set-option`. Those four lines are commented
  out and replaced by `printf '%s' "$mode_indicator"`, so `status-right` can
  call the script as `#(tmux_mode_indicator)`. This is the edit that matters;
  re-apply it when updating.
- **Drops upstream's `set -e`** (line 3).
- **Adds a provenance comment** pointing at the upstream repo and this file.
- **Adds `# shellcheck disable=SC2034`** on `mode_indicator_placeholder`,
  which only the commented-out rewrite used.

## License

```text
MIT License

Copyright (c) 2020 Munif Tanjim

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Copied verbatim from upstream `LICENSE` at `7027903`.

## Update procedure

From the repo root, see what changed upstream since the vendored commit:

```bash
sha=$(gh api "repos/MunifTanjim/tmux-mode-indicator/commits?path=mode_indicator.tmux&per_page=1" --jq '.[0].sha')
gh api "repos/MunifTanjim/tmux-mode-indicator/contents/mode_indicator.tmux?ref=$sha" \
  -H 'Accept: application/vnd.github.raw' > /tmp/mode_indicator.tmux
diff /tmp/mode_indicator.tmux bin/tmux_mode_indicator
```

Port the upstream changes into `bin/tmux_mode_indicator`, keeping the local
edits above. Then set **Vendored SHA** and **Vendored date** to `$sha` and its
commit date, re-check the `LICENSE` notice, and run
`bin/check-vendored bin`.
