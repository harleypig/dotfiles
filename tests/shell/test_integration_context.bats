#!/usr/bin/env bats

# Context-matrix integration tests: a login shell must bring up the base
# environment in every context, but interactive-only setup (the prompt) must
# run only in interactive shells. Verifies the existing per-module guards
# (e.g. bash_prompt) hold across contexts. Skips when docker is unavailable.

# shellcheck disable=SC2016  # $VARs run in the container's shell, not here.

load ../helpers/common

setup() {
  load_bats_libs
  IMAGE="$(dotfiles_harness_image)"
}

@test "non-interactive login: env comes up, but no prompt or aliases" {
  dotfiles_login "$IMAGE" '
    echo "DOTFILES=$DOTFILES"
    echo "xdg=${XDG_CONFIG_HOME:+set}"
    echo "pylint=${PYLINTRC:+set}"
    echo "prompt=[${PS1:+set}]"
    echo "pyalias=$(alias python > /dev/null 2>&1 && echo yes || echo no)"
  '
  assert_success
  assert_output --partial 'DOTFILES=/dotfiles'
  assert_output --partial 'xdg=set'
  # Env-only module content still runs (the python module sets PYLINTRC)...
  assert_output --partial 'pylint=set'
  # ...but interactive-only content is guarded out (bash_prompt prompt, and
  # the python module's `alias python`).
  assert_output --partial 'prompt=[]'
  assert_output --partial 'pyalias=no'
}

@test "interactive login: env comes up AND the prompt + aliases are set" {
  dotfiles_login_interactive "$IMAGE" '
    echo "DOTFILES=$DOTFILES"
    echo "prompt=[${PS1:+set}]"
    echo "pyalias=$(alias python > /dev/null 2>&1 && echo yes || echo no)"
  '
  assert_success
  assert_output --partial 'DOTFILES=/dotfiles'
  assert_output --partial 'prompt=[set]'
  assert_output --partial 'pyalias=yes'
}
