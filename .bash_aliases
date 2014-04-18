#echo 'Started .bash_aliases ...' >> ~/bash_startup.log

# Some of these aliases are:

# from the bash-it project on github:
#   https://github.com/revans/bash-it
#
# culled from superuser.com

# others are my own fault.

# System
alias c='clear'
alias ~='cd ~'
alias -- -="cd -"
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias df='df -h'
alias h='history'
alias l='ls -Al --color=auto'
alias md='mkdir -p'
alias rd=rmdir
alias realias='source ~/.bash_aliases'
alias refunction='source ~/.bash_functions'
alias sl=ls
alias t=task

if ! command -v tree > /dev/null; then

  alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"

fi

# Git
if command -v git > /dev/null; then

  alias ga='git add'
  alias gall='git add .'
  alias gba='git branch -a -v'
  alias gb='git branch'
  alias gca='git commit -a -v -m'
  alias gc='git commit -v -m'
  alias gco='git checkout'
  alias gcount='git shortlog -sn'
  alias gcp='git cherry-pick'
  alias gd='git diff'
  alias gexport='git archive --format zip --output'
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

# https://metacpan.org/module/Catalyst::Manual::Tutorial::07_Debugging#DEBUGGING-MODULES-FROM-CPAN
#alias pmver="perl -le '\$m = shift; eval qq(require \$m) or die qq(module \"\$m\" is not installed\\n); print \$m->VERSION || \"No Version Available\"'"
alias pmver="perl -e'for(@ARGV){\$v=eval\"require \$_\"?(\$_->VERSION||q(unknown)):q(not installed);print\"\$_ \$v\\n\"}'"

# http://www.commandlinefu.com/commands/view/5423/view-all-date-formats-quick-reference-help-alias
alias dateh='date --help|sed "/^ *%a/,/^ *%Z/!d;y/_/!/;s/^ *%\([:a-z]\+\) \+/\1_/gI;s/%/#/g;s/^\([a-y]\|[z:]\+\)_/%%\1_%\1_/I"|while read L;do date "+${L}"|sed y/!#/%%/;done|column -ts_'

# https://wiki.archlinux.org/index.php/Core_Utilities#ls
eval $(dircolors -b)

# https://wiki.archlinux.org/index.php/Core_Utilities#grep
export GREP_COLOR="1;33"
alias grep='grep --color=auto'
alias g='grep --color=auto'

alias diffdir='diff -qr'

if command -v colordiff > /dev/null; then
  alias diff='colordiff'
  alias diffdir='colordiff -qr'
fi

if command -v cpandoc > /dev/null; then
  alias perldoc='cpandoc'
fi

alias cpanm='cpanm --mirror http://cpan.cpantesters.org/ -S'

BIGALIASES="$(__basedir ~/.bash_aliases)/.bash_aliases.d"
SOURCE=$(ls ${BIGALIASES}/* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

HOSTSPECIFIC="$(__basedir ~/.bash_aliases)/hostspecific/$(hostname)"
SOURCE=$(ls ${HOSTSPECIFIC}/*aliases* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

#echo '  ... ended .bash_aliases.' >> ~/bash_startup.log
