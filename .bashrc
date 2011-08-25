#echo Started .bashrc ... >> ~/bash_startup.log

# .bashrc is called when shelling from vim or creating a new screen instance.

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

if [[ $- = *i* ]]
then

  shopt -s checkhash
  shopt -s checkwinsize
  shopt -s cmdhist

  [[ ${hostname} != 'ut1-facelift' ]] && shopt -s dirspell

  shopt -s dotglob
  shopt -s histappend
  shopt -s histreedit
  shopt -s histverify
  shopt -s nocaseglob

  [[ -x /usr/bin/lesspipe ]]                && eval "$(SHELL=/bin/sh lesspipe)"
  [[ -f /etc/bash_completion ]]             && source /etc/bash_completion
  [[ -f /etc/profile.d/bash-completion ]]   && source /etc/profile.d/bash-completion

  if [ ${hostname} != 'ut1-facelift' ]
  then

    echo 'not facelift!'
    perldoc='/home/harleypig/projects/bash-completion/perldoc-complete/perldoc-complete'
    completion="complete -C ${perldoc} -o nospace -o default perldoc"
    [[ -f ${perldoc} ]] && ${completion}

  fi

  [[ -f /usr/share/cdargs/cdargs-bash.sh ]] && source /usr/share/cdargs/cdargs-bash.sh
  [[ -f ~/.ssh-agent ]]                     && source ~/.ssh-agent
  [[ -f ~/.bash_aliases ]]                  && source ~/.bash_aliases
  [[ -f ~/.bash_functions ]]                && source ~/.bash_functions
  [[ -f ~/.bash_prompt ]]                   && source ~/.bash_prompt
  [[ -d ~/.bash_completion.d ]]             && source ~/.bash_completion.d/*

fi

#echo '  ... ended .bashrc.' >> ~/bash_startup.log
