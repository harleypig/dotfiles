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
  make_test_repo "$REPO"
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
  assert_output --partial 'only one of'
}

@test "requires -f or -n to do anything" {
  init_repo
  cd "$REPO"
  run "$GBC" -a
  assert_failure
  assert_output --partial 'is required'
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

@test "-n -a reports a never-pushed branch whose subject has [brackets]" {
  init_gone_repo
  git -C "$REPO" checkout -q -b wip
  git -C "$REPO" commit --allow-empty -q -m 'fix [WIP] thing [skip ci]'
  git -C "$REPO" checkout -q master
  cd "$REPO"
  run "$GBC" -n -a
  assert_success
  assert_output --partial 'Would delete branch: wip (never pushed)'
}

@test "-n -a leaves a pushed branch with a live upstream alone" {
  init_gone_repo
  git -C "$REPO" checkout -q -b kept
  git -C "$REPO" commit --allow-empty -q -m 'plain subject'
  git -C "$REPO" push -q -u origin kept
  git -C "$REPO" checkout -q master
  cd "$REPO"
  run "$GBC" -n -a
  assert_success
  refute_output --partial 'branch: kept'
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

@test "-f skips a gone branch checked out in another worktree and cleans the rest" {
  init_gone_repo
  git -C "$REPO" branch -q aaa-gone
  git -C "$REPO" push -q origin aaa-gone
  git -C "$REPO" branch -q --set-upstream-to=origin/aaa-gone aaa-gone
  git -C "$REPO" push -q origin --delete aaa-gone
  git -C "$REPO" worktree add -q "$BATS_TEST_TMPDIR/wt" feature
  cd "$REPO"
  run "$GBC" -f
  assert_success
  assert_output --partial 'Skipping branch: feature (checked out in worktree'
  assert_output --partial 'Deleting branch: aaa-gone'
  run git -C "$REPO" branch --list feature aaa-gone
  assert_output --partial 'feature'
  refute_output --partial 'aaa-gone'
}

@test "-n reports, not offers, a gone branch checked out in another worktree" {
  init_gone_repo
  git -C "$REPO" worktree add -q "$BATS_TEST_TMPDIR/wt" feature
  cd "$REPO"
  run "$GBC" -n
  assert_success
  assert_output --partial 'Skipping branch: feature (checked out in worktree'
  refute_output --partial 'Would delete branch: feature'
}

@test "-f -a skips a never-pushed branch checked out in another worktree" {
  init_gone_repo
  git -C "$REPO" worktree add -q "$BATS_TEST_TMPDIR/wt" local-only
  cd "$REPO"
  run "$GBC" -f -a
  assert_success
  assert_output --partial 'Skipping branch: local-only (checked out in worktree'
  refute_output --partial 'Deleting branch: local-only'
  run git -C "$REPO" branch --list local-only
  assert_output --partial 'local-only'
}

@test "-f carries on past a branch git refuses to delete, then fails" {
  init_gone_repo
  git -C "$REPO" branch -q zzz-gone
  git -C "$REPO" push -q origin zzz-gone
  git -C "$REPO" branch -q --set-upstream-to=origin/zzz-gone zzz-gone
  git -C "$REPO" push -q origin --delete zzz-gone
  # A stub git that refuses the first deletion makes the refusal deterministic.
  local stub
  stub=$(make_stub_dir)
  make_script_stub "$stub" git 'if [[ $1 == branch && $2 == -D && $3 == feature ]]; then
  echo "refused" >&2
  exit 1
fi
exec /usr/bin/git "$@"'
  cd "$REPO"
  run env "PATH=$stub:$PATH" "$GBC" -f
  assert_failure
  assert_output --partial 'Deleting branch: zzz-gone'
}

@test "-h prints usage (exit 0 via parse_params)" {
  init_repo
  cd "$REPO"
  run "$GBC" -h
  assert_success
  assert_output --partial 'Usage:'
}
