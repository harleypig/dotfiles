#!/usr/bin/env bats

# Tests for bin/git-all — run a git command across every repo under $REPOHOME,
# summarize pass/fail, and (-S) list repos with uncommitted changes. Exercised
# against a throwaway $REPOHOME holding a couple of real repos.

load ../helpers/common

setup() {
  load_bats_libs
  GA="$(dotfiles_root)/bin/git-all"
  PATH="$(dotfiles_root)/bin:$PATH"   # git-all uses ansi
  export TERM=dumb                    # keep ansi from emitting color
  export REPOHOME="$BATS_TEST_TMPDIR/repos"
  mkdir -p "$REPOHOME"
}

make_repo() {
  make_test_repo "$REPOHOME/$1"
}

@test "no command prints usage and exits 1" {
  run "$GA"
  assert_failure
  assert_output --partial 'Run git commands on all repositories'
}

@test "an invalid REPOHOME is rejected" {
  REPOHOME=/no/such/dir run "$GA" status
  assert_failure
  assert_output --partial 'Invalid'
}

@test "an unknown option is rejected" {
  run "$GA" -x
  assert_failure
  assert_output --partial 'invalid option'
}

@test "runs a git command across all repos and summarizes" {
  make_repo one
  make_repo two
  run "$GA" rev-parse --abbrev-ref HEAD
  assert_success
  assert_output --partial 'Job Summary For 2 Repos'
  assert_output --partial 'PASS'
  assert_output --partial 'one'
  assert_output --partial 'two'
}

@test "-S lists only repos with uncommitted changes" {
  make_repo dirty
  printf 'x\n' > "$REPOHOME/dirty/tracked"
  git -C "$REPOHOME/dirty" add tracked
  git -C "$REPOHOME/dirty" commit -q -m add
  printf 'more\n' >> "$REPOHOME/dirty/tracked"   # uncommitted modification
  make_repo clean
  run "$GA" -S
  assert_success
  assert_output --partial 'dirty'
  refute_output --partial '/clean'
}
