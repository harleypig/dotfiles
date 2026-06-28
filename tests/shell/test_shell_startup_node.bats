#!/usr/bin/env bats

# Unit tests for config/shell-startup/node — the nvm lazy-load module. Source
# it with stubbed shell-startup helpers (havecmd/addpath) and a fake nvm.sh,
# and assert: the XDG env vars export unconditionally, and nvm/node/npm/npx are
# deferred shims that load nvm only on first use.

load ../helpers/common

setup() {
  load_bats_libs

  export XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
  export XDG_CONFIG_HOME="$BATS_TEST_TMPDIR/cfg"
  export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"
  export DOTFILES="$BATS_TEST_TMPDIR/dot"

  # Minimal stand-ins for the shell-startup helpers the module calls.
  # shellcheck disable=SC2329  # invoked indirectly by the sourced module
  havecmd() { command -v "$1" > /dev/null 2>&1; }
  # shellcheck disable=SC2329  # invoked indirectly by the sourced module
  addpath() { :; }

  MODULE="$(dotfiles_root)/config/shell-startup/node"
}

# Write a fake nvm.sh that records it was sourced and (re)defines node.
fake_nvm() {
  mkdir -p "$XDG_DATA_HOME/nvm"
  cat > "$XDG_DATA_HOME/nvm/nvm.sh" << EOF
touch "$XDG_DATA_HOME/nvm/SOURCED"
node() { echo "real-node \$*"; }
EOF
}

@test "exports node/npm XDG env vars unconditionally (no nvm installed)" {
  # shellcheck disable=SC1090  # module path resolved at runtime
  source "$MODULE" || true # module's last line is a non-interactive guard

  assert_equal "$NODE_REPL_HISTORY" "$XDG_CACHE_HOME/node_repl_history"
  assert_equal "$NPM_CONFIG_USERCONFIG" "$XDG_CONFIG_HOME/npm/npmrc"
  # shellcheck disable=SC2154  # assigned by the sourced module
  assert_equal "$npm_config_cache" "$XDG_CACHE_HOME/npm"
  # no nvm present -> no lazy loader defined
  [ -z "$(type -t _node_lazy_nvm)" ]
}

@test "defines lazy shims when nvm is present, without sourcing nvm.sh" {
  fake_nvm

  # shellcheck disable=SC1090  # module path resolved at runtime
  source "$MODULE" || true # module's last line is a non-interactive guard

  assert_equal "$(type -t nvm)" function
  assert_equal "$(type -t node)" function
  assert_equal "$(type -t npm)" function
  assert_equal "$(type -t npx)" function
  # lazy: nvm.sh has NOT been sourced yet
  [ ! -e "$XDG_DATA_HOME/nvm/SOURCED" ]
}

@test "first use loads nvm, runs the real command, and drops the shims" {
  fake_nvm

  # shellcheck disable=SC1090  # module path resolved at runtime
  source "$MODULE" || true # module's last line is a non-interactive guard

  # Call in-shell (redirection does not subshell) so the unset + source happen
  # in this shell and the shim replacement is observable here.
  node --version > "$BATS_TEST_TMPDIR/out" 2>&1

  assert_equal "$(cat "$BATS_TEST_TMPDIR/out")" "real-node --version"
  [ -e "$XDG_DATA_HOME/nvm/SOURCED" ]   # nvm.sh got sourced on first use
  [ -z "$(type -t _node_lazy_nvm)" ]    # the loader removed itself
}
