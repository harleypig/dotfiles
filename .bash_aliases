#echo 'Started .bash_aliases ...' >> ~/bash_startup.log

# Some of these aliases are:

# from the bash-it project on github: where's the damn url?
# culled from superuser.com

# others are my own fault.

# Git
if [[ $(which git) ]]
then

  alias ga='git add'
  alias gall='git add .'
  alias gba='git branch -a -v'
  alias gb='git branch'
  alias gca='git commit -a -v'
  alias gc='git commit -v'
  alias gco='git checkout'
  alias gcount='git shortlog -sn'
  alias gcp='git cherry-pick'
  alias gd='git diff | vim -R -'
  alias gdv='git diff -w "$@" | vim -R -'
  alias gexport='git archive --format zip --output'
  alias git_remove_missing_files="git status | awk '/deleted:(.*)/ {print $3}' | xargs git rm"
  alias gl='git pull'
  alias glall='git pull --all'
  alias gmv='git mv'
  alias gp='git push'
  alias gpo='git push origin'
  alias gpall='git push --all'
  alias grm='git rm'
  alias gs='git status -s'
  alias gwtf='git-wtf'

fi

# System
alias c='clear'
alias -- -="cd -"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias g='grep'
alias h='history'
alias l='ls -lhA --color=auto'
alias md='mkdir -p'
alias rd=rmdir
alias realias='source ~/.bash_aliases'
alias refunction='source ~/.bash_functions'
alias sl=ls
alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"
alias cpanm="/usr/local/bin/cpanm -S"

HOSTSPECIFIC="$(__base_dir ~/.bash_aliases))/hostspecific/$(hostname)"
SOURCE=$(ls ${HOSTSPECIFIC}/*aliases* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

#echo '  ... ended .bash_aliases.' >> ~/bash_startup.log
