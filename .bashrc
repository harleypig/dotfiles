#echo Started .bashrc ... >> ~/bash_startup.log

# .bashrc is called when shelling from vim or creating a new screen instance.

export PATH=~/bin:~/.vim/bin/:~/projects/applications/apache2/bin:$PATH:/var/lib/gems/1.8/bin
export EDITOR=vim
export HISTCONTROL='ignoreboth:erasedups'
export HISTFILESIZE=1000
export HISTSIZE=1000
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

[[ $- != *i* ]] && return # We're not running interactively, don't do anything.

shopt -s histappend
shopt -s checkhash
shopt -s dirspell
shopt -s dotglob
shopt -s histreedit
shopt -s histverify
shopt -s checkwinsize
shopt -s nocaseglob

[[ -x /usr/bin/lesspipe ]]                && eval "$(SHELL=/bin/sh lesspipe)"
[[ -f /etc/bash_completion ]]             && source /etc/bash_completion
[[ -f /etc/profile.d/bash-completion ]]   && source /etc/profile.d/bash-completion

perldoc='/home/harleypig/projects/bash-completion/perldoc-complete/perldoc-complete'
completion="complete -C ${perldoc} -o nospace -o default perldoc"
[[ -f ${perldoc} ]] && ${completion}

[[ -f /usr/share/cdargs/cdargs-bash.sh ]] && source /usr/share/cdargs/cdargs-bash.sh
[[ -f ~/.ssh-agent ]]                     && source ~/.ssh-agent
[[ -f ~/.bash_aliases ]]                  && source ~/.bash_aliases
[[ -f ~/.bash_functions ]]                && source ~/.bash_functions
[[ -f ~/.bash_prompt ]]                   && source ~/.bash_prompt
[[ -d ~/.bash_completion.d ]]             && source ~/.bash_completion.d/*
[[ -s ~/.rvm/scripts/rvm ]]               && source ~/.rvm/scripts/rvm # This loads RVM into a shell session.

#echo '  ... ended .bashrc.' >> ~/bash_startup.log
