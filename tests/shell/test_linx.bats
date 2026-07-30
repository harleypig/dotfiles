#!/usr/bin/env bats

# Tests for bin/linx — run linode-cli under a per-scope Linode credential.
#
# The linode-cli stand-in below reports whether LINODE_CLI_TOKEN arrived, and
# which fixture it was, BY NAME — never by value. A stub that echoed
# $LINODE_CLI_TOKEN would print a real token straight into the test log on any
# machine where one is exported.

load ../helpers/common

setup() {
  load_bats_libs

  LINX="$(dotfiles_root)/bin/linx"

  export PROJECTS_DIR="$BATS_TEST_TMPDIR/projects"
  export XDG_CACHE_HOME="$BATS_TEST_TMPDIR/cache"

  TOKENS="$PROJECTS_DIR/private_dotfiles/linode/tokens"
  CACHE="$XDG_CACHE_HOME/linx/commands"
  STUB="$BATS_TEST_TMPDIR/stub"

  mkdir -p "$TOKENS" "$STUB"

  write_cli_stub '9.9.9'

  PATH="$STUB:$PATH"

  # Never let a real credential reach the stub.
  unset LINODE_CLI_TOKEN
}

#-----------------------------------------------------------------------------
# Stand in for linode-cli. Emulates the four things linx asks of it —
# `--version`, the `commands` table it parses its keyword list out of, the
# `--help` usage line it learns value-taking options from, and the two API
# calls — then reports the invocation. Takes the version to claim, so a test
# can simulate an upgrade invalidating the cache.

write_cli_stub() {
  local version=$1

  cat > "$STUB/linode-cli" << EOF
#!/usr/bin/env bash

if [[ \${1-} == --version ]]; then
  printf 'linode-cli v%s\nBuilt from spec version 4.0.0\n' '$version'
  exit 0
fi

# The usage line linx reads value-taking global options off. An option and its
# value share a bracket group; a valueless one has the group to itself.
if [[ \${1-} == --help ]]; then
  cat << 'USAGE'
usage: linode-cli [--help] [--text] [--json] [--no-headers]
                  [--format FORMAT] [--as-user USERNAME]
                  [--page-size PAGESIZE] [--alias [ALIAS]]
                  [COMMAND] [ACTION]

options:
  --format FORMAT       The columns to display in output. Provide a comma-
  --text                Display text output with a delimiter.
USAGE
  exit 0
fi

# The command table. Box-drawn, exactly as linode-cli renders it.
if [[ \${1-} == commands ]]; then
  cat << 'TABLE'

CLI user management commands:
┌─────────────┬──────────┐
│ configure   │ set-user │
└─────────────┴──────────┘

Available commands:
┌──────────┬─────────┬─────────┐
│ account  │ linodes │ profile │
│ regions  │ volumes │ domains │
└──────────┴─────────┴─────────┘
TABLE
  exit 0
fi

# --expiry's token list, and --rotate's identity check. \$LINX_EXP lets a test
# choose the expiry reported for the matching token.
if [[ " \$* " == *" profile tokens-list "* ]]; then
  case "\${LINODE_CLI_TOKEN-}" in
    acme-fixture | rotated-fixture) ;;
    *) echo 'Request failed: 401' >&2; exit 2 ;;
  esac

  # A decoy first, to prove the prefix match picks the right row.
  printf 'zzzz-other-token\t2030-01-01T00:00:00\n'
  printf 'acme\t%s\n' "\${LINX_EXP-2999-12-12T05:00:00}"
  exit 0
fi

if [[ " \$* " == *" profile view "* ]]; then
  case "\${LINODE_CLI_TOKEN-}" in
    acme-fixture | rotated-fixture) echo linodeuser; exit 0 ;;
    *) echo 'Request failed: 401' >&2; exit 2 ;;
  esac
fi

if [[ -z \${LINODE_CLI_TOKEN-} ]]; then
  seen=unset
elif [[ \$LINODE_CLI_TOKEN == acme-fixture ]]; then
  seen=acme
else
  seen=other
fi

