#echo Started .bash_profile ... >> ~/bash_startup.log

# .bash_profile is run *first* and *only* on ssh (or terminal) but not when
# shelling out from vim or a new screen instance is being created.

export EDITOR=vim
export HISTCONTROL='ignoreboth:erasedups'
export HISTFILESIZE=1000
export HISTSIZE=1000
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export PATH=~/bin:~/.vim/bin/:$PATH

[[ -f ~/.bashrc ]] && . ~/.bashrc

#echo '  ... ended .bash_profile.' >> ~/bash_startup.log
