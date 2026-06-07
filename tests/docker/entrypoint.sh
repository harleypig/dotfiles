#!/bin/bash

# Default entrypoint for the dotfiles integration-test image. Deploys the
# minimal dotfiles entry points (so a login shell loads shell-startup), then
# runs a login shell with the arguments as its command.
#
# The repo under test is mounted read-only at /dotfiles. Tests that need a
# pristine HOME (e.g. exercising check-dotfiles' own symlink creation)
# override this entrypoint (`--entrypoint bash`) and invoke scripts directly.

set -euo pipefail

ln -sf /dotfiles/shell-startup "$HOME/.bash_profile"
ln -sf /dotfiles/shell-startup "$HOME/.bashrc"

exec bash -lc "$*"
