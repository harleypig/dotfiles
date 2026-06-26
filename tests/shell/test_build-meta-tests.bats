#!/usr/bin/env bats

# Tests for tests/scaffold/build-meta-tests, focused on the stale-prune
# behavior: a generated *.meta.bats whose source is gone is removed on the
# next run, while real meta tests and hand-written test_*.bats are left alone.
# Runs against an isolated fixture repo so it never regenerates the real suite.

load ../helpers/common

setup() {
  load_bats_libs
  scaffold="$(dotfiles_root)/tests/scaffold"

  # Minimal fixture repo: <fix>/tests/scaffold/{build-meta-tests,templates} +
  # a source script under bin/. build-meta-tests resolves the repo root from
  # its own path (../..), so a copied scaffold targets the fixture, not us.
  FIX="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$FIX/tests/scaffold" "$FIX/tests/shell" "$FIX/bin"
  cp "$scaffold/build-meta-tests" "$FIX/tests/scaffold/"
  cp -r "$scaffold/templates" "$FIX/tests/scaffold/"

  printf '#!/usr/bin/env bash\necho hi\n' > "$FIX/bin/foo"
  chmod +x "$FIX/bin/foo"

  GEN="$FIX/tests/scaffold/build-meta-tests"
}

@test "generates a meta test for a source script" {
  run "$GEN" bin
  assert_success
  [ -f "$FIX/tests/shell/bin-foo.meta.bats" ]
}

@test "prunes a stale meta test whose source no longer exists" {
  "$GEN" bin
  # A leftover from a since-deleted/renamed source.
  touch "$FIX/tests/shell/bin-gone.meta.bats"

  run "$GEN" bin
  assert_success
  [ ! -e "$FIX/tests/shell/bin-gone.meta.bats" ]
  [ -f "$FIX/tests/shell/bin-foo.meta.bats" ]
}

@test "never touches hand-written test_*.bats" {
  touch "$FIX/tests/shell/test_keep.bats"

  run "$GEN" bin
  assert_success
  [ -f "$FIX/tests/shell/test_keep.bats" ]
}

@test "reports the pruned count" {
  "$GEN" bin
  touch "$FIX/tests/shell/bin-gone.meta.bats"

  run "$GEN" bin
  assert_success
  assert_output --partial 'pruned 1 stale'
}
