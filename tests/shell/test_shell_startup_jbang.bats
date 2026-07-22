#!/usr/bin/env bats

# Unit tests for config/shell-startup/jbang — the jbang module. Source it with
# a stubbed addpath (records its argument) and a controlled HOME/XDG, and
# assert the XDG auto-adopt: when $XDG_DATA_HOME/jbang exists JBANG_DIR is
# exported and PATH points there; otherwise it falls back to ~/.jbang. jbang
# has no native XDG support, so JBANG_DIR is the only lever (see the module).

load ../helpers/common

setup() {
  load_bats_libs

  export HOME="$BATS_TEST_TMPDIR/home"
  export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
  mkdir -p "$HOME" "$XDG_DATA_HOME"

  ADDPATH_LOG="$BATS_TEST_TMPDIR/addpath.log"
  : > "$ADDPATH_LOG"

  # Record what the module asks to add to PATH, without touching the real PATH.
  # shellcheck disable=SC2329  # invoked indirectly by the sourced module
  addpath() { printf '%s\n' "$*" >> "$ADDPATH_LOG"; }

  MODULE="$(dotfiles_root)/config/shell-startup/jbang"
}

@test "falls back to ~/.jbang when no XDG jbang dir exists" {
  # shellcheck disable=SC1090  # module path resolved at runtime
  source "$MODULE"

  [ -z "${JBANG_DIR:-}" ]
  assert_equal "$(cat "$ADDPATH_LOG")" "$HOME/.jbang/bin"
}

@test "auto-adopts the XDG jbang dir when it is present" {
  mkdir -p "$XDG_DATA_HOME/jbang"

  # shellcheck disable=SC1090  # module path resolved at runtime
  source "$MODULE"

  assert_equal "$JBANG_DIR" "$XDG_DATA_HOME/jbang"
  assert_equal "$(cat "$ADDPATH_LOG")" "$XDG_DATA_HOME/jbang/bin"
}

@test "defines the j! alias for jbang" {
  # shellcheck disable=SC1090  # module path resolved at runtime
  source "$MODULE"

  run alias 'j!'
  assert_success
  assert_output --partial jbang
}
