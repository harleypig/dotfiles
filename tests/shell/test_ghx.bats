#!/usr/bin/env bats

# Tests for bin/ghx — run gh under a per-scope GitHub credential.
#
# The gh stand-in below reports whether GH_TOKEN arrived, and which fixture it
# was, BY NAME — never by value. A stub that echoes $GH_TOKEN would print a
# real token straight into the test log on any machine where one is exported.

load ../helpers/common

setup() {
  load_bats_libs

  GHX="$(dotfiles_root)/bin/ghx"

  export PROJECTS_DIR="$BATS_TEST_TMPDIR/projects"
  export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"

  TOKENS="$PROJECTS_DIR/private_dotfiles/github/tokens"
  CACHE="$XDG_CACHE_HOME/ghx/commands"
  STUB="$BATS_TEST_TMPDIR/stub"

  mkdir -p "$TOKENS" "$STUB"

  write_gh_stub '9.9.9'

  PATH="$STUB:$PATH"

  # Never let a real credential reach the stub.
  unset GH_TOKEN GITHUB_TOKEN
}

#-----------------------------------------------------------------------------
# Stand in for gh. Emulates the two things ghx asks of it — `--version`, and
# the unknown-command output it parses its keyword list out of — then reports
# the invocation. Takes the version to claim, so a test can simulate an
# upgrade invalidating the cache.

write_gh_stub() {
  local version=$1

  cat > "$STUB/gh" << EOF
#!/usr/bin/env bash

if [[ \${1-} == --version ]]; then
  printf 'gh version %s (2026-01-01)\nhttps://example.invalid/\n' '$version'
  exit 0
fi

# The identity check --rotate makes to verify a freshly stored token, and the
# header request --expiry reads the expiry off. \$GHX_EXP lets a test choose
# the expiry the stub reports (empty = the header is absent entirely).
if [[ \${1-} == api && \${2-} == -i ]]; then
  case "\${GH_TOKEN-}" in
    acme-fixture | rotated-fixture) ;;
    *) echo 'HTTP 401: Bad credentials' >&2; exit 1 ;;
  esac

  printf 'HTTP/2.0 200 OK\r\n'
  [[ -n \${GHX_EXP-} ]] \
    && printf 'Github-Authentication-Token-Expiration: %s\r\n' "\$GHX_EXP"
  printf 'X-Oauth-Scopes: repo\r\n\r\n{"login":"octocat"}\n'
  exit 0
fi

if [[ \${1-} == api && \${2-} == user ]]; then
  case "\${GH_TOKEN-}" in
    acme-fixture | rotated-fixture) echo octocat; exit 0 ;;
    *) echo 'HTTP 401: Bad credentials' >&2; exit 1 ;;
  esac
fi

case "\${1-}" in
  api | auth | issue | pr | release | repo | run) ;;
  *)
    printf 'unknown command "%s" for "gh"\n\n' "\${1-}"
    printf 'Usage:  gh <command> <subcommand> [flags]\n\n'
    printf 'Available commands:\n'
    printf '  %s\n' api auth issue pr release repo run
    exit 1
    ;;
esac

if [[ -z \${GH_TOKEN-} ]]; then
  seen=unset
elif [[ \$GH_TOKEN == acme-fixture ]]; then
  seen=acme
else
  seen=other
fi

printf 'token=%s args=[%s]\n' "\$seen" "\$*"
EOF

  chmod +x "$STUB/gh"
}

#-----------------------------------------------------------------------------
# Dispatch: gh command vs scope name

@test "a gh command in first position passes straight through" {
  run env "PATH=$PATH" "$GHX" pr list
  assert_success
  assert_output --partial 'token=unset args=[pr list]'
}

@test "no positional argument at all passes straight through" {
  run env "PATH=$PATH" "$GHX" --version
  assert_success
  assert_output --partial 'gh version 9.9.9'
}

@test "a scope name runs gh under that scope's token" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$GHX" acme pr list
  assert_success
  assert_output --partial 'token=acme args=[pr list]'
}

@test "a short alias symlink resolves to the same token" {
  printf 'acme-fixture' > "$TOKENS/acme"
  ln -s acme "$TOKENS/ac"

  run env "PATH=$PATH" "$GHX" ac pr list
  assert_success
  assert_output --partial 'token=acme args=[pr list]'
}

