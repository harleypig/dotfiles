#!/usr/bin/env bats

# Tests for bin/gh-app-token — mint and cache a GitHub App installation
# access token.
#
# curl is stubbed so nothing here ever reaches the real GitHub API; openssl
# and jq are the real system tools (fast, deterministic, and it is the only
# way to prove the JWT is actually signed correctly). The stub curl records
# its own invocation so a test can assert it was (or was NOT) called at all
# — the cache-hit tests prove no network call happens once a token is fresh.
#
# Never assert on a real secret value beyond the fixture tokens this file
# itself makes up — see CLAUDE.md Secret Handling.

load ../helpers/common

setup_file() {
  # One throwaway RSA key shared by every test in this file — signing is
  # deterministic and fast, so nothing here mocks openssl itself.
  export GAT_TEST_KEY="$BATS_FILE_TMPDIR/test-key.pem"
  openssl genrsa -out "$GAT_TEST_KEY" 2048 2> /dev/null
}

setup() {
  load_bats_libs

  GAT="$(dotfiles_root)/bin/gh-app-token"

  export PROJECTS_DIR="$BATS_TEST_TMPDIR/projects"
  export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"

  APPS="$PROJECTS_DIR/private_dotfiles/github/apps"
  CACHE="$XDG_CACHE_HOME/gh-app-token"
  STUB="$BATS_TEST_TMPDIR/stub"
  CURL_CALLS="$BATS_TEST_TMPDIR/curl.calls"

  mkdir -p "$APPS" "$STUB"

  PATH="$STUB:$PATH"
}

#-----------------------------------------------------------------------------
# A valid App credential dir: the shared test key plus fixture IDs.

write_app_dir() {
  local slug=$1

  mkdir -p "$APPS/$slug"
  cp "$GAT_TEST_KEY" "$APPS/$slug/private-key.pem"
  printf '111' > "$APPS/$slug/app-id"
  printf '222' > "$APPS/$slug/installation-id"
}

#-----------------------------------------------------------------------------
# Stand in for curl. Records every invocation (args, including the
# Authorization header carrying the JWT) to $CURL_CALLS, then answers per
# mode: ok (a canned installation-token response), fail (a network error,
# curl's own exit 7), or malformed (200 but missing the fields we need).

write_curl_stub() {
  local mode=${1:-ok}
  local token=${2:-app-token-fixture}
  local expires_at=${3:-}

  [[ -n $expires_at ]] || expires_at=$(date -u -d '+55 minutes' '+%Y-%m-%dT%H:%M:%SZ')

  cat > "$STUB/curl" << EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$CURL_CALLS"

case '$mode' in
  fail)
    echo 'curl: (7) Failed to connect to api.github.com' >&2
    exit 7
    ;;
  malformed)
    printf '{"message":"Not Found"}\n'
    ;;
  *)
    printf '{"token":"$token","expires_at":"$expires_at"}\n'
    ;;
esac
EOF
  chmod +x "$STUB/curl"
}

#-----------------------------------------------------------------------------
# Write a cache file directly in the internal format (token, then a unix
# epoch), bypassing mint_token entirely — used to set up cache-hit/miss and
# boundary cases without a network round trip.

write_cache() {
  local slug=$1 token=$2 epoch=$3

  mkdir -p "$CACHE"
  chmod 700 "$CACHE"
  printf '%s\n%s\n' "$token" "$epoch" > "$CACHE/$slug.token"
  chmod 600 "$CACHE/$slug.token"
}

#-----------------------------------------------------------------------------
# Dispatch: usage, invalid slugs, help

@test "no slug prints usage and exits 2" {
  run env "PATH=$PATH" "$GAT"
  assert_failure 2
  assert_output --partial 'Usage: gh-app-token'
}

@test "--help shows usage and exits 0" {
  run env "PATH=$PATH" "$GAT" --help
  assert_success
  assert_output --partial 'Usage: gh-app-token'
  assert_output --partial '--status'
}

@test "a path-traversal slug is rejected" {
  run env "PATH=$PATH" "$GAT" '../evil'
  assert_failure 2
  assert_output --partial 'invalid slug'
}

