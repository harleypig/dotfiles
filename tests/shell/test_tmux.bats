#!/usr/bin/env bats

# Tests for config/shell-startup/tmux's tmux_winidx_circled() — it maps the
# current tmux window index to a circled-digit glyph, falling back to "(N)"
# once the index passes 20 (past the glyph table). The index comes from
# `tmux display-message`, so the tests stub `tmux` to feed a chosen index and
# assert the boundary + per-index glyph selection.
#
# The function is extracted from the module and eval'd in isolation (the module
# also wires aliases/`ta`); this is the same in-isolation approach as
# test_havecmd. The `circled_digits` glyph table lives *inside* the function
# (function-local, so it doesn't pollute module scope), so extracting the
# function body carries the table with it.

load ../helpers/common

TMUX_MODULE_REL="config/shell-startup/tmux"

# Pull the tmux_winidx_circled function (table included) out of the module.
extract_winidx() {
  sed -n '/^tmux_winidx_circled()/,/^}/p' "$(dotfiles_root)/$TMUX_MODULE_REL"
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

# Env-pollution hygiene guards (source-level): the interactive helpers must not
# be pushed into child processes, and no module-scope scratch var should leak.

@test "the tmux module does not export helpers into child processes" {
  run grep -nE '^[[:space:]]*export -f' "$(dotfiles_root)/$TMUX_MODULE_REL"
  assert_failure
}

@test "circled_digits is function-local, not a module-scope global" {
  # A module-scope assignment would be a line beginning `circled_digits=`;
  # inside the function it is preceded by `local`.
  run grep -nE '^circled_digits=' "$(dotfiles_root)/$TMUX_MODULE_REL"
  assert_failure
}