printf 'token=%s args=[%s]\n' "\$seen" "\$*"
EOF

  chmod +x "$STUB/linode-cli"
}

#-----------------------------------------------------------------------------
# Dispatch: linode-cli command vs scope name

@test "a linode-cli command in first position passes straight through" {
  run env "PATH=$PATH" "$LINX" linodes list
  assert_success
  assert_output --partial 'token=unset args=[linodes list]'
}

@test "no positional argument at all passes straight through" {
  run env "PATH=$PATH" "$LINX" --version
  assert_success
  assert_output --partial 'linode-cli v9.9.9'
}

@test "a scope name runs linode-cli under that scope's token" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$LINX" acme linodes list
  assert_success
  assert_output --partial 'token=acme args=[linodes list]'
}

@test "a short alias symlink resolves to the same token" {
  printf 'acme-fixture' > "$TOKENS/acme"
  ln -s acme "$TOKENS/ac"

  run env "PATH=$PATH" "$LINX" ac linodes list
  assert_success
  assert_output --partial 'token=acme args=[linodes list]'
}

@test "an empty token file defers to linode-cli's configured user" {
  : > "$TOKENS/deferred"

  run env "PATH=$PATH" "$LINX" deferred volumes list
  assert_success
  assert_output --partial 'token=unset args=[volumes list]'
}

@test "an empty token file clears an ambient LINODE_CLI_TOKEN" {
  # Otherwise "use the configured user" would silently keep using whatever the
  # environment happened to be carrying.
  : > "$TOKENS/deferred"

  run env "PATH=$PATH" "LINODE_CLI_TOKEN=ambient-fixture" \
    "$LINX" deferred volumes list
  assert_success
  assert_output --partial 'token=unset args=[volumes list]'
}

@test "an unknown scope fails without running the linode-cli command" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$LINX" nosuch linodes list
  assert_failure
  assert_output --partial "no token defined for 'nosuch'"
  assert_output --partial "$TOKENS/nosuch"
  refute_output --partial 'args='
}

@test "a broken alias reports the missing target" {
  ln -s gone "$TOKENS/broken"

  run env "PATH=$PATH" "$LINX" broken linodes list
  assert_failure
  assert_output --partial "alias 'broken' points at a missing scope"
}

#-----------------------------------------------------------------------------
# Option values are not scope names
#
# Unlike gh, linode-cli has global options that take a value (--format,
# --as-user, --page-size, ...). Reading one of those values as a scope name is
# the bug these pin.

@test "the value of a global option is not read as a scope" {
  run env "PATH=$PATH" "$LINX" --format id regions list
  assert_success
  assert_output --partial 'token=unset args=[--format id regions list]'
}

@test "a scope after a value-taking option is still found" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$LINX" --format id acme regions list
  assert_success
  assert_output --partial 'token=acme args=[--format id regions list]'
}

@test "several value-taking options in a row are all skipped" {
  run env "PATH=$PATH" "$LINX" --format id --as-user someone --json regions list
  assert_success
  assert_output --partial 'args=[--format id --as-user someone --json regions list]'
}

@test "the inline --opt=value form consumes no following argument" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$LINX" --format=id acme regions list
  assert_success
  assert_output --partial 'token=acme args=[--format=id regions list]'
}

@test "a valueless option does not swallow the scope after it" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$LINX" --json acme regions list
  assert_success
  assert_output --partial 'token=acme args=[--json regions list]'
}

@test "the value-taking options are cached alongside the commands" {
  run env "PATH=$PATH" "$LINX" linodes list
  assert_success

  run grep -cx -- '--format' "$CACHE"
  assert_output '1'

  run grep -cx -- '--as-user' "$CACHE"
  assert_output '1'
}

#-----------------------------------------------------------------------------
# The cached linode-cli command list

@test "the command list is cached, keyed on the linode-cli version" {
  run env "PATH=$PATH" "$LINX" linodes list
  assert_success

  assert_file_exists "$CACHE"
  run head -n1 "$CACHE"
  assert_output 'linode-cli v9.9.9'

  run grep -cx regions "$CACHE"
  assert_output '1'
}