@test "a slug that looks like a flag is rejected" {
  run env "PATH=$PATH" "$GAT" '-weird'
  assert_failure 2
  assert_output --partial 'invalid slug'
}

@test "an unknown trailing argument is rejected" {
  write_app_dir acme

  run env "PATH=$PATH" "$GAT" acme --bogus
  assert_failure 2
  assert_output --partial 'unknown argument'
}

#-----------------------------------------------------------------------------
# Minting — the curl/openssl round trip

@test "mints a fresh token, prints it, and caches it 0600 in a 0700 dir" {
  write_app_dir acme
  write_curl_stub ok app-token-fixture

  run env "PATH=$PATH" "$GAT" acme
  assert_success
  assert_output 'app-token-fixture'

  assert_file_exist "$CURL_CALLS"

  assert_equal "$(stat -c '%a' "$CACHE")" '700'
  assert_equal "$(stat -c '%a' "$CACHE/acme.token")" '600'
  assert_equal "$(sed -n '1p' "$CACHE/acme.token")" 'app-token-fixture'
}

@test "the JWT sent to curl verifies against the app's own public key" {
  write_app_dir acme
  write_curl_stub ok

  run env "PATH=$PATH" "$GAT" acme
  assert_success

  local jwt
  jwt=$(grep -o 'Authorization: Bearer [^ ]*' "$CURL_CALLS" | sed 's/^Authorization: Bearer //')
  [[ -n $jwt ]]

  local header payload sig
  IFS='.' read -r header payload sig <<< "$jwt"

  openssl rsa -in "$GAT_TEST_KEY" -pubout -out "$BATS_TEST_TMPDIR/pub.pem" 2> /dev/null

  python3 -c "
import base64, sys
def b64(s):
    s += '=' * (-len(s) % 4)
    return base64.urlsafe_b64decode(s)
open('$BATS_TEST_TMPDIR/sig.bin', 'wb').write(b64('$sig'))
"
  printf '%s.%s' "$header" "$payload" > "$BATS_TEST_TMPDIR/signing_input"

  run openssl dgst -sha256 -verify "$BATS_TEST_TMPDIR/pub.pem" \
    -signature "$BATS_TEST_TMPDIR/sig.bin" "$BATS_TEST_TMPDIR/signing_input"
  assert_success
  assert_output --partial 'Verified OK'
}

@test "a cache-hit never calls curl" {
  write_app_dir acme

  local future
  future=$(($(date +%s) + 3600))
  write_cache acme cached-fixture "$future"

  run env "PATH=$PATH" "$GAT" acme
  assert_success
  assert_output 'cached-fixture'

  assert_file_not_exist "$CURL_CALLS"
}

@test "a cache within the refresh buffer is treated as a miss and remints" {
  write_app_dir acme
  write_curl_stub ok fresh-fixture

  # 300s is the refresh buffer: exactly at the boundary counts as a miss.
  local near
  near=$(($(date +%s) + 300))
  write_cache acme stale-fixture "$near"

  run env "PATH=$PATH" "$GAT" acme
  assert_success
  assert_output 'fresh-fixture'

  assert_file_exist "$CURL_CALLS"
}

@test "a cache safely past the refresh buffer is reused" {
  write_app_dir acme
  write_curl_stub ok

  local safe
  safe=$(($(date +%s) + 301))
  write_cache acme cached-fixture "$safe"

  run env "PATH=$PATH" "$GAT" acme
  assert_success
  assert_output 'cached-fixture'

  assert_file_not_exist "$CURL_CALLS"
}

@test "a corrupt cache file is treated as a miss and remints" {
  write_app_dir acme
  write_curl_stub ok fresh-fixture

  mkdir -p "$CACHE"
  printf 'not-a-real-cache-line' > "$CACHE/acme.token"

  run env "PATH=$PATH" "$GAT" acme
  assert_success
  assert_output 'fresh-fixture'

  assert_file_exist "$CURL_CALLS"
}

