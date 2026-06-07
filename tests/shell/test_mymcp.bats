#!/usr/bin/env bats

# Tests for bin/mymcp dispatch + logging. Server launches are exercised against
# npx/docker PATH-stubs; DOTFILES is faked so logs land in a temp dir and the
# shared lib resolves.

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"

  FAKE="$BATS_TEST_TMPDIR/dotfiles"
  mkdir -p "$FAKE"
  ln -s "$ROOT/lib" "$FAKE/lib"

  STUB="$(make_stub_dir)"
}

teardown() {
  rm -rf "$STUB"
}

@test "no arguments logs usage and exits 2" {
  run env DOTFILES="$FAKE" "$ROOT/bin/mymcp"
  assert_failure 2

  run cat "$FAKE"/.mymcp/mymcp-unknown-*.log
  assert_output --partial "[mymcp] Usage:"
}

@test "an unknown command exits 2 and logs it" {
  run env DOTFILES="$FAKE" "$ROOT/bin/mymcp" bogus
  assert_failure 2

  run cat "$FAKE"/.mymcp/mymcp-bogus-*.log
  assert_output --partial "Unknown option: bogus"
}

@test "snyk dispatches to npx with the expected arguments" {
  make_stub "$STUB" npx
  run env DOTFILES="$FAKE" "PATH=$STUB:$PATH" "$ROOT/bin/mymcp" snyk
  assert_success

  run cat "$STUB/npx.args"
  assert_output --partial "-y snyk@latest mcp -t stdio"
}

@test "github refuses to run without GITHUB_TOKEN" {
  run env -u GITHUB_TOKEN DOTFILES="$FAKE" "$ROOT/bin/mymcp" github
  assert_failure
}
