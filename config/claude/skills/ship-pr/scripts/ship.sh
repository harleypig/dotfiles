#!/usr/bin/env bash
#
# ship.sh — deterministic mechanics for the ship-pr skill.
#
# Owns only the repetitive, judgment-free parts: the gh credential
# fallback, default-branch derivation, CI watch (by polling), merge-method
# discovery, the merge call, and post-merge cleanup. Authoring commit
# messages / PR bodies, diagnosing CI failures, and deciding whether to
# merge stay with the caller (see SKILL.md).
#
# Usage:
#   ship.sh default-branch
#   ship.sh pr-create --title T --body B [--base BRANCH]
#   ship.sh ci-watch [BRANCH]              # exits non-zero if CI failed
#   ship.sh merge-methods                  # prints allowed merge methods
#   ship.sh merge NUMBER --squash|--merge|--rebase
#   ship.sh cleanup BRANCH

set -euo pipefail

# gh wrapper: try the default credential; on a PAT scope error, retry the
# same command once with the env tokens cleared so gh uses the stored
# OAuth credential (see rules/gh.md). stdout stays clean for capture.
_gh() {
  local out err rc errfile
  errfile=$(mktemp)

  out=$(gh "$@" 2> "$errfile") && rc=0 || rc=$?
  err=$(cat "$errfile")
  rm -f "$errfile"

  if ((rc == 0)); then
    # Emit a trailing newline (like a normal command) so callers that pipe
    # into `while read` or `mapfile` don't drop the last line. Command
    # substitution `$(_gh ...)` strips it anyway, so this is safe there.
    if [[ -n $out ]]; then
      printf '%s\n' "$out"
    fi

    return 0
  fi

  if grep -qiE 'not accessible by personal access token|HTTP 403' \
    <<< "$err$out"; then
    # Deliberately clear both tokens for this single command so gh uses the
    # stored OAuth credential (rules/gh.md), not an empty-string assignment.
    # shellcheck disable=SC1007
    GH_TOKEN= GITHUB_TOKEN= gh "$@"
    return $?
  fi

  printf '%s\n' "$err" >&2
  return "$rc"
}

_default_branch() {
  local def
  def=$(git symbolic-ref refs/remotes/origin/HEAD 2> /dev/null \
    | sed 's@^refs/remotes/origin/@@') || true

  if [[ -z $def ]]; then
    def=$(_gh repo view --json defaultBranchRef -q .defaultBranchRef.name)
    git remote set-head origin "$def" > /dev/null 2>&1 || true
  fi

  printf '%s' "$def"
}

_nwo() {
  _gh repo view --json nameWithOwner -q .nameWithOwner
}

cmd_default_branch() {
  _default_branch
  echo
}

cmd_pr_create() {
  local title="" body="" base=""

  while (($#)); do
    case "$1" in
      --title)
        title=$2
        shift 2
        ;;
      --body)
        body=$2
        shift 2
        ;;
      --base)
        base=$2
        shift 2
        ;;
      *)
        echo "pr-create: unknown arg $1" >&2
        return 2
        ;;
    esac
  done

  [[ -n $base ]] || base=$(_default_branch)

  local head
  head=$(git branch --show-current)

  _gh pr create --base "$base" --head "$head" \
    --title "$title" --body "$body"
}