@test "the CLI management commands are keywords too" {
  # They live in a separate table from the API commands and are not in the
  # spec, so a probe that read only the API list would treat them as scopes.
  run env "PATH=$PATH" "$LINX" configure
  assert_success
  assert_output --partial 'args=[configure]'
}

@test "a linode-cli upgrade invalidates the cache" {
  run env "PATH=$PATH" "$LINX" linodes list
  assert_success

  write_cli_stub '10.0.0'

  run env "PATH=$PATH" "$LINX" linodes list
  assert_success

  run head -n1 "$CACHE"
  assert_output 'linode-cli v10.0.0'
}

@test "--refresh rebuilds the cache" {
  run env "PATH=$PATH" "$LINX" linodes list
  assert_success

  printf 'stale\n' > "$CACHE"

  run env "PATH=$PATH" "$LINX" --refresh linodes list
  assert_success

  run head -n1 "$CACHE"
  assert_output 'linode-cli v9.9.9'
}

@test "an unreadable command list passes everything through, loudly" {
  printf 'acme-fixture' > "$TOKENS/acme"

  # A linode-cli whose `commands` prints no table. Treating its subcommands as
  # scope names would be far worse than passing through, so linx passes
  # through — but says so.
  cat > "$STUB/linode-cli" << 'EOF'
#!/usr/bin/env bash
[[ ${1-} == --version ]] && { echo 'linode-cli v9.9.9'; exit 0; }
[[ ${1-} == commands ]] && { echo 'Unrecognized command'; exit 0; }
printf 'args=[%s]\n' "$*"
EOF
  chmod +x "$STUB/linode-cli"

  run env "PATH=$PATH" "$LINX" acme linodes list
  assert_success
  assert_output --partial "could not read linode-cli's command list"
  assert_output --partial 'args=[acme linodes list]'
}

#-----------------------------------------------------------------------------
# Reporting

@test "--list names each scope and never prints a token" {
  printf 'acme-fixture' > "$TOKENS/acme"
  ln -s acme "$TOKENS/ac"
  : > "$TOKENS/deferred"

  run env "PATH=$PATH" "$LINX" --list
  assert_success
  assert_output --partial 'acme'
  assert_output --partial 'alias -> acme'
  assert_output --partial 'configured user'
  refute_output --partial 'acme-fixture'
}

@test "--help explains the dispatch rule" {
  run env "PATH=$PATH" "$LINX" --help
  assert_success
  assert_output --partial 'Usage: linx'
  assert_output --partial 'scope'
}

#-----------------------------------------------------------------------------
# --expiry
#
# The Linode API cannot say which token authenticated a request, so linx picks
# its own out of /profile/tokens by prefix. The stub returns a decoy row ahead
# of the matching one so a test would catch "just take the first".

@test "--expiry reports each token's expiry and days remaining" {
  printf 'acme-fixture' > "$TOKENS/acme"

  local when
  when=$(date -u -d '+90 days' '+%Y-%m-%dT%H:%M:%S')

  run env "PATH=$PATH" "LINX_EXP=$when" "$LINX" --expiry
  assert_success
  assert_output --partial 'acme'
  assert_output --partial "$(date -u -d '+90 days' '+%Y-%m-%d')"
  assert_output --regexp '9[01]d'
  refute_output --partial 'expiring soon'
}

@test "--expiry flags a token close to expiry" {
  printf 'acme-fixture' > "$TOKENS/acme"

  local when
  when=$(date -u -d '+3 days' '+%Y-%m-%dT%H:%M:%S')

  run env "PATH=$PATH" "LINX_EXP=$when" "$LINX" --expiry
  assert_success
  assert_output --partial 'expiring soon'
}

@test "--expiry flags a token that already expired" {
  printf 'acme-fixture' > "$TOKENS/acme"

  local when
  when=$(date -u -d '-2 days' '+%Y-%m-%dT%H:%M:%S')

  run env "PATH=$PATH" "LINX_EXP=$when" "$LINX" --expiry
  assert_success
  assert_output --partial 'EXPIRED'
}

