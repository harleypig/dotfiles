#echo Started .bashrc ... >> ~/bash_startup.log

# .bashrc is called when shelling from vim or creating a new screen instance.

function __basedir() {

  d=$(readlink ~/.bash_profile)
  if [ -n "$d" ]; then d=$(dirname "${d}"); else d="${HOME}"; fi
  echo "${d}"

}


PATH="${PATH}:~/bin"
PATH="${PATH}:~/.vim/bin/"
#PATH="${PATH} ~/projects/android-sdk/tools"
#PATH="${PATH} ~/projects/android-sdk/platform-tools"
export PATH

export EDITOR=vim
export HISTCONTROL='ignorespace:erasedups'
export HISTFILESIZE=1000
export HISTSIZE=1000
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

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

  ########################################################################################
  # less setup

  #export LESS='--quit-if-one-screen --hilite-search --IGNORE-CASE --status-column --LINE-NUMBERS --RAW-CONTROL-CHARS --hilite-unread --tabs=2'
  export LESS='--hilite-search --IGNORE-CASE --status-column --RAW-CONTROL-CHARS --hilite-unread --tabs=2'

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
  # cdargs setup

  CDARGS=$(command -v cdargs)

  if [ $? -eq 0 ]; then

    cv () { cdargs "$1" && cd $(cat $HOME/.cdargsresult); }
    cvadd () { cdargs --add=$(pwd); }

    # XXX: fall back to homegrown bookmark manager if cdargs isn't installed

  fi

  ########################################################################################
  # Simple check and source lines

  [[ -f ~/.ssh-agent ]]                     && source ~/.ssh-agent
  [[ -f ~/.bash_aliases ]]                  && source ~/.bash_aliases
  [[ -f ~/.bash_functions ]]                && source ~/.bash_functions
  [[ -f ~/.bash_prompt ]]                   && source ~/.bash_prompt

  [[ -f /etc/bash_completion ]]             && source /etc/bash_completion
  [[ -f /etc/profile.d/bash-completion ]]   && source /etc/profile.d/bash-completion
  [[ -d ~/.bash_completion.d ]]             && source ~/.bash_completion.d/*
  [[ -f $rvm_path/scripts/completion ]]     && source $rvm_path/scripts/completion
  [[ $(type setup-bash-complete 2> /dev/null) ]] && source setup-bash-complete

  [[ -f ~/perl5/perlbrew/etc/bashrc ]]      && source ~/perl5/perlbrew/etc/bashrc
  [[ -f $rvm_path/scripts/rvm ]]            && source $rvm_path/scripts/rvm

  ########################################################################################
  # Source any files we find in our host specific directory

  HOSTSPECIFIC="$(__basedir ~/.bashrc)/hostspecific/$(hostname)"
  SOURCE=$(ls ${HOSTSPECIFIC}/*bashrc* 2> /dev/null)
  for s in ${SOURCE}; do source $s; done


  ########################################################################################
  # Say something funny

  # XXX: add random selection of template

  if [[ -n $(command -v cowsay) ]]; then command cowsay $(fortune -s); fi

fi

#echo '  ... ended .bashrc.' >> ~/bash_startup.log
