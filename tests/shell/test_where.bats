#!/usr/bin/env bats

# Tests for bin/where — classify how each command name resolves
# (keyword / builtin / file+path / not found). The alias path is exercised via
# a sourced shell with `expand_aliases` (below); the function path still needs
# a live shell and isn't exercised here.

load ../helpers/common

setup() {
  load_bats_libs
  WHERE="$(dotfiles_root)/bin/where"
}

@test "where reports a shell keyword" {
  run "$WHERE" if
  assert_success
  assert_output --partial 'if:keyword'
}

@test "where reports a builtin" {
  run "$WHERE" cd
  assert_output --partial 'cd:builtin'
}

@test "where reports a file command with its path" {
  run "$WHERE" ls
  assert_output --regexp '^ls:file:/'
}

@test "where reports a missing command" {
  run "$WHERE" __no_such_cmd_xyz__
  assert_output --partial 'is not found'
}

@test "where handles several commands at once" {
  run "$WHERE" if cd
  assert_output --partial 'if:keyword'
  assert_output --partial 'cd:builtin'
}

# Regression: aliases in this setup live in the dotfiles shell modules
# ($DOTFILES/config/shell-startup), not the classic ~/.bash* files. Before the
# fix, `where` detected the alias TYPE but its hardcoded search locations
# missed the module, so it reported no definition location. The alias must be
# live in the shell (expand_aliases) for `type -t` to see it, AND present in a
# searched file for its location to be found.
@test "where locates an alias defined in the dotfiles shell modules" {
  local root="$BATS_TEST_TMPDIR/df"
  mkdir -p "$root/config/shell-startup" "$root/home"
  cat > "$root/config/shell-startup/mymod" <<'MOD'
# a shell module
alias whtest='echo hi'
MOD

  run env DOTFILES="$root" HOME="$root/home" \
    bash -c "shopt -s expand_aliases; alias whtest='echo hi'; source '$WHERE' whtest"

  assert_success
  assert_output --regexp '^whtest:alias:[0-9]+:.*/config/shell-startup/mymod$'
}