# Watch the CI run(s) for the branch's current tip commit until they finish.
# Pin to the tip SHA — not merely "the latest run for the branch" — so a
# previous commit's already-finished run is never mistaken for this push's
# (GitHub lags a few seconds after a push). A single push can trigger SEVERAL
# workflows (e.g. tests + secret-scan), so watch EVERY run for the SHA and
# aggregate — not just the first. Polling (not `gh run watch`) sidesteps the
# annotation-scope 403 a narrow PAT can hit.
cmd_ci_watch() {
  local branch=${1:-$(git branch --show-current)}
  local target_sha attempt run_id status
  local -a run_ids=()

  # The commit whose run we want is the tip we just pushed. Prefer the local
  # ref for the named branch; fall back to HEAD.
  target_sha=$(git rev-parse --verify --quiet "refs/heads/$branch") \
    || target_sha=$(git rev-parse --verify --quiet HEAD) \
    || target_sha=""

  # Poll until at least one run for target_sha registers, then a short grace
  # pass to catch sibling workflows that register a beat later. Collect ALL of
  # them. Give up after ~60s and fall back to the latest run for the branch.
  if [[ -n $target_sha ]]; then
    for ((attempt = 0; attempt < 12; attempt++)); do
      mapfile -t run_ids < <(
        _gh run list --branch "$branch" --limit 20 --json databaseId,headSha \
          --jq "map(select(.headSha==\"$target_sha\")) | .[].databaseId"
      )

      ((${#run_ids[@]} > 0)) && break

      sleep 5
    done

    if ((${#run_ids[@]} > 0)); then
      sleep 5
      mapfile -t run_ids < <(
        _gh run list --branch "$branch" --limit 20 --json databaseId,headSha \
          --jq "map(select(.headSha==\"$target_sha\")) | .[].databaseId"
      )
    fi
  fi

  if ((${#run_ids[@]} == 0)); then
    run_id=$(_gh run list --branch "$branch" --limit 1 \
      --json databaseId --jq '.[0].databaseId // empty')

    if [[ -n $run_id ]]; then
      [[ -n $target_sha ]] && echo "ci-watch: no run for ${target_sha:0:9}" \
        "yet; watching latest run $run_id instead" >&2
      run_ids=("$run_id")
    fi
  fi

  if ((${#run_ids[@]} == 0)); then
    echo "no CI run found for $branch" >&2
    return 0
  fi

  # Wait for every collected run to complete.
  for run_id in "${run_ids[@]}"; do
    while :; do
      status=$(_gh run view "$run_id" --json status --jq '.status')

      [[ $status == completed ]] && break

      sleep 15
    done
  done

  # Report each run's workflow + jobs + conclusion; track the worst outcome.
  local failed=0 name conclusion
  for run_id in "${run_ids[@]}"; do
    name=$(_gh run view "$run_id" --json workflowName --jq '.workflowName')
    conclusion=$(_gh run view "$run_id" --json conclusion --jq '.conclusion')

    echo "$name (run $run_id): $conclusion"
    _gh run view "$run_id" --json jobs \
      --jq '.jobs[] | "  \(.name): \(.conclusion)"'

    [[ $conclusion == success ]] || failed=1
  done
  echo

  # A "success" conclusion can still carry warning/error annotations
  # (deprecations, audit notices, lint warnings) that the conclusion hides.
  # Surface them. Best-effort: if the token lacks annotation read scope this
  # section is silently skipped.
  local sha nwo id level message
  local warnings=0 errors=0
  local -a check_ids=()

  # Annotations are per-COMMIT (check-runs for the SHA span every workflow), so
  # scan once for the tip SHA rather than per run.
  sha=$target_sha
  [[ -n $sha ]] || sha=$(_gh run view "${run_ids[0]}" --json headSha --jq '.headSha')
  nwo=$(_nwo)

  mapfile -t check_ids < <(
    _gh api "repos/$nwo/commits/$sha/check-runs" \
      --jq '.check_runs[] | select((.output.annotations_count // 0) > 0) | .id' \
      2> /dev/null
  )

  if ((${#check_ids[@]} > 0)); then
    echo "annotations:"

    for id in "${check_ids[@]}"; do
      while IFS=$'\t' read -r level message; do
        case "$level" in
          warning) warnings=$((warnings + 1)) ;;
          failure) errors=$((errors + 1)) ;;
        esac

        echo "  [$level] $message"
      done < <(
        _gh api "repos/$nwo/check-runs/$id/annotations" \
          --jq '.[] | "\(.annotation_level)\t\(.message | split("\n")[0])"' \
          2> /dev/null
      )
    done

    echo "  total: $errors error(s), $warnings warning(s)"
  fi

  # Exit codes: 1 = any run failed (or error annotations); 2 = passed with
  # warnings; 0 = clean. The caller decides what to do with warnings.
  if ((failed)) || ((errors > 0)); then
    return 1
  fi

  if ((warnings > 0)); then
    return 2
  fi

  return 0
}

# Print the merge methods the repo allows, honoring any branch ruleset that
# restricts them (a ruleset can be stricter than the repo settings).
cmd_merge_methods() {
  local nwo ruleset_methods
  nwo=$(_nwo)

  ruleset_methods=$(
    _gh api "repos/$nwo/rulesets" --jq '.[].id' 2> /dev/null \
      | while read -r id; do
        _gh api "repos/$nwo/rulesets/$id" \
          --jq '.rules[]? | select(.type=="pull_request")
                  | .parameters.allowed_merge_methods[]?' 2> /dev/null
      done | sort -u
  )

  if [[ -n $ruleset_methods ]]; then
    echo "$ruleset_methods"
    return 0
  fi

  _gh api "repos/$nwo" --jq '
    (if .allow_squash_merge then "squash" else empty end),
    (if .allow_merge_commit then "merge" else empty end),
    (if .allow_rebase_merge then "rebase" else empty end)'
}

cmd_merge() {
  local number=${1:?merge: PR number required}
  local method=${2:?merge: method flag required (--squash|--merge|--rebase)}

  _gh pr merge "$number" "$method" --delete-branch
}

cmd_cleanup() {
  local branch=${1:?cleanup: branch required}
  local def
  def=$(_default_branch)

  git checkout "$def"
  git pull origin "$def"
  git branch -d "$branch" 2> /dev/null || true
  git branch -dr "origin/$branch" 2> /dev/null || true
  git branch -ra
}

main() {
  local sub=${1:?usage: ship.sh <subcommand> [args]}
  shift || true

  case "$sub" in
    default-branch) cmd_default_branch "$@" ;;
    pr-create) cmd_pr_create "$@" ;;
    ci-watch) cmd_ci_watch "$@" ;;
    merge-methods) cmd_merge_methods "$@" ;;
    merge) cmd_merge "$@" ;;
    cleanup) cmd_cleanup "$@" ;;
    *)
      echo "ship.sh: unknown subcommand $sub" >&2
      return 2
      ;;
  esac
}

main "$@"
