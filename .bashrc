#echo Started .bashrc ... >> ~/bash_startup.log

# http://www.catonmat.net/series/bash-one-liners-explained
#   http://www.catonmat.net/blog/bash-one-liners-explained-part-four/
# http://www.catonmat.net/blog/the-definitive-guide-to-bash-command-line-history/
#

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

if [ -e ~/.gem/ruby/2.1.0/bin ]; then
  PATH="${PATH}:/home/harleypig/.gem/ruby/2.1.0/bin"
fi

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
  # cdargs setup

  if command -v cdargs > /dev/null; then

    cv () { cdargs "$1" && cd $(cat $HOME/.cdargsresult); }
    cvadd () { cdargs --add=$(pwd); }

    # XXX: fall back to homegrown bookmark manager if cdargs isn't installed

  fi

  ########################################################################################
  # man setup

  # http://zameermanji.com/blog/2012/12/30/using-vim-as-manpager/
  export MANPAGER="/bin/sh -c \"col -b | vim -R -c 'set ft=man ts=8 nomod nolist nonu noma' -\""

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

  [[ -f ~/bin/tokens ]]                     && source ~/bin/tokens

  ########################################################################################
  # If google's depot_file repo is found in a known place, add it to the path.
  # http://www.chromium.org/chromium-os/developer-guide#TOC-Building-an-image-to-run-in-a-virtu

  [[ -d ~/projects/depot_tools ]] && export PATH="${PATH}:~/projects/depot_tools"
  umask 022
  export GOOGLE_API_KEY='AIzaSyBIyn_yoeYI4FRmrq2f07Jr8keto1OkjHM'
  export GOOGLE_DEFAULT_CLIENT_ID='960272373064.apps.googleusercontent.com'
  export GOOGLE_DEFAULT_CLIENT_SECRET='tGJ1fD6araLkhrulLU8JKdrN'

  ########################################################################################
  # CVS settings

  export CVS_RSH=ssh
  export CVSROOT=harleypig@cvs.vwh.net:/cvsroot

  ########################################################################################
  # Source any files we find in our host specific directory

  HOSTSPECIFIC="$(__basedir ~/.bashrc)/hostspecific/$(hostname)"
  SOURCE=$(ls ${HOSTSPECIFIC}/*bashrc* 2> /dev/null)
  for s in ${SOURCE}; do source $s; done


  ########################################################################################
  # Say something funny

  # XXX: add random selection of template

  if command -v cowsay > /dev/null; then command cowsay $(fortune -s); fi

fi

#echo '  ... ended .bashrc.' >> ~/bash_startup.log
