#!/usr/bin/env bats

# Integration tests for bin/check-dotfiles, run in a throwaway container so its
# `ln -fs` into $HOME can never touch the host — the container IS the sandbox.
# Skips when docker is unavailable.

# shellcheck disable=SC2016  # $VARs run in the container's shell, not here.

load ../helpers/common

setup() {
  load_bats_libs
  IMAGE="$(dotfiles_harness_image)"
}

# Run a command directly (bypassing the login-shell entrypoint) so check-dotfiles
# starts from a pristine HOME. Sets $output/$status via bats `run`.
in_container() {
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" --entrypoint bash \
    "$IMAGE" -c "$1"
}

@test "check-dotfiles links the shell entry points to shell-startup" {
  in_container '
    export DOTFILES=/dotfiles
    rm -f "$HOME/.bash_profile" "$HOME/.bashrc" "$HOME/.profile"
    /dotfiles/bin/check-dotfiles
    for f in .bash_profile .bashrc .profile; do
      echo "$f -> $(readlink "$HOME/$f")"
    done
  '
  assert_success
  assert_output --partial '.bash_profile -> /dotfiles/shell-startup'
  assert_output --partial '.bashrc -> /dotfiles/shell-startup'
  assert_output --partial '.profile -> /dotfiles/shell-startup'
}

@test "check-dotfiles reports a mismatched link without clobbering it" {
  in_container '
    export DOTFILES=/dotfiles
    ln -sf /etc/hostname "$HOME/.bash_profile"
    /dotfiles/bin/check-dotfiles
    echo "still -> $(readlink "$HOME/.bash_profile")"
  '
  assert_success
  assert_output --partial ".bash_profile is not linked to /dotfiles/shell-startup"
  assert_output --partial 'still -> /etc/hostname'
}

@test "check-dotfiles honours .nochecklinks" {
  in_container '
    export DOTFILES=/dotfiles
    rm -f "$HOME/.bash_profile"
    touch "$HOME/.nochecklinks"
    /dotfiles/bin/check-dotfiles
    [[ -e "$HOME/.bash_profile" ]] && echo created || echo skipped
  '
  assert_success
  assert_output --partial 'skipped'
}
