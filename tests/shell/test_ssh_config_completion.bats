#!/usr/bin/env bats

# config/shell-startup/ssh-config-completion defines the _ssh completion
# function. Regression for the env-pollution-hygiene fix: its SSH_KNOWN_HOSTS /
# SSH_CONFIG_HOSTS arrays must be `local` so they don't leak into the global
# shell every time completion runs.

load ../helpers/common

setup() {
  load_bats_libs

  eval "$(source_funcs \
    "$(dotfiles_root)/config/shell-startup/ssh-config-completion" _ssh)"

  # Fake ~/.ssh so the readarray/read pipelines inside _ssh have real input.
  HOME="$BATS_TEST_TMPDIR"
  mkdir -p "$HOME/.ssh"
  printf 'host-a ssh-rsa AAAA\nhost-b ssh-rsa BBBB\n' > "$HOME/.ssh/known_hosts"
  printf 'Host cfg-a\n  User me\n' > "$HOME/.ssh/config"
}

@test "_ssh registers a word-list completion for ssh" {
  _ssh

  run complete -p ssh
  assert_success
  assert_output --partial 'host-a'
  assert_output --partial 'cfg-a'
}

@test "_ssh does not leak SSH_KNOWN_HOSTS / SSH_CONFIG_HOSTS into the shell" {
  _ssh

  [ -z "${SSH_KNOWN_HOSTS+set}" ]
  [ -z "${SSH_CONFIG_HOSTS+set}" ]
}