@test "a cache with a non-numeric expiry is treated as a miss and remints" {
  write_app_dir acme
  write_curl_stub ok fresh-fixture

  write_cache acme old-fixture not-a-number

  run env "PATH=$PATH" "$GAT" acme
  assert_success
  assert_output 'fresh-fixture'
}

#-----------------------------------------------------------------------------
# Fail-closed on missing/empty credential inputs — never an unauthenticated
# fallback.

@test "fails closed when the private key is missing" {
  mkdir -p "$APPS/acme"
  printf '111' > "$APPS/acme/app-id"
  printf '222' > "$APPS/acme/installation-id"

  run env "PATH=$PATH" "$GAT" acme
  assert_failure 1
  assert_output --partial 'private key not found or unreadable'

  assert_file_not_exist "$CURL_CALLS"
}

@test "fails closed when app-id is missing" {
  mkdir -p "$APPS/acme"
  cp "$GAT_TEST_KEY" "$APPS/acme/private-key.pem"
  printf '222' > "$APPS/acme/installation-id"

  run env "PATH=$PATH" "$GAT" acme
  assert_failure 1
  assert_output --partial 'app-id not found or unreadable'
}

@test "fails closed when installation-id is missing" {
  mkdir -p "$APPS/acme"
  cp "$GAT_TEST_KEY" "$APPS/acme/private-key.pem"
  printf '111' > "$APPS/acme/app-id"

  run env "PATH=$PATH" "$GAT" acme
  assert_failure 1
  assert_output --partial 'installation-id not found or unreadable'
}

@test "fails closed when app-id is empty" {
  write_app_dir acme
  : > "$APPS/acme/app-id"

  run env "PATH=$PATH" "$GAT" acme
  assert_failure 1
  assert_output --partial 'app-id file is empty'
}

@test "fails closed on a network failure, and caches nothing" {
  write_app_dir acme
  write_curl_stub fail

  run env "PATH=$PATH" "$GAT" acme
  assert_failure 1
  assert_output --partial 'could not mint an installation token'

  assert_file_not_exist "$CACHE/acme.token"
}

@test "fails closed on a malformed API response, and caches nothing" {
  write_app_dir acme
  write_curl_stub malformed

  run env "PATH=$PATH" "$GAT" acme
  assert_failure 1
  assert_output --partial 'unexpected response'

  assert_file_not_exist "$CACHE/acme.token"
}

#-----------------------------------------------------------------------------
# --status — reports validity, never the token

@test "--status never prints the cached token value" {
  local future
  future=$(($(date +%s) + 3600))
  write_cache acme super-secret-fixture "$future"

  run env "PATH=$PATH" "$GAT" acme --status
  assert_success
  assert_output --partial 'valid'
  refute_output --partial 'super-secret-fixture'
}

@test "--status reports no cached token when none exists" {
  run env "PATH=$PATH" "$GAT" acme --status
  assert_success
  assert_output --partial 'no cached token'
}

@test "--status flags an expired cached token" {
  local past
  past=$(($(date +%s) - 10))
  write_cache acme expired-fixture "$past"

  run env "PATH=$PATH" "$GAT" acme --status
  assert_success
  assert_output --partial 'EXPIRED'
  refute_output --partial 'expired-fixture'
}

@test "--status reports a corrupt cache file as corrupt" {
  mkdir -p "$CACHE"
  printf 'garbage' > "$CACHE/acme.token"

  run env "PATH=$PATH" "$GAT" acme --status
  assert_success
  assert_output --partial 'corrupt'
}

@test "--status reminds that the private key must be rotated by hand" {
  local future
  future=$(($(date +%s) + 3600))
  write_cache acme cached-fixture "$future"

  run env "PATH=$PATH" "$GAT" acme --status
  assert_success
  assert_output --partial 'rotate by hand'
  assert_output --partial 'private-key.pem'
}

@test "--status never calls curl" {
  local future
  future=$(($(date +%s) + 3600))
  write_cache acme cached-fixture "$future"

  run env "PATH=$PATH" "$GAT" acme --status
  assert_success

  assert_file_not_exist "$CURL_CALLS"
}