@test "an empty token file defers to gh's stored credential" {
  : > "$TOKENS/ldteam"

  run env "PATH=$PATH" "$GHX" ldteam repo list
  assert_success
  assert_output --partial 'token=unset args=[repo list]'
}

@test "an unknown scope fails without running the gh command" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$GHX" nosuch pr list
  assert_failure
  assert_output --partial "no token defined for 'nosuch'"
  assert_output --partial "$TOKENS/nosuch"
  refute_output --partial 'args='
}

@test "a broken alias reports the missing target" {
  ln -s gone "$TOKENS/broken"

  run env "PATH=$PATH" "$GHX" broken pr list
  assert_failure
  assert_output --partial "alias 'broken' points at a missing scope"
}

#-----------------------------------------------------------------------------
# The cached gh command list

@test "the command list is cached, keyed on the gh version" {
  run env "PATH=$PATH" "$GHX" pr list
  assert_success

  assert_file_exists "$CACHE"
  run head -n1 "$CACHE"
  assert_output 'gh version 9.9.9 (2026-01-01)'

  run grep -cx pr "$CACHE"
  assert_output '1'
}

@test "a gh upgrade invalidates the cache" {
  run env "PATH=$PATH" "$GHX" pr list
  assert_success

  write_gh_stub '10.0.0'

  run env "PATH=$PATH" "$GHX" pr list
  assert_success

  run head -n1 "$CACHE"
  assert_output 'gh version 10.0.0 (2026-01-01)'
}

@test "--refresh rebuilds the cache" {
  run env "PATH=$PATH" "$GHX" pr list
  assert_success

  printf 'stale\n' > "$CACHE"

  run env "PATH=$PATH" "$GHX" --refresh pr list
  assert_success

  run head -n1 "$CACHE"
  assert_output 'gh version 9.9.9 (2026-01-01)'
}

@test "an unreadable command list passes everything through, loudly" {
  printf 'acme-fixture' > "$TOKENS/acme"

  # A gh that never prints an "Available commands:" block. Treating its
  # subcommands as scope names would be far worse than passing through, so
  # ghx passes through — but says so.
  cat > "$STUB/gh" << 'EOF'
#!/usr/bin/env bash
[[ ${1-} == --version ]] && { echo 'gh version 9.9.9 (2026-01-01)'; exit 0; }
printf 'args=[%s]\n' "$*"
EOF
  chmod +x "$STUB/gh"

  run env "PATH=$PATH" "$GHX" acme pr list
  assert_success
  assert_output --partial "could not read gh's command list"
  assert_output --partial 'args=[acme pr list]'
}

#-----------------------------------------------------------------------------
# Reporting

@test "--list names each scope and never prints a token" {
  printf 'acme-fixture' > "$TOKENS/acme"
  ln -s acme "$TOKENS/ac"
  : > "$TOKENS/ldteam"

  run env "PATH=$PATH" "$GHX" --list
  assert_success
  assert_output --partial 'acme'
  assert_output --partial 'alias -> acme'
  assert_output --partial 'stored credential'
  refute_output --partial 'acme-fixture'
}

@test "--help explains the dispatch rule" {
  run env "PATH=$PATH" "$GHX" --help
  assert_success
  assert_output --partial 'Usage: ghx'
  assert_output --partial 'scope'
}

#-----------------------------------------------------------------------------
# --expiry
#
# GitHub has no endpoint for a token's expiry — it comes back as a response
# header on an authenticated request, so these drive the stub's header.

@test "--expiry reports each token's expiry and days remaining" {
  printf 'acme-fixture' > "$TOKENS/acme"

  local when
  when=$(date -u -d '+90 days' '+%Y-%m-%d %H:%M:%S UTC')

  run env "PATH=$PATH" "GHX_EXP=$when" "$GHX" --expiry
  assert_success
  assert_output --partial 'acme'
  assert_output --partial "$(date -u -d '+90 days' '+%Y-%m-%d')"
  assert_output --regexp '9[01]d'
  refute_output --partial 'expiring soon'
}

