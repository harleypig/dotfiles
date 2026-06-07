#!/usr/bin/env bats

# Tests for bin/creds-helper — a git credential helper: emit "password=..."
# from ~/.netrc for the requested host, falling back to the
# $PROJECTS_DIR/private_dotfiles/api-key/github PAT file.

load ../helpers/common

setup() {
  load_bats_libs
  CREDS="$(dotfiles_root)/bin/creds-helper"
  export HOME="$BATS_TEST_TMPDIR/home"
  export PROJECTS_DIR="$BATS_TEST_TMPDIR/projects"
  mkdir -p "$HOME" "$PROJECTS_DIR/private_dotfiles/api-key"
}

@test "emits the .netrc password for the host" {
  printf 'machine github.com\n  login me\n  password netrcsecret\n' \
    > "$HOME/.netrc"
  run "$CREDS" <<< "host=github.com"
  assert_success
  assert_output 'password=netrcsecret'
}

@test "falls back to the PAT file when .netrc has no match" {
  # No ~/.netrc; the PAT file should be used (regression: it used to read an
  # unset $PAT_FILE and error instead of this file).
  printf 'pattoken' > "$PROJECTS_DIR/private_dotfiles/api-key/github"
  run "$CREDS" <<< "host=github.com"
  assert_success
  assert_output 'password=pattoken'
}

@test ".netrc wins over the PAT file" {
  printf 'machine github.com\n  password netrcsecret\n' > "$HOME/.netrc"
  printf 'pattoken' > "$PROJECTS_DIR/private_dotfiles/api-key/github"
  run "$CREDS" <<< "host=github.com"
  assert_output 'password=netrcsecret'
}

@test "emits nothing when neither source has the credential" {
  run "$CREDS" <<< "host=github.com"
  assert_success
  assert_output ''
}
