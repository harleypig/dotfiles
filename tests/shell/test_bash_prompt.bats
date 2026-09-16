#!/usr/bin/env bats

# Tests for lib/bash_prompt's per-render helper functions: _exit_status,
# _venv, _get_next_prompt_char, and _parent.
#
# bash_prompt is a *sourced* file that guards on an interactive shell
# (`[[ $- == *i* ]] || return 0`) and so bails before defining anything in a
# non-interactive test shell. It also reads prompt-color vars its
# config/shell-startup wrapper computes once at load time. So setup() strips
# that interactive-guard block, sets sentinel colors, and evals the result to
# exercise the real function bodies in isolation — the same in-isolation
# approach as test_havecmd.
#
# _update_prompt is intentionally NOT unit-tested here: it orchestrates many
# external commands (loadavg, dir-readable, git-status) and shell history
# state, and is covered in aggregate by test_integration_context.

load ../helpers/common

# Strip the `[[ $- == *i* ]] || { ... }` interactive-guard block so the
# function definitions below it load in this non-interactive shell. Only the
# guard block is removed; the rest of the file is eval'd verbatim.
strip_interactive_guard() {
  awk '
    /\[\[ \$- == \*i\* \]\] \|\|/ { inguard = 1; next }
    inguard && /^\}/              { inguard = 0; next }
    inguard                       { next }
    { print }
  ' "$(dotfiles_root)/lib/bash_prompt"
}

setup() {
  load_bats_libs

  # Sentinel prompt colors (the wrapper computes these once at load time).
  # shellcheck disable=SC2034  # read by the eval'd bash_prompt functions
  exit_good_color=GOOD exit_bad_color=BAD color_off=OFF
  # shellcheck disable=SC2034  # read by the eval'd bash_prompt functions
  venv_ok_color=VOK venv_bad_color=VBAD venv_poetry_color=VPOE

  # The trailing `true` keeps the lib's benign falsy last line
  # (`[[ -n $PS1 ]] && PROMPT_COMMAND=...`, false when PS1 is empty) from
  # failing setup; a real syntax error in the source still aborts the eval.
  eval "$(strip_interactive_guard)
true"
}

@test "_exit_status marks 0 and 141 good, other codes bad" {
  run _exit_status 0 1 141
  assert_success
  assert_output --partial 'GOOD 0 OFF'
  assert_output --partial 'BAD 1 OFF'
  assert_output --partial 'GOOD 141 OFF'
}

@test "_get_next_prompt_char returns a character from the rotation set" {
  run _get_next_prompt_char
  assert_success
  refute_output ''
  # shellcheck disable=SC2154  # PROMPT_CHARS is defined by the eval'd lib
  printf '%s\n' "${PROMPT_CHARS[@]}" | grep -qxF "$output"
}

@test "_venv prints nothing outside any virtualenv" {
  unset VIRTUAL_ENV POETRY_ACTIVE
  run _venv
  assert_success
  assert_output ''
}

@test "_venv flags an active poetry environment" {
  POETRY_ACTIVE=1 run _venv
  assert_success
  assert_output --partial 'poetry venv'
}

@test "_venv labels a venv whose project matches \$PWD as ok" {
  cd "$BATS_TEST_TMPDIR"
  local here
  here=$(readlink -ne "$PWD")
  VIRTUAL_ENV="$here/.venv" run _venv
  assert_success
  assert_output --partial '(venv)'
}

@test "_parent returns nothing when pstree is unavailable" {
  unset _HAS_PSTREE
  run _parent
  assert_success
  assert_output ''
}

# _capture_exit_status must run as the very next statement after the command
# whose PIPESTATUS it captures -- any intervening command (even `local`)
# resets PIPESTATUS first and the function would capture the wrong thing.
# `if false; then :; fi` runs `false` as the condition (leaving PIPESTATUS
# from that evaluation) without executing a `then` body that would reset it,
# and without the bare `false` aborting the test under bats' errexit
# behavior.

@test "_capture_exit_status captures a single command's exit status" {
  if false; then :; fi
  _capture_exit_status
  # shellcheck disable=SC2154  # _prompt_pipestatus is set by the call above
  assert_equal "${#_prompt_pipestatus[@]}" 1
  assert_equal "${_prompt_pipestatus[0]}" 1
}

@test "_capture_exit_status captures every stage of a pipeline" {
  false | true
  _capture_exit_status
  # shellcheck disable=SC2154  # _prompt_pipestatus is set by the call above
  assert_equal "${#_prompt_pipestatus[@]}" 2
  assert_equal "${_prompt_pipestatus[0]}" 1
  assert_equal "${_prompt_pipestatus[1]}" 0
}

@test "_bash_prompt_reorder_hooks pins the two prompt hooks first, keeps a real extra hook, and drops a bogus entry" {
  _fake_tool_hook() { :; }

  PROMPT_COMMAND=(_fake_tool_hook _nonexistent_hook_xyz _update_prompt _capture_exit_status)

  _bash_prompt_reorder_hooks

  local -a expected=(_capture_exit_status _update_prompt _fake_tool_hook)
  assert_equal "${#PROMPT_COMMAND[@]}" "${#expected[@]}"

  local i
  for i in "${!expected[@]}"; do
    assert_equal "${PROMPT_COMMAND[$i]}" "${expected[$i]}"
  done
}

# BASH_VERSINFO is readonly, so the pre-5.1 false branch can't be exercised
# here without a separate bash binary -- documented as a known gap rather
# than silently omitted.

@test "_bash_prompt_supports_hooks succeeds on this bash (5.1+)" {
  run _bash_prompt_supports_hooks
  assert_success
}
