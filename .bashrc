#!/bin/bash

DEBUG_PREFIX=${BASH_SOURCE#$HOME/}

__debugit () {
  if [ -f ~/.dot_debug ]; then
    echo "$@" >> ~/.dotfiles_$$_$(date +%s).log
  fi
}

__debugit "${DEBUG_PREFIX}:$LINENO Entering ..."

# XXX: Does __can256 belong in the general utlities file?
__can256 () { [ $(tput Co 2> /dev/null || tput colors 2> /dev/null || echo 0) -gt 2 ] ; }

__realdir () { printf -v "$1" "%s" $(dirname $(readlink -nf "$2")) ; }

__buildpath () {

  local varname=$1    ; shift
  local sourcefile=$1 ; shift
  local endpoint=$1   ; shift

  __realdir 'REALDIR' "$sourcefile"

  printf -v "$varname" '%s' "${REALDIR}${endpoint}"

}


__source_files () {

  for s in $(ls "$1" 2> /dev/null); do
    __debugit "${DEBUG_PREFIX}:$LINENO Sourcing $s ..."
    source $s

  done
}

__source_host_specific () {

  local endpoint=$1
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

  dir=${d//\~/$HOME}
  dir=$(readlink -nf $dir)

  if [[ -d $dir ]] && [[ $PATH != *"$dir"* ]]; then
      PATH="${PATH}:${dir}"

  fi
done

PATH="${PATH}:."
export PATH

########################################################################
# Environment Variables

export EDITOR=vim
export HISTCONTROL='ignorespace:erasedups'
export HISTFILESIZE=1000
export HISTSIZE=1000
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PACMAN='pacmatic'

########################################################################

if [[ $- != *i* ]]; then
  # non-interactive shell, nothing else to do.
  __debugit "${DEBUG_PREFIX}:$LINENO Non-interactive shell, done."
  return
fi

shopt -s checkhash
shopt -s checkwinsize
shopt -s cmdhist
shopt -s dotglob
shopt -s histappend
shopt -s histreedit
shopt -s histverify
shopt -s nocaseglob

umask 022

########################################################################################
# Simple check and source lines

# This eval needs to be included in .bashrc because some of it will be lost
# when switching to an interactive shell.
if [[ -d ~/.rbenv ]]; then
  eval "$(rbenv init -)"
fi

[[ -f ~/.Xresources                  ]] && xrdb ~/.Xresources
[[ -s "$HOME/.rvm/scripts/rvm"       ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
[[ -f /etc/bash_completion           ]] && source /etc/bash_completion
[[ -f /etc/profile.d/bash-completion ]] && source /etc/profile.d/bash-completion
[[ -f ~/.ssh-agent                   ]] && source ~/.ssh-agent
[[ -f ~/.bash_aliases                ]] && source ~/.bash_aliases
[[ -f ~/.bash_functions              ]] && source ~/.bash_functions
[[ -f ~/.bash_prompt                 ]] && source ~/.bash_prompt
[[ -f /.travis/travis.sh             ]] && source /.travis/travis.sh
[[ -f /usr/share/nvm/init-nvm.sh     ]] && source /usr/share/nvm/init-nvm.sh
[[ -f $rvm_path/scripts/completion   ]] && source $rvm_path/scripts/completion

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

__buildpath 'HOSTSPECIFIC' "${BASH_SOURCE}" "/hostspecific/$(hostname)/*bashrc*"
__source_files $HOSTSPECIFIC

########################################################################################
# Source any private files

PRIVATE="${HOME}/.bash_private.d"
__source_files $PRIVATE

[[ -f ~/.sekrets ]] && source ~/.sekrets

__debugit "${DEBUG_PREFIX}:$LINENO Exiting ..."
