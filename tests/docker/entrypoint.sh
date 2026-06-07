#!/bin/bash

# Default entrypoint for the dotfiles integration-test image. Deploys the
# minimal dotfiles entry points (so a login shell loads shell-startup), then
# execs bash with the passed arguments — so callers choose the shell mode:
#   docker run IMAGE -lc  'cmd'   # non-interactive login
#   docker run IMAGE -lic 'cmd'   # interactive login
#
# The repo under test is mounted read-only at /dotfiles. Tests that need a
# pristine HOME (e.g. exercising check-dotfiles' own symlink creation)
# override this entrypoint (`--entrypoint bash`) and invoke scripts directly.

set -euo pipefail

ln -sf /dotfiles/shell-startup "$HOME/.bash_profile"
ln -sf /dotfiles/shell-startup "$HOME/.bashrc"

exec bash "$@"
