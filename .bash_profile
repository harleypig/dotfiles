#!/bin/bash

# For debugging login files, do:
#
# ssh -t localhost "PS4='+[\$BASH_SOURCE:\$LINENO]: ' BASH_XTRACEFD=7 bash -xl 7> login.trace"
#
# See https://unix.stackexchange.com/a/154971/9032

#---------------------------------------------------------------------------------------
# Environment Variables

export EDITOR=vim
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

export BROWSER='chromium-browser'

DOTFILES="$(dirname "$(readlink -nf "$HOME/.bash_profile")")"
export DOTFILES

# $HOME/.bashrc needs to exist so things like shelling from vim will load the
# dotfiles correctly. Warn if .bashrc doesn't point to the .bashrc in
# DOTFILES. If it doesn't exist, create the link.

if [[ ! -f $HOME/.bashrc ]]; then
  ln -s "$DOTFILES/.bashrc"
else
  [[ $(readlink -nf "$HOME/.bashrc") == "$DOTFILES/.bashrc" ]] || {
    echo "$HOME/.bashrc is not linked to DOTFILES version."
  }
fi

# shellcheck disable=SC1090
[[ -f $HOME/.bashrc ]] && source "$HOME/.bashrc"
