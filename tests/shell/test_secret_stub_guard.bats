#!/usr/bin/env bats

# Guards against a test stub echoing a secret-bearing variable's VALUE
# instead of a non-reversible discriminator (name/set-unset/length/hash).
# While building bin/ghx, a throwaway `gh` stub used a bare printf to show
# which credential arrived — because the real GH_TOKEN was exported at the
# time, it printed a live PAT into the session transcript and forced a
# rotation (#355). dotagents' secret-echo-guard.py PreToolUse hook stops the
# agent from writing or running that shape; this is the repo-side backstop
# for a stub a human writes, or one already sitting in the tree. See
# tests/helpers/common.bash for the safe shapes this rejects the absence of.
#
# The two positive-control fixtures below build the offending line at
# bats-runtime (the variable name kept apart from the "$" that reassembles
# it) rather than spelling the incident's own shape out verbatim in this
# file — this source is shell too, and writing it here as literal text
# would be exactly the mistake this test guards against.

load ../helpers/common

setup() {
  load_bats_libs
}

#-----------------------------------------------------------------------------
# Print any echo/printf line in <file> that interpolates a secret-bearing
# variable's VALUE — excluding the safe forms (a set/unset marker
# `${VAR:+…}`, a length `${#VAR}`) and a line whose output is consumed
# (redirected to a file, piped) rather than left on the terminal. Matches
# only an ALL-CAPS name, the shell convention for an env-sourced credential,
# so a same-named local fixture variable (`token`, `expires_at`) is not
# flagged. Prints nothing when the file is clean.

_scan_secret_echo() {
  local file=$1
  local secret_re='\$\{?[A-Z][A-Z0-9_]*'
  secret_re+='(TOKEN|SECRET|PASSWORD|PASSWD|PASSPHRASE|CREDENTIAL'
  secret_re+='|PRIVATE_KEY|API_?KEY|ACCESS_?KEY|_KEY|_PAT)[A-Z0-9_]*\}?'

  grep -nE '\b(echo|printf)\b' "$file" 2> /dev/null \
    | grep -E "$secret_re" \
    | grep -vE '\$\{[A-Z0-9_]+:?\+' \
    | grep -vE '\$\{#' \
    | grep -vE '[>|]' \
    || true
}

#-----------------------------------------------------------------------------
# Positive controls (testing.md: a check is not trusted until it has been
# seen to fail) — confirm the scan actually catches the incident's shape.

@test "flags a stub that prints a secret-bearing variable's value" {
  local f="$BATS_TEST_TMPDIR/bad_stub" var=GH_TOKEN

  printf '#!/usr/bin/env bash\nprintf %s "$%s"\n' "'%s'" "$var" > "$f"

  run _scan_secret_echo "$f"
  assert_output --partial "$var"
}

@test "flags a display-fallback that prints a secret's value when set" {
  local f="$BATS_TEST_TMPDIR/bad_stub_fallback" var=AWS_SECRET_ACCESS_KEY

  # shellcheck disable=SC2016  # ${%s...} is a printf format, not expansion here
  printf '#!/usr/bin/env bash\necho "${%s:-unset}"\n' "$var" > "$f"

  run _scan_secret_echo "$f"
  assert_output --partial "$var"
}

#-----------------------------------------------------------------------------
# Negative control — confirm the safe shapes documented in common.bash do
# NOT trip the guard (a check that is too wide is its own failure mode).

@test "does not flag the documented safe shapes" {
  local f="$BATS_TEST_TMPDIR/good_stub"

  cat > "$f" << 'EOF'
#!/usr/bin/env bash
[[ -n $GH_TOKEN ]] && echo set || echo unset
echo "${GH_TOKEN:+set}"
echo "${#GH_TOKEN}"
printf '%s' "$GH_TOKEN" | sha256sum | cut -c1-8
printf '%s' "$GH_TOKEN" >> "$out"
case "$GH_TOKEN" in
  acme-fixture) echo acme ;;
  *) echo other ;;
esac
EOF

  run _scan_secret_echo "$f"
  assert_output ''
}

#-----------------------------------------------------------------------------
# The real guard — every committed shell test file, clean.

@test "the committed shell test suite contains no unguarded secret echo" {
  local root files f hits=0

  root="$(dotfiles_root)"

  mapfile -t files < <(
    git -C "$root" ls-files 'tests/shell/*.bats' 'tests/helpers/*.bash'
  )
  ((${#files[@]} > 0)) || fail "no test files found — the walk is vacuous"

  for f in "${files[@]}"; do
    [[ -f "$root/$f" ]] || continue

    run _scan_secret_echo "$root/$f"
    if [[ -n $output ]]; then
      hits=$((hits + 1))
      printf 'secret-echo risk in %s:\n%s\n' "$f" "$output" >&2
    fi
  done

  ((hits == 0))
}
