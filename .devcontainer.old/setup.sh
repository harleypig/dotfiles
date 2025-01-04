#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Print all commands before executing them (useful for debugging)
set -x

# Define the path to the dotfiles directory and the shell-startup script
DOTFILES_DIR="/workspaces/.codespaces/.persistedshare/dotfiles"
SHELL_STARTUP_SCRIPT="$DOTFILES_DIR/shell-startup"

# Remove existing .bash_profile and .bashrc before linking
rm -f $HOME/.bash_profile
rm -f $HOME/.bashrc

# Link .bash_profile to the shell-startup script
ln -s "$SHELL_STARTUP_SCRIPT" $HOME/.bash_profile

# Link .bashrc to the shell-startup script
ln -s "$SHELL_STARTUP_SCRIPT" $HOME/.bashrc

# Display a message indicating the script has run successfully
echo "Successfully linked .bash_profile and .bashrc to $SHELL_STARTUP_SCRIPT"
