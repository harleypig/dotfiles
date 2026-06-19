#!/usr/bin/env bats

# Behavioural tests for the ship-pr skill's ship.sh helper — the pure-logic
# paths that a gh/git stub can exercise without a network or a real PR:
#   - ci-watch resolves the run matching the branch tip SHA (regression for the
#     PR #114 bug, where it watched the *latest* run instead).
#   - merge-methods parses a ruleset's allowed_merge_methods, and falls back to
#     the repo's own merge settings when no ruleset restricts them.
#
# The gh stub is faithful rather than canned: it picks canned JSON per endpoint
# and applies the requested `--jq`/`-q` expression with real jq, exactly as gh
# does — so the jq that selects the run / parses the methods is the real one
# ship.sh ships, not a test reimplementation. jq is required; the suite skips
# without it.

load ../helpers/common

setup() {
  load_bats_libs
  command -v jq > /dev/null || skip "jq not installed"

  ROOT="$(dotfiles_root)"
  SHIP="$ROOT/config/claude/skills/ship-pr/scripts/ship.sh"
  STUB="$(make_stub_dir)"

  write_gh_stub
  write_git_stub
}

teardown() {
  rm -rf "$STUB"
}

# A gh stub that mirrors `gh`: choose canned JSON by endpoint, then apply the
# requested --jq/-q expression with jq. Canned JSON is injected via env.
write_gh_stub() {
  cat > "$STUB/gh" << 'EOF'
#!/usr/bin/env bash
args=("$@")

# Defaults via plain assignment — an inline ${VAR:-{...}} would mis-parse,
# since the JSON's '}' closes the parameter expansion early.
[[ -n ${GH_RUNS-} ]] || GH_RUNS='[]'
[[ -n ${GH_RUN-} ]] || GH_RUN='{}'
[[ -n ${GH_REPO-} ]] || GH_REPO='{"nameWithOwner":"o/r"}'
[[ -n ${GH_RULESETS-} ]] || GH_RULESETS='[]'
[[ -n ${GH_RULESET-} ]] || GH_RULESET='{}'
[[ -n ${GH_CHECKRUNS-} ]] || GH_CHECKRUNS='{"check_runs":[]}'
[[ -n ${GH_REPOINFO-} ]] || GH_REPOINFO='{}'

jqexpr='.'
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[i]}" in
    --jq | -q) jqexpr="${args[i + 1]}" ;;
  esac
done

emit() { jq -r "$jqexpr" <<< "$1"; }

case "${args[0]}" in
  run)
    case "${args[1]}" in
      list) emit "$GH_RUNS" ;;
      view)
        # Per-run-id data via GH_RUN_<id>, falling back to GH_RUN. Lets a test
        # give two runs (workflows) distinct conclusions.
        var="GH_RUN_${args[2]}"
        emit "${!var:-$GH_RUN}"
        ;;
    esac
    ;;
  repo) emit "$GH_REPO" ;;
  api)
    case "${args[1]}" in
      */rulesets/*) emit "$GH_RULESET" ;;
      */rulesets) emit "$GH_RULESETS" ;;
      */check-runs) emit "$GH_CHECKRUNS" ;;
      *) emit "$GH_REPOINFO" ;;
    esac
    ;;
esac
EOF

  chmod +x "$STUB/gh"
}

# ci-watch resolves the branch tip via `git rev-parse`; return a fixed SHA.
write_git_stub() {
  cat > "$STUB/git" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$GIT_SHA"
EOF

  chmod +x "$STUB/git"
}

#------------------------------------------------------------------------------
# ci-watch — picks the run for the tip SHA, not merely the latest.

@test "ci-watch watches the run matching the branch tip SHA" {
  # The latest run (222) is for a different commit; the older run (111) is the
  # one for our tip. The pre-fix code took .[0] (222); the fix selects 111.
  local runs='[{"databaseId":222,"headSha":"feedface"},{"databaseId":111,"headSha":"abc123"}]'
  local run='{"status":"completed","conclusion":"success","workflowName":"tests","headSha":"abc123","jobs":[{"name":"bats","conclusion":"success"}]}'

  run env "PATH=$STUB:$PATH" GIT_SHA="abc123" GH_RUNS="$runs" GH_RUN="$run" \
    "$SHIP" ci-watch some-branch

  assert_success
  assert_output --partial "tests (run 111): success"
  refute_output --partial "run 222"
}

@test "ci-watch returns non-zero when the tip run failed" {
  local runs='[{"databaseId":111,"headSha":"abc123"}]'
  local run='{"status":"completed","conclusion":"failure","workflowName":"tests","headSha":"abc123","jobs":[{"name":"bats","conclusion":"failure"}]}'

  run env "PATH=$STUB:$PATH" GIT_SHA="abc123" GH_RUNS="$runs" GH_RUN="$run" \
    "$SHIP" ci-watch some-branch

  assert_failure
  assert_output --partial "tests (run 111): failure"
}

@test "ci-watch watches every workflow run for the tip SHA, not just one" {
  # Two workflows ran the same commit; the second (secret-scan) failed.
  # Watching only .[0] (tests, success) would miss it — we must see both and
  # fail. This is the regression for the multi-workflow gap.
  local runs='[{"databaseId":501,"headSha":"abc123"},{"databaseId":502,"headSha":"abc123"}]'
  local tests_run='{"status":"completed","conclusion":"success","workflowName":"tests","headSha":"abc123","jobs":[{"name":"bats","conclusion":"success"}]}'
  local scan_run='{"status":"completed","conclusion":"failure","workflowName":"secret-scan","headSha":"abc123","jobs":[{"name":"trufflehog","conclusion":"failure"}]}'

  run env "PATH=$STUB:$PATH" GIT_SHA="abc123" GH_RUNS="$runs" \
    GH_RUN_501="$tests_run" GH_RUN_502="$scan_run" \
    "$SHIP" ci-watch some-branch

  assert_failure
  assert_output --partial "tests (run 501): success"
  assert_output --partial "secret-scan (run 502): failure"
}

#------------------------------------------------------------------------------
# merge-methods — ruleset restriction wins; repo settings are the fallback.

@test "merge-methods reports the ruleset's allowed methods" {
  local rulesets='[{"id":42}]'
  local ruleset='{"rules":[{"type":"pull_request","parameters":{"allowed_merge_methods":["squash"]}}]}'

  run env "PATH=$STUB:$PATH" \
    GH_REPO='{"nameWithOwner":"o/r"}' GH_RULESETS="$rulesets" GH_RULESET="$ruleset" \
    "$SHIP" merge-methods

  assert_success
  assert_output "squash"
}

@test "merge-methods falls back to repo settings when no ruleset restricts" {
  run env "PATH=$STUB:$PATH" \
    GH_REPO='{"nameWithOwner":"o/r"}' GH_RULESETS='[]' \
    GH_REPOINFO='{"allow_squash_merge":true,"allow_merge_commit":true,"allow_rebase_merge":false}' \
    "$SHIP" merge-methods

  assert_success
  assert_line "squash"
  assert_line "merge"
  refute_output --partial "rebase"
}
