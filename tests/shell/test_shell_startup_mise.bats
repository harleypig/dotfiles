#!/usr/bin/env bats

# Unit tests for config/shell-startup/mise. The module has three branches:
#   1. havecmd mise fails                -> no-op (return before anything else)
#   2. interactive AND hooks supported   -> full activation + hook reorder
#   3. otherwise (non-interactive OR no  -> shims-only activation, no reorder
#      hook support)
#
# _bash_prompt_supports_hooks and _bash_prompt_reorder_hooks are stubbed
# rather than exercised for real -- their own behavior is already covered by
# tests/shell/test_bash_prompt.bats; this file only checks that the module
# calls the right one under the right condition.
#
# Branch 2/3 depend on $-, which bats itself never sets to interactive and
# which cannot be toggled with `set -i` after a shell has started (bash
# rejects it -- verified in-session). The module is therefore sourced inside
# a `bash --norc [-i] -c '...'` child, with `--norc` so no real ~/.bashrc
# leaks its own definitions of the two lib/bash_prompt collaborators into the
# stub environment. `mise` itself is stubbed as a shell function -- the
# module does `eval "$(mise activate bash[, --shims])"`, so the stub's
# printed line IS what gets eval'd, and each branch prints a distinct,
# harmless export so the test can tell which one fired.

load ../helpers/common

setup() {
  load_bats_libs

  MODULE="$(dotfiles_root)/config/shell-startup/mise"
}

# Source the module in a bash child with havecmd/mise/_bash_prompt_* stubbed,
# optionally interactive. Sets $output/$status via bats `run`; the child
# prints FULL_SET / SHIMS_SET itself (reading the FAKE_MISE_* vars the
# module's `eval` set) since subshell state can't otherwise cross back to
# this process, and _bash_prompt_reorder_hooks's stub prints REORDER_CALLED
# directly.
#   run_mise_module interactive|noninteractive <hooks_supported_rc>
run_mise_module() {
  local mode=$1 hooks_rc=$2
  local -a bashflags=(--norc)

  [[ $mode == interactive ]] && bashflags+=(-i)

  run bash "${bashflags[@]}" -c '
    module=$1
    hooks_rc=$2

    havecmd() { [[ $1 == mise ]]; }
    _bash_prompt_supports_hooks() { return "$hooks_rc"; }
    _bash_prompt_reorder_hooks() { echo REORDER_CALLED; }

    mise() {
      if [[ $1 == activate && $2 == bash && $3 == --shims ]]; then
        printf "export FAKE_MISE_SHIMS=1\n"
      elif [[ $1 == activate && $2 == bash ]]; then
        printf "export FAKE_MISE_FULL=1\n"
      fi
    }

    source "$module"

    [[ -n ${FAKE_MISE_FULL:-} ]]  && echo FULL_SET
    [[ -n ${FAKE_MISE_SHIMS:-} ]] && echo SHIMS_SET
    true
  ' _ "$MODULE" "$hooks_rc"
}

@test "no-op when mise is not installed" {
  # A marker FILE, not just a variable, because a call under eval/command
  # substitution runs in its own subshell -- a variable set there would not
  # be visible here, but a file write survives.
  local marker="$BATS_TEST_TMPDIR/mise_invoked"

  # shellcheck disable=SC2329  # invoked indirectly by the sourced module
  havecmd() { return 1; }
  # Would fail the test if ever invoked -- proves the early return
  # short-circuits before mise is touched at all.
  # shellcheck disable=SC2329  # invoked indirectly by the sourced module
  mise() {
    echo invoked >> "$marker"
    return 1
  }

  # shellcheck disable=SC1090  # module path resolved at runtime
  source "$MODULE"

  assert_file_not_exist "$marker"
}

@test "interactive with hook support runs full activation and reorders hooks" {
  run_mise_module interactive 0

  assert_success
  assert_output --partial 'FULL_SET'
  assert_output --partial 'REORDER_CALLED'
  refute_output --partial 'SHIMS_SET'
}

@test "interactive without hook support falls back to shims, no reorder" {
  run_mise_module interactive 1

  assert_success
  assert_output --partial 'SHIMS_SET'
  refute_output --partial 'FULL_SET'
  refute_output --partial 'REORDER_CALLED'
}

# The regression guard: a non-interactive shell used to skip the whole
# module (a standalone `[[ $- == *i* ]] || return 0` before the branch), so
# BASH_ENV / a script sourcing shell-startup non-interactively got no mise
# activation at all. Hook support is stubbed true here specifically to
# isolate the variable under test -- interactivity, not hook support -- so a
# regression back to the old guard is what turns this red, not a change to
# _bash_prompt_supports_hooks's own logic.
@test "non-interactive still activates mise via shims (regression)" {
  run_mise_module noninteractive 0

  assert_success
  assert_output --partial 'SHIMS_SET'
  refute_output --partial 'FULL_SET'
  refute_output --partial 'REORDER_CALLED'
}
