#!/usr/bin/env bats

# Tests for bin/check-vendored — report vendored copies behind upstream.
#
# gh is stubbed: it records its arguments and answers with whatever
# gh_answers last set, so no test reaches the network.

load ../helpers/common

setup() {
  load_bats_libs

  CHECK="$(dotfiles_root)/bin/check-vendored"

  TREE="$BATS_TEST_TMPDIR/tree"
  STUB="$BATS_TEST_TMPDIR/stub"

  mkdir -p "$TREE" "$STUB"

  cat > "$STUB/gh" << 'EOF'
#!/usr/bin/env bash
dir=$(dirname "$0")
printf '%s\n' "$*" >> "$dir/gh.args"
[[ -s $dir/gh.out ]] && cat "$dir/gh.out"
exit "$(cat "$dir/gh.rc" 2> /dev/null || echo 0)"
EOF

  chmod +x "$STUB/gh"

  PATH="$STUB:$PATH"

  FULL=c5a7ee124d491d5fe0e3948532ca8219b3b471c0
  NEWER=189ff3a56d34a1a23a53888e0431096a3f20436f
}

#-----------------------------------------------------------------------------
# Set what the gh stub prints and the status it exits with.

gh_answers() {
  local rc=$1 out=$2

  printf '%s' "$out" > "$STUB/gh.out"
  printf '%s' "$rc" > "$STUB/gh.rc"
}

#-----------------------------------------------------------------------------
# Write a provenance table to <file>. Each further argument is one
# "Field=value" row, so a test can leave a field out.

write_record() {
  local file=$1 row
  shift

  mkdir -p "$(dirname "$file")"

  {
    echo '# Source'
    echo
    echo '| Field | Value |'
    echo '|-------|-------|'

    for row in "$@"; do
      # shellcheck disable=SC2016  # the backticks are literal Markdown
      printf '| %s | `%s` |\n' "${row%%=*}" "${row#*=}"
    done
  } > "$file"
}

good_record() {
  write_record "$1" 'Upstream repo=git/git' \
    'Path=contrib/completion/git-completion.bash' \
    "Vendored SHA=c5a7ee1\` (full: \`$FULL"
}

@test "up to date: reports OK and exits 0" {
  good_record "$TREE/completions/git.SOURCE.md"
  gh_answers 0 "$FULL 2024-03-14T21:05:25Z"

  run "$CHECK" "$TREE"

  assert_success
  assert_output --partial 'OK      '
  assert_output --partial 'git/git:contrib/completion/git-completion.bash  c5a7ee1'
  assert_file_contains "$STUB/gh.args" \
    'repos/git/git/commits?path=contrib/completion/git-completion.bash&per_page=1'
}

@test "behind: reports BEHIND with a compare URL and exits 1" {
  good_record "$TREE/SOURCE.md"
  gh_answers 0 "$NEWER 2026-08-31T15:24:59Z"

  run "$CHECK" "$TREE"

  assert_failure 1
  assert_output --partial 'BEHIND  '
  assert_output --partial 'c5a7ee1 -> 189ff3a (2026-08-31T15:24:59Z)'
  assert_output --partial "https://github.com/git/git/compare/$FULL...$NEWER"
}

@test "a short vendored SHA matches the full latest SHA" {
  write_record "$TREE/SOURCE.md" 'Upstream repo=git/git' 'Path=p' \
    'Vendored SHA=c5a7ee1'
  gh_answers 0 "$FULL 2024-03-14T21:05:25Z"

  run "$CHECK" "$TREE"

  assert_success
  assert_output --partial 'OK      '
}

@test "malformed: a record missing Path is an ERROR, exit 2, gh not called" {
  write_record "$TREE/SOURCE.md" 'Upstream repo=git/git' "Vendored SHA=$FULL"

  run "$CHECK" "$TREE"

  assert_failure 2
  assert_output --partial 'ERROR   '
  assert_output --partial 'malformed: missing Path'
  assert_file_not_exists "$STUB/gh.args"
}

@test "malformed: a Vendored SHA with no hex SHA in it is an ERROR" {
  write_record "$TREE/SOURCE.md" 'Upstream repo=git/git' 'Path=p' \
    'Vendored SHA=unknown'

  run "$CHECK" "$TREE"

  assert_failure 2
  assert_output --partial 'missing Vendored SHA'
}

@test "gh failure is an ERROR carrying gh's message, exit 2" {
  good_record "$TREE/SOURCE.md"
  gh_answers 1 'HTTP 404: Not Found'

  run "$CHECK" "$TREE"

  assert_failure 2
  assert_output --partial 'ERROR   '
  assert_output --partial 'gh api failed for git/git: HTTP 404: Not Found'
}

@test "no upstream commits for the path is an ERROR" {
  good_record "$TREE/SOURCE.md"
  gh_answers 0 ''

  run "$CHECK" "$TREE"

  assert_failure 2
  assert_output --partial 'no upstream commits for git/git:'
}

@test "ERROR outranks BEHIND in the exit status, and every record is checked" {
  good_record "$TREE/a/SOURCE.md"
  write_record "$TREE/b/SOURCE.md" 'Upstream repo=git/git' "Vendored SHA=$FULL"
  gh_answers 0 "$NEWER 2026-08-31T15:24:59Z"

  run "$CHECK" "$TREE"

  assert_failure 2
  assert_output --partial 'BEHIND  '
  assert_output --partial 'ERROR   '
}

@test "a SOURCE.md with no Vendored SHA row is attribution only and skipped" {
  write_record "$TREE/SOURCE.md" 'Upstream repo=someone/else' 'Path=x'

  run "$CHECK" "$TREE"

  assert_success
  assert_output --partial 'no vendored SOURCE.md records found'
  assert_file_not_exists "$STUB/gh.args"
}

@test "records under .git are not scanned" {
  good_record "$TREE/.git/SOURCE.md"

  run "$CHECK" "$TREE"

  assert_success
  assert_file_not_exists "$STUB/gh.args"
}

@test "defaults to the current directory" {
  good_record "$TREE/SOURCE.md"
  gh_answers 0 "$FULL 2024-03-14T21:05:25Z"

  cd "$TREE"
  run "$CHECK"

  assert_success
  assert_output --partial 'OK      ./SOURCE.md'
}

@test "-h prints usage" {
  run "$CHECK" -h

  assert_success
  assert_output --partial 'Usage:'
}
