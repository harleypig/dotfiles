#!/bin/bash

# http://www.catonmat.net/series/bash-one-liners-explained
# http://www.catonmat.net/blog/bash-one-liners-explained-part-four/
# http://www.catonmat.net/blog/the-definitive-guide-to-bash-command-line-history/

# .bashrc is called when shelling from vim or creating a new screen instance.

# We repeat these here and export for general use. See .bash_profile for more info.

__debugit () {
  if [ -f ~/.dot_debug ]; then
    echo "${BASH_SOURCE}:$@" >> ~/.dotfiles_$$.log
  fi
}
export -f __debugit

__debugit "$LINENO Entering ..."

# XXX: Does __can256 belong in the general utlities file?
__can256 () { [ $(tput Co 2> /dev/null || tput colors 2> /dev/null || echo 0) -gt 2 ] ; }
export -f __can256

__realdir () { printf -v "$1" "%s" $(dirname $(readlink -nf "$2")) ; }
export -f __realdir

__buildpath () {

  local varname=$1    ; shift
  local sourcefile=$1 ; shift
  local endpoint=$1   ; shift

  __realdir 'REALDIR' "$sourcefile"

  printf -v "$varname" '%s' "${REALDIR}${endpoint}"

}
export -f __buildpath

__source_host_specific () {

  local endpoint=$1
  local hostname=$(hostname)

  __buildpath 'path' "${BASH_SOURCE}" '/hostspecific'

  if [ -d "${path}/${hostname}" ]; then
    path="${path}/${hostname}/${endpoint}"
  else
    path="${path}/default/${endpoint}"
  fi

  for s in $(ls $path 2> /dev/null); do
    source $s

  done
}
export -f __source_host_specific

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
  __debugit "$LINENO Non-interactive shell, done."
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
# less setup
# XXX: this section should be in its own file in a .d directory.

export LESS='--hilite-search --IGNORE-CASE --status-column --RAW-CONTROL-CHARS --hilite-unread --tabs=2 -X'

# http://www-zeuthen.desy.de/~friebel/unix/lesspipe.html
# XXX: figure out how to make syntax hilighting work for source

# Try to use a more current lesspipe
lesspipe=$(command -v lesspipe.sh)

if [ $? -eq 0 ]; then

  export LESSOPEN="|${lesspipe} %s"

else

  # Fall back to system lesspipe, if it exists
  lesspipe=$(command -v lesspipe)

  if [ $? -eq 0 ]; then

    eval "$(SHELL=/bin/sh ${lesspipe})"

  fi
fi

########################################################################################
# man setup

# http://zameermanji.com/blog/2012/12/30/using-vim-as-manpager/
#export MANPAGER="/bin/sh -c \"col -b | vim -R -c 'set ft=man ts=8 nomod nolist nonu noma' -\""

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
  for s in $(ls $COMPLETION 2> /dev/null); do source $s; done
fi

[[ $(type setup-bash-complete 2> /dev/null) ]] && source setup-bash-complete

[[ -f ~/bin/tokens ]] && source ~/bin/tokens

########################################################################################
# CVS settings

export CVS_RSH='ssh'
export CVSROOT='harleypig@cvs.vwh.net:/cvsroot'

########################################################################################
# Source any files we find in our host specific directory

__buildpath 'HOSTSPECIFIC' "${BASH_SOURCE}" "/hostspecific/$(hostname)/*bashrc*"
for s in $(ls ${HOSTSPECIFIC} 2> /dev/null); do source $s; done

########################################################################################
# Source any private files

PRIVATE="${HOME}/.bash_private.d"
for s in $(ls ${PRIVATE} 2> /dev/null); do source $s; done

[[ -f ~/.sekrets ]] && source ~/.sekrets

__debugit "$LINENO Entering ..."
