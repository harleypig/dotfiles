[[ -f /etc/profile.d/bash-completion ]] && \
  source /etc/profile.d/bash-completion

[[ -f /usr/share/cdargs/cdargs-bash.sh ]] && \
  source /usr/share/cdargs/cdargs-bash.sh

[[ -f ~/.bash_aliases ]] && . ~/.bash_aliases

[[ -f ~/.bashrc ]] && . ~/.bashrc

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# http://www.gnu.org/software/bash/manual/bashref.html#The-Shopt-Builtin
#shopt -s 

[[ -f ~/.ssh-agent ]] && . ~/.ssh-agent
#ssh-agent

export PATH=~/bin:~/.vim/bin/:$PATH
