#!/usr/bin/env bats

# Integration tests for bin/check-dotfiles, run in a throwaway container so its
# `ln -fs` into $HOME can never touch the host — the container IS the sandbox.
# Skips when docker is unavailable.

# shellcheck disable=SC2016  # $VARs run in the container's shell, not here.

load ../helpers/common

setup() {
  load_bats_libs
  require_docker
  IMAGE="$(dotfiles_harness_image)"
}

# Run a command directly (bypassing the login-shell entrypoint) so check-dotfiles
# starts from a pristine HOME. An optional second argument sets the container's
# hostname, which selects the per-host dotlinks file. Sets $output/$status via
# bats `run`.
in_container() {
  local -a host=()
  [[ -n ${2:-} ]] && host=(--hostname "$2")

  run docker run --rm "${host[@]}" -v "$(dotfiles_root):/dotfiles:ro" \
    --entrypoint bash "$IMAGE" -c "$1"
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

# A link under a directory that does not exist yet (~/.config/user-tmpfiles.d
# on a fresh host): ln alone fails, so the parent must be created first.
@test "check-dotfiles creates a missing parent directory for a nested link" {
  in_container '
    export DOTFILES=/dotfiles
    printf "\$DOTFILES/dotlinks-default .new/nested/dir/link\n" > "$HOME/.dotlinks"
    /dotfiles/bin/check-dotfiles
    echo "nested -> $(readlink "$HOME/.new/nested/dir/link")"
  '
  assert_success
  assert_output --partial 'nested -> /dotfiles/dotlinks-default'
}

# The per-host file is chosen by hostname alone (#625 - one gate for host
# settings). user-tmpfiles.d/tmp.conf is listed only in dotlinks-harleypig.com,
# so its link says which file was read.
@test "check-dotfiles uses dotlinks-\$HOSTNAME when ~/.dotlinks is absent" {
  in_container '
    export DOTFILES=/dotfiles
    rm -f "$HOME/.dotlinks"
    /dotfiles/bin/check-dotfiles
    echo "tmpfiles -> $(readlink "$HOME/.config/user-tmpfiles.d/tmp.conf")"
  ' harleypig.com
  assert_success
  assert_output --partial 'tmpfiles -> /dotfiles/config/user-tmpfiles.d/tmp.conf'
}

@test "check-dotfiles prefers ~/.dotlinks over dotlinks-\$HOSTNAME" {
  in_container '
    export DOTFILES=/dotfiles
    rm -f "$HOME/.bash_logout"
    printf "\$DOTFILES/dot-general/.bash_logout\n" > "$HOME/.dotlinks"
    /dotfiles/bin/check-dotfiles
    echo "logout -> $(readlink "$HOME/.bash_logout")"
    [[ -e "$HOME/.config/user-tmpfiles.d/tmp.conf" ]] \
      && echo "tmpfiles linked" || echo "tmpfiles absent"
  ' harleypig.com
  assert_success
  assert_output --partial 'logout -> /dotfiles/dot-general/.bash_logout'
  assert_output --partial 'tmpfiles absent'
}

@test "check-dotfiles falls back to dotlinks-default with no host file" {
  in_container '
    export DOTFILES=/dotfiles
    rm -f "$HOME/.dotlinks" "$HOME/.bash_logout"
    /dotfiles/bin/check-dotfiles
    echo "logout -> $(readlink "$HOME/.bash_logout")"
    [[ -e "$HOME/.config/user-tmpfiles.d/tmp.conf" ]] \
      && echo "tmpfiles linked" || echo "tmpfiles absent"
  ' no-such-host
  assert_success
  assert_output --partial 'logout -> /dotfiles/dot-general/.bash_logout'
  assert_output --partial 'tmpfiles absent'
}

# dotlinks-sweetums named a .bash_logout at the repo root, which does not
# exist; check_link skips a missing source silently, so nothing was linked.
@test "check-dotfiles links .bash_logout from dotlinks-sweetums" {
  in_container '
    export DOTFILES=/dotfiles
    rm -f "$HOME/.dotlinks" "$HOME/.bash_logout"
    /dotfiles/bin/check-dotfiles
    echo "logout -> $(readlink "$HOME/.bash_logout")"
  ' sweetums
  assert_success
  assert_output --partial 'logout -> /dotfiles/dot-general/.bash_logout'
}
