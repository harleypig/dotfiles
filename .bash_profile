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

command -v chromium-browser &> /dev/null && export BROWSER='chromium-browser'

DOTFILES="$(dirname "$(readlink -nf "$HOME/.bash_profile")")"
export DOTFILES

# These should not be exported

CDPATH="."
PROMPT_DIRTRIM=2
HISTCONTROL="erasedups:ignoreboth"
HISTFILESIZE=100000
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
HISTSIZE=500000
HISTTIMEFORMAT='%F %T '

#---------------------------------------------------------------------------------------
debug "Setting up shell options ..."

bind "set completion-ignore-case on"
bind "set completion-map-case on"
bind "set mark-symlinked-directories on"
bind "set show-all-if-ambiguous on"
bind Space:magic-space

shopt -s autocd 2> /dev/null
shopt -s cdspell 2> /dev/null
shopt -s dirspell 2> /dev/null
shopt -s globstar 2> /dev/null

shopt -s cdable_vars
shopt -s checkhash
shopt -s checkwinsize
shopt -s cmdhist
shopt -s dotglob
shopt -s histappend
shopt -s histreedit
shopt -s histverify
shopt -s nocaseglob

umask 022

#---------------------------------------------------------------------------------------
# $HOME/.bashrc needs to exist so things like shelling from vim will load the
# dotfiles correctly. Warn if .bashrc doesn't point to the .bashrc in
# DOTFILES. If it doesn't exist, create the link.

if [[ ! -f $HOME/.bashrc ]]; then
  ln -s "$DOTFILES/.bashrc" "$HOME/.bashrc"
else
  [[ $(readlink -nf "$HOME/.bashrc") == "$DOTFILES/.bashrc" ]] || {
    echo "$HOME/.bashrc is not linked to DOTFILES version."
  }
fi

#---------------------------------------------------------------------------------------
# shellcheck disable=SC1090
[[ -f $HOME/.bashrc ]] && source "$HOME/.bashrc"
