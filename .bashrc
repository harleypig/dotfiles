#echo Started .bashrc ... >> ~/bash_startup.log

# .bashrc is called when shelling from vim or creating a new screen instance.

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
[[ -f /usr/share/cdargs/cdargs-bash.sh ]] && source /usr/share/cdargs/cdargs-bash.sh
[[ -f ~/.ssh-agent ]]                     && source ~/.ssh-agent
[[ -f ~/.bash_aliases ]]                  && source ~/.bash_aliases
[[ -f ~/.bash_functions ]]                && source ~/.bash_functions
[[ -f ~/.bash_prompt ]]                   && source ~/.bash_prompt

#echo '  ... ended .bashrc.' >> ~/bash_startup.log
