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

[[ -d ~/bin        ]] && PATH="${PATH}:~/bin"
[[ -d ~/.vim/bin   ]] && PATH="${PATH}:~/.vim/bin/"

if [[ -d ~/.rvm ]]; then

  [[ -d ~/.rvm/bin ]] && PATH="${PATH}:~/.rvm/bin"

  # Include this here for the GEM_HOME variable
  [[ -f ~/.rvm/scripts/rvm ]] && source ~/.rvm/scripts/rvm

fi

if [[ -d $HOME/projects/android-sdk ]]; then

  PATH="${PATH}:~/projects/android-sdk/tools"
  PATH="${PATH}:~/projects/android-sdk/platform-tools"

fi

## Include this here for the GEM_HOME variable
#[[ -f ~/.rvm/scripts/rvm ]] && source ~/.rvm/scripts/rvm
#
#RUBY=$(command -v ruby)
#
#if [ $? -eq 0 ]; then
#  PATH="$($RUBY -e 'print Gem.user_dir')/bin:${PATH}"
#  export GEM_HOME=$($RUBY -e 'print Gem.user_dir')
#fi

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

  [[ -f ~/.ssh-agent       ]] && source ~/.ssh-agent
  [[ -f ~/.bash_aliases    ]] && source ~/.bash_aliases
  [[ -f ~/.bash_functions  ]] && source ~/.bash_functions
  [[ -f ~/.bash_prompt     ]] && source ~/.bash_prompt
  [[ -f /.travis/travis.sh ]] && source /.travis/travis.sh
  [[ -f /usr/share/nvm/init-nvm.sh ]] && source /usr/share/nvm/init-nvm.sh

  [[ -f /etc/bash_completion           ]] && source /etc/bash_completion
  [[ -f /etc/profile.d/bash-completion ]] && source /etc/profile.d/bash-completion
  [[ -f $rvm_path/scripts/completion   ]] && source $rvm_path/scripts/completion

  if [[ -d ~/.bash_completion.d ]]; then
     COMPLETION="$(__basedir ~/.bash_completion.d)/.bash_completion.d"
     SOURCE=$(ls ${COMPLETION}/* 2> /dev/null)
     for s in ${SOURCE}; do source $s; done
   fi

  [[ $(type setup-bash-complete 2> /dev/null)       ]] && source setup-bash-complete

  [[ -f ~/bin/tokens ]]                     && source ~/bin/tokens

  ########################################################################################
  # If google's depot_file repo is found in a known place, add it to the path.
  # http://www.chromium.org/chromium-os/developer-guide#TOC-Building-an-image-to-run-in-a-virtu

  [[ -d ~/projects/depot_tools ]] && export PATH="${PATH}:~/projects/depot_tools"

  ########################################################################################
  # CVS settings

  export CVS_RSH=ssh
  export CVSROOT=harleypig@cvs.vwh.net:/cvsroot

  ########################################################################################
  # Source any files we find in our host specific directory

  HOSTSPECIFIC="$(__basedir ~/.bashrc)/hostspecific/$(hostname)"
  SOURCE=$(ls ${HOSTSPECIFIC}/*bashrc* 2> /dev/null)
  for s in ${SOURCE}; do source $s; done

fi

#echo '  ... ended .bashrc.' >> ~/bash_startup.log

PATH="/home/harleypig/perl5/bin${PATH+:}${PATH}"; export PATH;
PERL5LIB="/home/harleypig/perl5/lib/perl5${PERL5LIB+:}${PERL5LIB}"; export PERL5LIB;
PERL_LOCAL_LIB_ROOT="/home/harleypig/perl5${PERL_LOCAL_LIB_ROOT+:}${PERL_LOCAL_LIB_ROOT}"; export PERL_LOCAL_LIB_ROOT;
PERL_MB_OPT="--install_base \"/home/harleypig/perl5\""; export PERL_MB_OPT;
PERL_MM_OPT="INSTALL_BASE=/home/harleypig/perl5"; export PERL_MM_OPT;
