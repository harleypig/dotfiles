#!/usr/bin/env bats

# Tests for bin/git-status — renders a colored git prompt fragment. The prompt
# callers get " (repo: branch …)"; the Claude statusline passes --plain to drop
# the leading space and wrapping parens.
#
# It needs the system git-prompt.sh (which provides __git_ps1); when that isn't
# installed git-status prints nothing, so the in-repo assertions skip rather
# than fail. `ansi` is stubbed to a no-op so the paren/space assertions see
# clean text and git-status's bare `ansi` call doesn't print "command not
# found" (bin/ isn't on PATH in CI). ansi already degrades to silence in an
# incomplete terminal — the stub is purely for deterministic test output.

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"

  STUB="$(make_stub_dir)"
  printf '#!/usr/bin/env bash\n' > "$STUB/ansi"
  chmod +x "$STUB/ansi"

  REPO="$BATS_TEST_TMPDIR/sample"
  make_test_repo "$REPO"
}

teardown() {
  rm -rf "$STUB"
}

@test "git-status outside a git repo prints nothing and succeeds" {
  cd "$BATS_TEST_TMPDIR"
  run env PATH="$STUB:$PATH" "$ROOT/bin/git-status"
  assert_success
  assert_output ''
}

@test "git-status (default) wraps the repo as ' (repo: branch)'" {
  cd "$REPO"
  run env PATH="$STUB:$PATH" "$ROOT/bin/git-status"
  [[ -n $output ]] || skip "git-status produced no output (no __git_ps1?)"
  assert_output --regexp '^ \(sample: '
}

@test "git-status --plain drops the parens and the leading space" {
  cd "$REPO"
  run env PATH="$STUB:$PATH" "$ROOT/bin/git-status" --plain
  [[ -n $output ]] || skip "git-status produced no output (no __git_ps1?)"
  refute_output --partial '('
  refute_output --partial ')'
  refute_output --regexp '^ '
  assert_output --partial 'sample: '
}

@test "git-status marks a bare repository" {
  local bare="$BATS_TEST_TMPDIR/bare.git"
  git init -q --bare "$bare"
  cd "$bare"
  run env PATH="$STUB:$PATH" "$ROOT/bin/git-status"
  assert_success
  assert_output --partial 'BARE'
}
