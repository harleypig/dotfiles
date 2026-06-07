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

@test "interactive non-login (reads .bashrc): env + prompt + aliases" {
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" "$IMAGE" -ic '
    echo "DOTFILES=$DOTFILES"
    echo "prompt=[${PS1:+set}]"
    echo "pyalias=$(alias python > /dev/null 2>&1 && echo yes || echo no)"
  '
  assert_success
  assert_output --partial 'DOTFILES=/dotfiles'
  assert_output --partial 'prompt=[set]'
  assert_output --partial 'pyalias=yes'
}

@test "non-interactive non-login shell does not load the dotfiles" {
  # bash -c reads neither .bash_profile nor .bashrc, so shell-startup never
  # runs — scripts/subshells must not inherit the interactive setup.
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" "$IMAGE" -c \
    'echo "dotfiles=[${DOTFILES-}]"'
  assert_success
  assert_output --partial 'dotfiles=[]'
}

@test "interactive shell with TERM unset comes up without tput errors" {
  # Incomplete terminal (cron, non-tty ssh command): TERM unset. ansi falls
  # back to a usable TERM so the prompt path emits no tput errors.
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" --entrypoint bash \
    "$IMAGE" -c '
      unset TERM
      ln -sf /dotfiles/shell-startup "$HOME/.bash_profile"
      ln -sf /dotfiles/shell-startup "$HOME/.bashrc"
      exec bash -lic "ansi fg red > /dev/null; echo started=ok"
    '
  assert_success
  assert_output --partial 'started=ok'
  refute_output --partial 'No value for $TERM'
}