@test "--expiry reads Linode's far-future sentinel as no expiry" {
  # A token that never expires comes back dated in the year 2999 rather than
  # null; reporting that verbatim would say "356000d".
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "LINX_EXP=2999-12-12T05:00:00" "$LINX" --expiry
  assert_success
  assert_output --partial 'no expiry'
  refute_output --partial '2999'
}

@test "--expiry reports a rejected token rather than failing" {
  printf 'dud-fixture' > "$TOKENS/dud"

  run env "PATH=$PATH" "$LINX" --expiry
  assert_success
  assert_output --partial 'rejected'
}

@test "--expiry does not call the API for aliases or empty scopes" {
  printf 'acme-fixture' > "$TOKENS/acme"
  ln -s acme "$TOKENS/ac"
  : > "$TOKENS/deferred"

  run env "PATH=$PATH" "$LINX" --expiry
  assert_success
  assert_output --partial 'alias -> acme'
  assert_output --partial 'configured user'
  refute_output --partial 'acme-fixture'
}

#-----------------------------------------------------------------------------
# --rotate
#
# Linode can mint a token over the API, but that needs a working token with
# profile:read_write and cannot bootstrap a new scope, so --rotate automates
# the half that always works: getting the value onto disk without it passing
# through the shell history, the process list, or the terminal.

@test "--rotate stores a token from stdin, 0600, without echoing it" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$LINX" --rotate acme <<< 'rotated-fixture'
  assert_success
  assert_output --partial 'rotated'
  assert_output --partial 'authenticated as linodeuser'
  refute_output --partial 'rotated-fixture'

  assert_equal "$(< "$TOKENS/acme")" 'rotated-fixture'
  assert_equal "$(stat -c '%a' "$TOKENS/acme")" '600'
}

@test "--rotate creates a scope that does not exist yet" {
  run env "PATH=$PATH" "$LINX" --rotate brandnew <<< 'rotated-fixture'
  assert_success
  assert_output --partial 'created'

  assert_equal "$(< "$TOKENS/brandnew")" 'rotated-fixture'
  assert_equal "$(stat -c '%a' "$TOKENS/brandnew")" '600'
}

@test "--rotate refuses an alias rather than rotating its target" {
  printf 'acme-fixture' > "$TOKENS/acme"
  ln -s acme "$TOKENS/ac"

  run env "PATH=$PATH" "$LINX" --rotate ac <<< 'rotated-fixture'
  assert_failure
  assert_output --partial "'ac' is an alias for 'acme'"

  # The target is untouched.
  assert_equal "$(< "$TOKENS/acme")" 'acme-fixture'
}

@test "--rotate refuses empty input and leaves the old token intact" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$LINX" --rotate acme < /dev/null
  assert_failure
  assert_output --partial 'nothing written'

  assert_equal "$(< "$TOKENS/acme")" 'acme-fixture'
}

@test "--rotate needs a scope name" {
  run env "PATH=$PATH" "$LINX" --rotate < /dev/null
  assert_failure
  assert_output --partial 'needs a scope name'
}

@test "--rotate rejects a scope name that would escape the store" {
  run env "PATH=$PATH" "$LINX" --rotate ../elsewhere <<< 'rotated-fixture'
  assert_failure
  assert_output --partial 'invalid scope name'
}

@test "--rotate warns when the new token does not authenticate" {
  printf 'acme-fixture' > "$TOKENS/acme"

  run env "PATH=$PATH" "$LINX" --rotate acme <<< 'dud-fixture'
  assert_success
  assert_output --partial 'did not authenticate'

  # Stored anyway — the warning is advisory, not a rollback.
  assert_equal "$(< "$TOKENS/acme")" 'dud-fixture'
}

@test "--rotate leaves no staging file behind" {
  run env "PATH=$PATH" "$LINX" --rotate acme <<< 'rotated-fixture'
  assert_success

  run bash -c "ls -A '$TOKENS'"
  assert_output 'acme'
}
