#!/usr/bin/env bats

# Covers bin/git-status's --plain flag (used by the Claude statusline): it drops
# the leading space + wrapping parens the prompt callers keep. Runs against this
# real repo; skips if git-status emits nothing (no __git_ps1 available).

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"
}

# Strip ANSI color + charset-select codes so paren/space checks see plain text.
strip_ansi() {
  sed 's/\x1b\[[0-9;]*m//g; s/\x1b(B//g'
}

@test "git-status (default) wraps the repo in parens for the prompt" {
  run "$ROOT/bin/git-status"
  [[ -n $output ]] || skip "git-status produced no output (no __git_ps1?)"

  local plain
  plain=$(printf '%s' "$output" | strip_ansi)
  [[ $plain == *'('* ]] || fail "default output lost its parens: $plain"
}

@test "git-status --plain drops the parens and the leading space" {
  run "$ROOT/bin/git-status" --plain
  [[ -n $output ]] || skip "git-status produced no output (no __git_ps1?)"

  local plain
  plain=$(printf '%s' "$output" | strip_ansi)
  [[ $plain != *'('* ]] || fail "--plain output still has parens: $plain"
  [[ $plain != *')'* ]] || fail "--plain output still has parens: $plain"
  [[ $plain != ' '* ]] || fail "--plain output has a leading space: $plain"
}
