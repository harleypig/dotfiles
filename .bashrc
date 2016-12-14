#!/bin/bash

DEBUG_PREFIX=${BASH_SOURCE#$HOME/}

__debugit () {
  if [ -f ~/.dot_debug ]; then
    echo "$@" >> ~/.dotfiles_$$_$(date +%s).log
  fi
}

__debugit "${DEBUG_PREFIX}:$LINENO Entering ..."

########################################################################
# Don't delete this, it's for figuring things out sometimes.

#if [[ $- == *i* ]]; then
#  __debugit "${DEBUG_PREFIX} We are interactive ..."
#else
#  __debugit "${DEBUG_PREFIX} We are *not* interactive ..."
#fi
#
#if shopt -q login_shell; then
#  __debugit "${DEBUG_PREFIX} We are in a login shell ..."
#else
#  __debugit "${DEBUG_PREFIX} We are *not* in a login shell ..."
#fi
########################################################################

# Determines the fully qualified path of a file and sets $1 to the path.
# NOTE: Does not validate the path or file.
# Expects, in order:
#   The name of the variable to be set.
#   The name of the path to fully qualify.

__realpath () {

  local varname=$1  ; shift
  local filename=$1 ; shift

  fqfn=${filename//\~/$HOME}
  fqfn=$(readlink -nf $fqfn)

  printf -v "${varname}" "%s" "$fqfn"

}

# Builds a fully qualified path and sets $1 to the value.
# NOTE: Does not validate the path or file.
# Expects, in order:
#   The name of the variable to be set.
#   The name of the file to determine where to load files from.
#   The endpoint the path should have.

__buildpath () {

  local varname=$1    ; shift
  local sourcefile=$1 ; shift
  local endpoint=$1   ; shift

  __realpath 'realpath' "$sourcefile"
  realpath=$(dirname $realpath)

  printf -v "$varname" '%s' "${realpath}${endpoint}"

}

# Sources all files found in $1.
__source_files () {

  __debugit "${DEBUG_PREFIX}:${LINENO} Trying to source $1 ..."

  for s in $(ls $1 2> /dev/null); do
    __debugit "${DEBUG_PREFIX}:${LINENO} Sourcing $s ..."
    source $s

  done
}

# Sources all files found in either a hostspecific directory or a default directory.
__source_host_specific () {

  local endpoint="$1"
  local hostname=$(hostname)

  __buildpath 'path' "${BASH_SOURCE}" '/hostspecific'

  if [ -d "${path}/${hostname}" ]; then
    path="${path}/${hostname}/${endpoint}"
  else
    path="${path}/default/${endpoint}"
  fi

  __source_files $path

}

########################################################################
# Environment Variables

export EDITOR=vim
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

command -v pacmatic > /dev/null 2>&1 && export PACMAN='pacmatic'

########################################################################
# PATH setup

if [[ -d ~/.rbenv ]]; then

  PATH="~/.rbenv/plugins/ruby-build/bin:~/.rbenv/bin:${PATH}"
  eval "$(rbenv init -)"

fi

# Do not alphabetize, order is important here.

BIN_DIRS="${BIN_DIRS} ~/bin"
BIN_DIRS="${BIN_DIRS} ~/.vim/bin"
BIN_DIRS="${BIN_DIRS} ~/.cabal/bin"
BIN_DIRS="${BIN_DIRS} ~/.minecraft/bin"
BIN_DIRS="${BIN_DIRS} ~/Dropbox/bin"
BIN_DIRS="${BIN_DIRS} ~/videos/bin"
BIN_DIRS="${BIN_DIRS} ~/projects/depot_tools"
BIN_DIRS="${BIN_DIRS} ~/projects/dotfiles/bin"
BIN_DIRS="${BIN_DIRS} ~/projects/android-sdk/tools"
BIN_DIRS="${BIN_DIRS} ~/projects/android-sdk/platform-tools"

for d in $BIN_DIRS; do

  __realpath 'dir' "$d"

  if [[ -d $dir ]] && [[ $PATH != *"$dir"* ]]; then
      PATH="${PATH}:${dir}"

  fi
done

PATH="${PATH}:."
export PATH

########################################################################

if [[ $- != *i* ]]; then
  # non-interactive shell, nothing else to do.
  __debugit "${DEBUG_PREFIX}:$LINENO Non-interactive shell, done."
  return
fi

shopt -s checkhash
shopt -s checkwinsize
shopt -s dotglob
shopt -s nocaseglob

umask 022

########################################################################################
# Load application specific files.

__buildpath 'SOURCES' "${BASH_SOURCE}" "/.bash_sources.d/*"
__source_files "$SOURCES"

########################################################################################
# Simple check and source lines

[[ -f ~/.Xresources                  ]] && xrdb ~/.Xresources
[[ -f /etc/bash_completion           ]] && source /etc/bash_completion
[[ -f /etc/profile.d/bash-completion ]] && source /etc/profile.d/bash-completion
[[ -f ~/.bash_functions              ]] && source ~/.bash_functions
[[ -f ~/.bash_prompt                 ]] && source ~/.bash_prompt
[[ -f /.travis/travis.sh             ]] && source /.travis/travis.sh
[[ -f /usr/share/nvm/init-nvm.sh     ]] && source /usr/share/nvm/init-nvm.sh

[[ -z $SSH_AUTH_SOCK && -f ~/.ssh-agent && -r ~/.ssh-agent ]] && source ~/.ssh-agent

command -v npm > /dev/null 2>&1 && source <(npm completion)

if [[ -d ~/.bash_completion.d ]]; then
  __buildpath 'COMPLETION' "${BASH_SOURCE}" '/.bash_completion.d/*'
  __source_files $COMPLETION
#  for s in $(ls $COMPLETION 2> /dev/null); do source $s; done
fi

[[ $(type setup-bash-complete 2> /dev/null) ]] && source setup-bash-complete

[[ -f ~/bin/tokens ]] && source ~/bin/tokens

########################################################################################
# Source any files we find in our host specific directory

__source_host_specific '*bashrc*'
#__buildpath 'HOSTSPECIFIC' "${BASH_SOURCE}" "/hostspecific/$(hostname)/*bashrc*"
#__source_files $HOSTSPECIFIC

########################################################################################
# Source any private files

__buildpath 'PRIVATE' "${HOME}" '/.bash_private.d'
__source_files $PRIVATE

[[ -f ~/.sekrets ]] && source ~/.sekrets

__debugit "${DEBUG_PREFIX}:$LINENO Exiting ..."
