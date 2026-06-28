#!/usr/bin/env bats

# Tests for the vendored bash-completion scripts in config/completions/.
#
# These are generated from each tool's official `completion` command and
# committed, because sourcing a static file is far cheaper than forking the
# tool on every interactive shell (docker and npm each measured ~300ms). The
# shell-startup modules that source them (gh, docker, rust, and nodejs for npm)
# are thin `havecmd`-guarded wrappers, exercised in aggregate by the
# integration startup test; here we guard the vendored content itself — a
# botched regeneration is the real risk.

load ../helpers/common

setup() {
  load_bats_libs
}

# Completions this repo generates from a tool's own `completion` output, each
# self-contained enough to register without the system bash-completion package
# (unlike the large third-party git/packwiz/poetry scripts).
GENERATED="gh docker npm rustup cargo"

@test "every vendored completion file parses as bash" {
  local f
  for f in "$(dotfiles_root)"/config/completions/*; do
    [[ -f $f ]] || continue
    [[ $f == *.md ]] && continue
    bash -n "$f" || fail "syntax error in $f"
  done
}

@test "each generated completion registers its command when sourced" {
  local t
  for t in $GENERATED; do
    run bash -c "source '$(dotfiles_root)/config/completions/$t' && complete -p $t"
    assert_success
    assert_output --partial " $t"
  done
}
