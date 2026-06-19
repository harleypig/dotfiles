#!/usr/bin/env bats

# Covers bin/git-status's --plain flag (used by the Claude statusline): it drops
# the leading space + wrapping parens the prompt callers keep.
#
# Runs in a throwaway repo with a normal (non-detached) branch and a no-op
# `ansi` stub, so output is deterministic regardless of CI's detached HEAD or
# whether `ansi` is on PATH. Skips if __git_ps1 isn't available (git-status
# then prints nothing).

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"

  STUB="$(make_stub_dir)"
  printf '#!/usr/bin/env bash\n' > "$STUB/ansi"
  chmod +x "$STUB/ansi"

  REPO="$BATS_TEST_TMPDIR/sample"
  git init -q "$REPO"
  git -C "$REPO" -c user.email=t@example.com -c user.name=t \
    commit -q --allow-empty -m init
}

teardown() {
  rm -rf "$STUB"
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
