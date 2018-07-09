#!/bin/bash

if ! [ -f "$HOME/.bash_functions" ]; then
  echo "$HOME/.bash_functions does not exist"
  exit 1
fi

# All other scripts depend on the functions defined here.
# shellcheck source=/home/harleypig/.bash_functions
source "$HOME/.bash_functions"

debug "After loading functions ..."

#---------------------------------------------------------------------------------------
# Don't delete this, it's for figuring things out sometimes.

if [[ $- == *i* ]]; then
  debug "We are interactive ..."
else
  debug "We are *not* interactive ..."
fi

if shopt -q login_shell; then
  debug "We are in a login shell ..."
else
  debug "We are *not* in a login shell ..."
fi

#---------------------------------------------------------------------------------------

# .bash_* (aside from .bash_prompt and .bashrc) are expected to be in whatever
# directory the repo is in. .bash_prompt and .bashrc should be linked to the
# same place, so DOT_BASH_DIR will be used for sourcing support files.

DOT_BASH_DIR=$(dirname "$(realpath "$HOME/.bash_profile")")
debug ".bash_dir: $DOT_BASH_DIR"

#---------------------------------------------------------------------------------------
debug "Setting up shell options ..."

CDPATH="."
PROMPT_DIRTRIM=2
HISTCONTROL="erasedups:ignoreboth"
HISTFILESIZE=100000
HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear"
HISTSIZE=500000
HISTTIMEFORMAT='%F %T '

bind "set completion-ignore-case on"
bind "set completion-map-case on"
bind "set mark-symlinked-directories on"
bind "set show-all-if-ambiguous on"
bind Space:magic-space

shopt -s autocd 2> /dev/null
shopt -s cdable_vars
shopt -s cdspell 2> /dev/null
shopt -s checkhash
shopt -s checkwinsize
shopt -s cmdhist
shopt -s dirspell 2> /dev/null
shopt -s dotglob
shopt -s globstar 2> /dev/null
shopt -s histappend
shopt -s histreedit
shopt -s histverify
shopt -s nocaseglob
shopt -s nocaseglob;

umask 022

#---------------------------------------------------------------------------------------
# Simple check and source lines

# shellcheck disable=SC1090
[[ -z $SSH_AUTH_SOCK && -r $HOME/.ssh-agent ]] && source "$HOME/.ssh-agent"

[[ -f $HOME/.Xresources ]] && xrdb "$HOME/.Xresources"

declare -a FILES

# Order matters, don't mess with the order.
FILES+=('/etc/bash_completion')
FILES+=('/etc/profile.d/bash-completion')
FILES+=('/.travis/travis.sh')
FILES+=('/usr/share/nvm/init-nvm.sh')
FILES+=('.task/completion/task-completion.sh')

for file in "${FILES[@]}"; do
  # shellcheck disable=SC1090
  [[ -f $file ]] && source "$file"
done

if [[ -d "${HOME}/projects/nvm" ]]; then
  export NVM_DIR="$HOME/projects/nvm"
  # shellcheck disable=SC1090
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "${NVM_DIR}/nvm.sh"
fi

# shellcheck disable=SC1090
command -v npm &> /dev/null && source <(npm completion)

# shellcheck disable=SC1090
[[ -f $HOME/bin/tokens ]] && source "$HOME/bin/tokens"

#---------------------------------------------------------------------------------------
# Load source files

# shellcheck disable=SC1091
source_dir "$DOT_BASH_DIR/.bash_sources.d"

#---------------------------------------------------------------------------------------
# Setup prompt command

# shellcheck disable=SC1090
source "$DOT_BASH_DIR/.bash_prompt"

#---------------------------------------------------------------------------------------
# Source any files we find in our host specific directory

# shellcheck disable=SC1091
source_dir "$DOT_BASH_DIR/$HOSTNAME"

#---------------------------------------------------------------------------------------
# Source any local files

# shellcheck disable=SC1091
source_dir "$HOME/.bash_local"

#---------------------------------------------------------------------------------------
# Source sekrets.

# shellcheck disable=SC1091
source_dir "$HOME/.sekrets"

#---------------------------------------------------------------------------------------
# PATH setup

# Run this last to allow for other stuff above modifying the path

rbenv_bin=$(command -v rbenv &>/dev/null)
if [[ -d $HOME/.rbenv ]] && [[ -n $rbenv_bin ]]; then
  PATH="$HOME/.rbenv/plugins/ruby-build/bin:$HOME/.rbenv/bin:${PATH}"
  eval "$(rbenv init -)"
fi

# Do not alphabetize, order is important here.
# XXX: Use add_path function instead here.
# XXX: Add cleanup ability to add_path function.

BIN_DIRS="${BIN_DIRS} ${HOME}/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/.vim/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/.cabal/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/.minecraft/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/Dropbox/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/videos/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/projects/depot_tools"
BIN_DIRS="${BIN_DIRS} ${HOME}/projects/dotfiles/bin"
BIN_DIRS="${BIN_DIRS} ${HOME}/projects/android-sdk/tools"
BIN_DIRS="${BIN_DIRS} ${HOME}/projects/android-sdk/platform-tools"
BIN_DIRS="${BIN_DIRS} /usr/lib/dart/bin"
BIN_DIRS="${BIN_DIRS} ${GOROOT}/bin"
BIN_DIRS="${BIN_DIRS} ${GOPATH}/bin"

for d in $BIN_DIRS; do

  dir=$(realpath "$d")

  # shellcheck disable=SC2154
  if [[ -d $dir ]] && [[ $PATH != *"$dir"* ]]; then
    PATH="${PATH}:${dir}"
  fi
done

PATH="${PATH}:."
export PATH

debug "Exiting ..."

alias one='echo two three'
