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

@test "github fails with a clear error when its token file is missing" {
  run env PROJECTS_DIR="$BATS_TEST_TMPDIR/projects" DOTFILES="$FAKE" \
    "$ROOT/bin/mymcp" github
  assert_failure

  run cat "$FAKE"/.mymcp/mymcp-github-*.log
  assert_output --partial "api-key file not found"
}

@test "github reads its mcp-github token file and passes it to docker" {
  local keydir="$BATS_TEST_TMPDIR/projects/private_dotfiles/api-key"
  mkdir -p "$keydir"
  printf 'tok-abc123' > "$keydir/mcp-github"

  # Docker stub records both its args and the token it received via the
  # environment, so we can assert the file's contents reached the server.
  cat > "$STUB/docker" << EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$STUB/docker.args"
printf '%s\n' "\$GITHUB_PERSONAL_ACCESS_TOKEN" >> "$STUB/docker.env"
exit 0
EOF
  chmod +x "$STUB/docker"

  run env PROJECTS_DIR="$BATS_TEST_TMPDIR/projects" DOTFILES="$FAKE" \
    "PATH=$STUB:$PATH" "$ROOT/bin/mymcp" github
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "ghcr.io/github/github-mcp-server stdio --dynamic-toolsets --tools=get_me,search_code"

  run cat "$STUB/docker.env"
  assert_output "tok-abc123"
}