@test "--expiry flags a token close to expiry" {
  printf 'acme-fixture' > "$TOKENS/acme"

  local when
  when=$(date -u -d '+3 days' '+%Y-%m-%d %H:%M:%S UTC')

  run env "PATH=$PATH" "GHX_EXP=$when" "$GHX" --expiry
  assert_success
  assert_output --partial 'expiring soon'
}

@test "--expiry flags a token that already expired" {
  printf 'acme-fixture' > "$TOKENS/acme"

  local when
  when=$(date -u -d '-2 days' '+%Y-%m-%d %H:%M:%S UTC')

  run env "PATH=$PATH" "GHX_EXP=$when" "$GHX" --expiry
  assert_success
  assert_output --partial 'EXPIRED'
}

@test "--expiry reports a token with no expiry header as non-expiring" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "GHX_EXP=" "$GHX" --expiry
  assert_success
  assert_output --partial 'no expiry'
}

@test "--expiry reports a rejected token rather than failing" {
  printf 'dud-fixture' > "$TOKENS/dud"

  run env "PATH=$PATH" "$GHX" --expiry
  assert_success
  assert_output --partial 'token rejected'
}

@test "--expiry does not call the API for aliases or empty scopes" {
  printf 'acme-fixture' > "$TOKENS/acme"
  ln -s acme "$TOKENS/ac"
  : > "$TOKENS/ldteam"

  run env "PATH=$PATH" "GHX_EXP=2099-01-01 00:00:00 UTC" "$GHX" --expiry
  assert_success
  assert_output --partial 'alias -> acme'
  assert_output --partial 'stored credential'
  refute_output --partial 'acme-fixture'
}

#-----------------------------------------------------------------------------
# --rotate
#
# GitHub has no API for minting a PAT, so --rotate automates only the half
# that can be: getting the value onto disk without it passing through the
# shell history, the process list, or the terminal.

@test "--rotate stores a token from stdin, 0600, without echoing it" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$GHX" --rotate acme <<< 'rotated-fixture'
  assert_success
  assert_output --partial 'rotated'
  assert_output --partial 'authenticated as octocat'
  refute_output --partial 'rotated-fixture'

  assert_equal "$(< "$TOKENS/acme")" 'rotated-fixture'
  assert_equal "$(stat -c '%a' "$TOKENS/acme")" '600'
}

@test "--rotate creates a scope that does not exist yet" {
  run env "PATH=$PATH" "$GHX" --rotate brandnew <<< 'rotated-fixture'
  assert_success
  assert_output --partial 'created'

  assert_equal "$(< "$TOKENS/brandnew")" 'rotated-fixture'
  assert_equal "$(stat -c '%a' "$TOKENS/brandnew")" '600'
}

@test "--rotate refuses an alias rather than rotating its target" {
  printf 'acme-fixture' > "$TOKENS/acme"
  ln -s acme "$TOKENS/ac"

  run env "PATH=$PATH" "$GHX" --rotate ac <<< 'rotated-fixture'
  assert_failure
  assert_output --partial "'ac' is an alias for 'acme'"

  # The target is untouched.
  assert_equal "$(< "$TOKENS/acme")" 'acme-fixture'
}

@test "--rotate refuses empty input and leaves the old token intact" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$GHX" --rotate acme < /dev/null
  assert_failure
  assert_output --partial 'nothing written'

  assert_equal "$(< "$TOKENS/acme")" 'acme-fixture'
}

@test "--rotate needs a scope name" {
  run env "PATH=$PATH" "$GHX" --rotate < /dev/null
  assert_failure
  assert_output --partial 'needs a scope name'
}

@test "--rotate warns when the new token does not authenticate" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$GHX" --rotate acme <<< 'dud-fixture'
  assert_success
  assert_output --partial 'did not authenticate'

  # Stored anyway — the warning is advisory, not a rollback.
  assert_equal "$(< "$TOKENS/acme")" 'dud-fixture'
}

@test "--rotate leaves no staging file behind" {
  run env "PATH=$PATH" "$GHX" --rotate acme <<< 'rotated-fixture'
  assert_success

  run bash -c "ls -A '$TOKENS'"
  assert_output 'acme'
}
