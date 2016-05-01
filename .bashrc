#echo Started .bashrc ... >> ~/bash_startup.log

# http://www.catonmat.net/series/bash-one-liners-explained
# http://www.catonmat.net/blog/bash-one-liners-explained-part-four/
# http://www.catonmat.net/blog/the-definitive-guide-to-bash-command-line-history/
#

# .bashrc is called when shelling from vim or creating a new screen instance.

# We repeat these here and export for general use. See .bash_profile for more info.

# XXX: Does __can256 belong in the general utlities file?
function __can256 { [ $(tput Co 2> /dev/null || tput colors 2> /dev/null || echo 0) -gt 2 ] ; }
export -f __can256

function __realdir { printf -v "$1" "%s" $(dirname $(readlink -nf "$2")) ; }
export -f __realdir

function __buildpath {

  local varname=$1 ; shift
  local source=$1  ; shift
  local addon=$1   ; shift

  __realdir 'REALDIR' "$source"

  printf -v "$varname" "${REALDIR}${addon}"

}
export -f __buildpath

[[ -d ~/bin            ]] && PATH="${PATH}:~/bin"
[[ -d ~/.vim/bin       ]] && PATH="${PATH}:~/.vim/bin"
[[ -d ~/.cabal/bin     ]] && PATH="${PATH}:~/.cabal/bin"
[[ -d ~/.minecraft/bin ]] && PATH="${PATH}:~/.minecraft/bin"

if [[ -d $HOME/projects/android-sdk ]]; then

  PATH="${PATH}:~/projects/android-sdk/tools"
  PATH="${PATH}:~/projects/android-sdk/platform-tools"

fi

export EDITOR=vim
export HISTCONTROL='ignorespace:erasedups'
export HISTFILESIZE=1000
export HISTSIZE=1000
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PACMAN='pacmatic'
export PATH

if [[ $- = *i* ]]
then

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

  [[ -f /etc/bash_completion           ]] && source /etc/bash_completion
  [[ -f /etc/profile.d/bash-completion ]] && source /etc/profile.d/bash-completion

  [[ -f ~/.ssh-agent       ]] && source ~/.ssh-agent
  [[ -f ~/.bash_aliases    ]] && source ~/.bash_aliases
  [[ -f ~/.bash_functions  ]] && source ~/.bash_functions
  [[ -f ~/.bash_prompt     ]] && source ~/.bash_prompt
  [[ -f /.travis/travis.sh ]] && source /.travis/travis.sh
  [[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh

  [[ -f $rvm_path/scripts/completion   ]] && source $rvm_path/scripts/completion

  command -v npm > /dev/null 2>&1 && source <(npm completion)

  if [[ -d ~/.bash_completion.d ]]; then
    __buildpath 'COMPLETION' "${BASH_SOURCE}" '/.bash_completion.d/*'
    for s in $(ls $COMPLETION 2> /dev/null); do source $s; done
  fi

  [[ $(type setup-bash-complete 2> /dev/null) ]] && source setup-bash-complete

  [[ -f ~/bin/tokens ]] && source ~/bin/tokens

  ########################################################################################
  # If google's depot_file repo is found in a known place, add it to the path.
  # http://www.chromium.org/chromium-os/developer-guide#TOC-Building-an-image-to-run-in-a-virtu

  [[ -d ~/projects/depot_tools ]] && export PATH="${PATH}:~/projects/depot_tools"

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

fi

#echo '  ... ended .bashrc.' >> ~/bash_startup.log
