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

if command -v pacman > /dev/null; then
  command -v pacmatic > /dev/null 2>&1 && export PACMAN='pacmatic'
fi

if [[ -d "$HOME/projects/go" ]]; then
  export GOROOT="$HOME/projects/go"
  export GOPATH="$HOME/.go"
  export GOBIN="$HOME/.go/bin"
fi

#---------------------------------------------------------------------------------------
# This is for hman.
export BROWSER='chromium-browser'

# shellcheck disable=SC1090
[[ -f $HOME/.bashrc ]] && source "$HOME/.bashrc"
