#!/bin/bash

__debugit "${BASH_SOURCE#$HOME/}:$LINENO Entering ..."

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

if ! command -v tree > /dev/null; then

  alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"

fi

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

__buildpath 'BIGALIASES' "${BASH_SOURCE}" "/.bash_aliases.d/*"
for s in $(ls $BIGALIASES 2> /dev/null); do source $s; done

__buildpath 'HOSTSPECIFIC' "${BASH_SOURCE}" "/hostspecific/$(hostname)/*aliases*"
for s in $(ls $HOSTSPECIFIC 2> /dev/null); do source $s; done

__debugit "${BASH_SOURCE#$HOME/}:$LINENO Exiting ..."
