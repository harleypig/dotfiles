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

@test "serena dispatches to docker with the image, project mount, config volume, and stdio flags" {
  cat > "$STUB/docker" << EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$STUB/docker.args"
exit 0
EOF
  chmod +x "$STUB/docker"

  run env PROJECTS_DIR="$BATS_TEST_TMPDIR/projects" DOTFILES="$FAKE" \
    "PATH=$STUB:$PATH" "$ROOT/bin/mymcp" serena
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "run --rm -i"
  assert_output --partial "-v $BATS_TEST_TMPDIR/projects:/workspaces/projects"
  assert_output --partial "-v serena-config:/workspaces/serena/config"
  assert_output --partial "ghcr.io/oraios/serena:latest serena start-mcp-server --transport stdio --enable-web-dashboard false"
}

@test "playwright dispatches to docker with the image, headless/isolated flags, and forwards extra args" {
  cat > "$STUB/docker" << EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$STUB/docker.args"
exit 0
EOF
  chmod +x "$STUB/docker"

  run env DOTFILES="$FAKE" "PATH=$STUB:$PATH" "$ROOT/bin/mymcp" playwright
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "run --rm -i mcr.microsoft.com/playwright/mcp --headless --isolated"

  run env DOTFILES="$FAKE" "PATH=$STUB:$PATH" "$ROOT/bin/mymcp" playwright \
    --allowed-origins http://localhost:3000
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "run --rm -i mcr.microsoft.com/playwright/mcp --headless --isolated --allowed-origins http://localhost:3000"
}

@test "github reads its mcp-github token file and passes it to docker" {
  # GitHub credentials live in their own store, not under api-key/ (bin/ghx
  # owns it); mymcp reads this one by full path.
  local keydir="$BATS_TEST_TMPDIR/projects/private_dotfiles/github"
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

@test "xai-consult reads its grok key and execs the published server with it" {
  local keydir="$BATS_TEST_TMPDIR/projects/private_dotfiles/api-key"
  mkdir -p "$keydir"
  printf 'xai-fixture-key' > "$keydir/grok"

  # Fake Claude config dir holding the server. The stub reports which fixture
  # key arrived by name, never the value (see common.bash *Secret-bearing
  # stubs*).
  local cfg="$BATS_TEST_TMPDIR/claude"
  mkdir -p "$cfg/bin"
  make_script_stub "$cfg/bin" xai-consult-mcp "case \$XAI_API_KEY in
  xai-fixture-key) echo fixture > '$STUB/xai.env' ;;
  *) echo other > '$STUB/xai.env' ;;
esac"

  # -u: a key already exported in the calling shell would reach the server
  # whether or not mymcp exports it.
  run env -u XAI_API_KEY PROJECTS_DIR="$BATS_TEST_TMPDIR/projects" \
    DOTFILES="$FAKE" CLAUDE_CONFIG_DIR="$cfg" "$ROOT/bin/mymcp" xai-consult
  assert_success

  run cat "$STUB/xai.env"
  assert_output "fixture"

  # The launch line is logged; the key never is.
  run cat "$FAKE"/.mymcp/mymcp-xai-consult-*.log
  assert_output --partial "$cfg/bin/xai-consult-mcp"
  refute_output --partial "xai-fixture-key"
}

@test "xai-consult fails with a clear error when the server is not installed" {
  run env PROJECTS_DIR="$BATS_TEST_TMPDIR/projects" DOTFILES="$FAKE" \
    CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/no-claude" \
    "$ROOT/bin/mymcp" xai-consult
  assert_failure 1

  run cat "$FAKE"/.mymcp/mymcp-xai-consult-*.log
  assert_output --partial "xai-consult-mcp not found or not executable"
}

@test "xai-consult fails with a clear error when its grok key file is missing" {
  local cfg="$BATS_TEST_TMPDIR/claude"
  mkdir -p "$cfg/bin"
  make_stub "$cfg/bin" xai-consult-mcp

  run env PROJECTS_DIR="$BATS_TEST_TMPDIR/projects" DOTFILES="$FAKE" \
    CLAUDE_CONFIG_DIR="$cfg" "$ROOT/bin/mymcp" xai-consult
  assert_failure

  run cat "$FAKE"/.mymcp/mymcp-xai-consult-*.log
  assert_output --partial "api-key file not found"
  assert_file_not_exists "$cfg/bin/xai-consult-mcp.args"
}
