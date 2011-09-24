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
  alias glall='git pull --all'
  alias gl='git pull'
  alias glg='git lg'
  alias gmv='git mv'
  alias gpall='git push --all'
  alias gp='git push'
  alias gpo='git push origin'
  alias grm='git rm'
  alias gs='git status -s'
  alias gwtf='git-wtf'

fi

# System
alias c='clear'
alias ~='cd ~'
alias -- -="cd -"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias diffdir='diff -qr'
alias g='grep'
alias h='history'
alias l='ls -lhA --color=auto'
alias md='mkdir -p'
alias rd=rmdir
alias realias='source ~/.bash_aliases'
alias refunction='source ~/.bash_functions'
alias sl=ls
alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"

# https://metacpan.org/module/Catalyst::Manual::Tutorial::07_Debugging#DEBUGGING-MODULES-FROM-CPAN
alias pmver="perl -le '\$m = shift; eval qq(require \$m) or die qq(module \"\$m\" is not installed\\n); print \$m->VERSION || \"No Version Available\"'"

HOSTSPECIFIC="$(__basedir ~/.bash_aliases)/hostspecific/$(hostname)"
SOURCE=$(ls ${HOSTSPECIFIC}/*aliases* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

#echo '  ... ended .bash_aliases.' >> ~/bash_startup.log
