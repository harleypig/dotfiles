#!/usr/bin/env bats

# Tests for config/shell-startup/tmux's tmux_winidx_circled() — it maps the
# current tmux window index to a circled-digit glyph, falling back to "(N)"
# once the index passes 20 (past the glyph table). The index comes from
# `tmux display-message`, so the tests stub `tmux` to feed a chosen index and
# assert the boundary + per-index glyph selection.
#
# The function and its `circled_digits` table are extracted from the module
# and eval'd in isolation (the module also wires aliases/exports/`ta`); this is
# the same in-isolation approach as test_havecmd.

load ../helpers/common

# Pull the circled_digits table line plus the function body out of the module.
extract_winidx() {
  sed -n '/^circled_digits=/,/^}/p' "$(dotfiles_root)/config/shell-startup/tmux"
}

setup() {
  load_bats_libs

  # Stub tmux so `tmux display-message -p '#I'` yields the index under test.
  # shellcheck disable=SC2329  # invoked indirectly by the eval'd function
  tmux() { printf '%s\n' "$STUB_WINIDX"; }

  eval "$(extract_winidx)"
}

@test "tmux_winidx_circled wraps an index above 20 in parentheses" {
  STUB_WINIDX=21 run tmux_winidx_circled
  assert_success
  assert_output '(21)'
}

@test "tmux_winidx_circled wraps a large index in parentheses" {
  STUB_WINIDX=99 run tmux_winidx_circled
  assert_success
  assert_output '(99)'
}

@test "tmux_winidx_circled uses a glyph (not parens) at the boundary of 20" {
  STUB_WINIDX=20 run tmux_winidx_circled
  assert_success
  refute_output ''
  refute_output --partial '('
}

@test "tmux_winidx_circled selects a distinct glyph per window index" {
  STUB_WINIDX=5 run tmux_winidx_circled
  local g5=$output
  STUB_WINIDX=6 run tmux_winidx_circled
  local g6=$output

  [ -n "$g5" ]
  [ "$g5" != "$g6" ]
}
