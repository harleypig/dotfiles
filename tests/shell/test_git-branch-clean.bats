#!/usr/bin/env bats

# Tests for bin/git-branch-clean — delete local branches whose upstream is
# gone (and, with -a, branches never pushed). Exercised against a throwaway
# repo with a real (local, bare) remote so `git fetch --prune` works offline.

load ../helpers/common

setup() {
  load_bats_libs
  GBC="$(dotfiles_root)/bin/git-branch-clean"
  REPO="$BATS_TEST_TMPDIR/work"
}

# Minimal repo (no remote) — for the usage / guard tests.
init_repo() {
  git init -q "$REPO"
  git -C "$REPO" config user.email t@example.com
  git -C "$REPO" config user.name test
  git -C "$REPO" commit --allow-empty -q -m init
}

# Repo with a pushed-then-deleted "feature" (gone upstream) and a never-pushed
# "local-only" branch.
init_gone_repo() {
  local remote="$BATS_TEST_TMPDIR/remote.git"
  git init --bare -q "$remote"
  init_repo
  git -C "$REPO" branch -M master
  git -C "$REPO" remote add origin "$remote"
  git -C "$REPO" push -q -u origin master
  git -C "$REPO" checkout -q -b feature
  git -C "$REPO" commit --allow-empty -q -m feat
  git -C "$REPO" push -q -u origin feature
  git -C "$REPO" checkout -q master
  git -C "$REPO" push -q origin --delete feature
  git -C "$REPO" branch local-only
}

@test "errors when not in a git repository" {
  cd "$BATS_TEST_TMPDIR"
  run "$GBC" -n
  assert_failure
  assert_output --partial 'not a git repository'
}

@test "shows usage with no options" {
  init_repo
  cd "$REPO"
  run "$GBC"
  assert_failure
  assert_output --partial 'Usage:'
}

@test "-n and -f are mutually exclusive" {
  init_repo
  cd "$REPO"
  run "$GBC" -n -f
  assert_failure
  assert_output --partial 'mutually exclusive'
}

@test "requires -f or -n to do anything" {
  init_repo
  cd "$REPO"
  run "$GBC" -a
  assert_failure
  assert_output --partial '-f required'
}

@test "-n dry-run reports a gone branch without deleting it" {
  init_gone_repo
  cd "$REPO"
  run "$GBC" -n
  assert_success
  assert_output --partial 'Would delete branch: feature'
  run git -C "$REPO" branch --list feature
  assert_output --partial 'feature'
}

@test "-n -a also reports never-pushed branches" {
  init_gone_repo
  cd "$REPO"
  run "$GBC" -n -a
  assert_success
  assert_output --partial 'Would delete branch: feature'
  assert_output --partial 'Would delete branch: local-only'
}

@test "-f deletes the gone branch" {
  init_gone_repo
  cd "$REPO"
  run "$GBC" -f
  assert_success
  assert_output --partial 'Deleting branch: feature'
  run git -C "$REPO" branch --list feature
  assert_output ''
}

@test "-h prints usage" {
  init_repo
  cd "$REPO"
  run "$GBC" -h
  assert_failure
  assert_output --partial 'Usage:'
}
