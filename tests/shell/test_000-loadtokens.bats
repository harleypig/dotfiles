#!/usr/bin/env bats

# Tests for config/shell-startup/000-loadtokens — exports API tokens named in
# $PROJECTS_DIR/dotfiles/api-keys.cfg from files under
# $PROJECTS_DIR/private_dotfiles/api-key, but only when both are present. It
# must be a no-op otherwise and must clean up its temporary variables.

# shellcheck disable=SC1090  # $MODULE is resolved at runtime via dotfiles_root

load ../helpers/common

setup() {
  load_bats_libs
  MODULE="$(dotfiles_root)/config/shell-startup/000-loadtokens"
  PROJECTS_DIR="$BATS_TEST_TMPDIR"
  mkdir -p "$PROJECTS_DIR/private_dotfiles/api-key" "$PROJECTS_DIR/dotfiles"
  export PROJECTS_DIR
}

@test "exports a token from a VAR=file mapping" {
  printf 'ghtoken' > "$PROJECTS_DIR/private_dotfiles/api-key/github"
  printf 'DEMO_TOKEN=github\n' > "$PROJECTS_DIR/dotfiles/api-keys.cfg"
  source "$MODULE"
  assert_equal "$DEMO_TOKEN" 'ghtoken'
}

@test "exports several tokens" {
  printf 'a' > "$PROJECTS_DIR/private_dotfiles/api-key/one"
  printf 'b' > "$PROJECTS_DIR/private_dotfiles/api-key/two"
  printf 'ONE=one\nTWO=two\n' > "$PROJECTS_DIR/dotfiles/api-keys.cfg"
  source "$MODULE"
  assert_equal "$ONE" 'a'
  assert_equal "$TWO" 'b'
}

@test "skips comment lines and lines without '='" {
  printf 'tok' > "$PROJECTS_DIR/private_dotfiles/api-key/f"
  printf '  # a comment\nnotamapping\nGOOD=f\n' \
    > "$PROJECTS_DIR/dotfiles/api-keys.cfg"
  source "$MODULE"
  assert_equal "$GOOD" 'tok'
}

@test "skips a mapping whose token file is missing" {
  printf 'MISSING=nofile\n' > "$PROJECTS_DIR/dotfiles/api-keys.cfg"
  source "$MODULE"
  assert_equal "${MISSING-UNSET}" 'UNSET'
}

@test "is a no-op when private_dotfiles is absent" {
  rm -rf "$PROJECTS_DIR/private_dotfiles"
  printf 'NOPE_TOKEN=github\n' > "$PROJECTS_DIR/dotfiles/api-keys.cfg"
  source "$MODULE"
  assert_equal "${NOPE_TOKEN-UNSET}" 'UNSET'
}

@test "is a no-op when the config file is absent" {
  run source "$MODULE"
  assert_success
}

@test "cleans up its temporary variables" {
  printf 'tok' > "$PROJECTS_DIR/private_dotfiles/api-key/f"
  printf 'GOOD=f\n' > "$PROJECTS_DIR/dotfiles/api-keys.cfg"
  source "$MODULE"
  for v in private_dotfiles config_file config_lines line filePath varName fileName; do
    assert_equal "${!v-UNSET}" 'UNSET'
  done
}
