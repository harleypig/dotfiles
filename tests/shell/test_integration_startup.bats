#!/usr/bin/env bats

# Integration tests for dotfiles startup, run in a throwaway container (the
# repo mounted read-only at /dotfiles) so a real login shell is exercised
# without touching the host. Skips when docker is unavailable.
#
# These confirm startup *functions* — a login shell comes up with the
# expected environment — not merely that the scripts parse.

# shellcheck disable=SC2016  # $VARs in the command strings are evaluated in
# the container's shell, not here — deliberately single-quoted.

load ../helpers/common

setup() {
  load_bats_libs
  IMAGE="$(dotfiles_harness_image)"
}

@test "a login shell comes up with DOTFILES, XDG, and bin on PATH" {
  dotfiles_login "$IMAGE" '
    echo "DOTFILES=$DOTFILES"
    echo "XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
    case ":$PATH:" in
      *:/dotfiles/bin:*) echo binpath=yes ;;
      *) echo binpath=no ;;
    esac
  '
  assert_success
  assert_output --partial 'DOTFILES=/dotfiles'
  assert_output --partial 'XDG_CONFIG_HOME=/dotfiles/config'
  assert_output --partial 'binpath=yes'
}

@test "the double-source guard prevents a re-source from changing PATH" {
  dotfiles_login "$IMAGE" '
    before="$PATH"
    source /dotfiles/shell-startup
    [[ "$before" == "$PATH" ]] && echo guard=ok || echo guard=FAILED
  '
  assert_success
  assert_output --partial 'guard=ok'
}

@test "PATH has no duplicate /dotfiles/bin entry (cleanpath integrated)" {
  # Label the count so it is distinguishable from any startup stdout (e.g.
  # check-dotfiles notices).
  dotfiles_login "$IMAGE" \
    'echo "dupcount=$(tr ":" "\n" <<< "$PATH" | grep -c "^/dotfiles/bin$")"'
  assert_success
  assert_output --partial 'dupcount=1'
}
