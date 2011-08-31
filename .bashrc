#echo Started .bashrc ... >> ~/bash_startup.log

# .bashrc is called when shelling from vim or creating a new screen instance.

function __basedir() {

  d=$(readlink ~/.bash_profile)

  if [ -n "$d" ]; then d=$(dirname "${d}"); else d="${HOME}"; fi

  echo "${d}"

}


export PATH=~/bin:~/.vim/bin/:$PATH
export EDITOR=vim
export HISTCONTROL='ignorespace:erasedups'
export HISTFILESIZE=1000
export HISTSIZE=1000
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

hostname=$(hostname)
hostname=${hostname%[0-9]*}

HOSTSPECIFIC="$(__basedir ~/.bashrc))/hostspecific/$(hostname)"

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

  [[ -x /usr/bin/lesspipe ]]                && eval "$(SHELL=/bin/sh lesspipe)"

  CDARGS=$(which cdargs 2> /dev/null)

  if [[ -f ${CDARGS} ]]
  then

    CDARGS_COMPLETION="$(dirname $(readlink ~/.bashrc))"
    source ${CDARGS_COMPLETION}/cdargs_completion

  fi

  [[ -f ~/.ssh-agent ]]                     && source ~/.ssh-agent
  [[ -f ~/.bash_aliases ]]                  && source ~/.bash_aliases
  [[ -f ~/.bash_functions ]]                && source ~/.bash_functions
  [[ -f ~/.bash_prompt ]]                   && source ~/.bash_prompt

#  [[ -f /etc/bash_completion ]]             && source /etc/bash_completion
  [[ -f /etc/profile.d/bash-completion ]]   && source /etc/profile.d/bash-completion
  [[ -d ~/.bash_completion.d ]]             && source ~/.bash_completion.d/*

  SOURCE=$(ls ${HOSTSPECIFIC}/*bashrc* 2> /dev/null)
  for s in ${SOURCE}; do source $s; done

fi

#echo '  ... ended .bashrc.' >> ~/bash_startup.log
