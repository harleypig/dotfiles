#!/usr/bin/env bats

# Tests for bin/git-status — renders a colored git prompt fragment
# ("(repo: branch …)") via __git_ps1. It needs the system git-prompt.sh
# (which provides __git_ps1); when that isn't installed it prints nothing, so
# those assertions skip rather than fail.

load ../helpers/common

setup() {
  load_bats_libs
  setup_temp_dir

  repo="$TEST_TEMP_DIR/myrepo"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" -c user.email=t@example.com -c user.name=t \
    commit -q --allow-empty -m init
}

teardown() {
  cleanup_temp_dir
}

# Run git-status inside the temp repo with the repo's bin/ on PATH (so it
# finds `ansi` and git-status itself).
run_git_status() {
  run bash -c 'cd "$1" && PATH="$2/bin:$PATH" git-status' _ \
    "$repo" "$(dotfiles_root)"
}

@test "git-status outside a git repo prints nothing and succeeds" {
  run bash -c 'cd "$1" && PATH="$2/bin:$PATH" git-status' _ \
    "$TEST_TEMP_DIR" "$(dotfiles_root)"
  assert_success
  assert_output ''
}

@test "git-status names the repository inside a git repo" {
  run_git_status
  assert_success
  [[ -z $output ]] && skip "git-prompt.sh (__git_ps1) not available"
  assert_output --partial 'myrepo'
}

@test "git-status marks a bare repository" {
  local bare="$TEST_TEMP_DIR/bare.git"
  git init -q --bare "$bare"
  run bash -c 'cd "$1" && PATH="$2/bin:$PATH" git-status' _ \
    "$bare" "$(dotfiles_root)"
  assert_success
  assert_output --partial 'BARE'
}
