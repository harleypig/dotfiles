#!/bin/bash

[[ $- == *i* ]] || return 0

_ssh() {
  local curw
  COMPREPLY=()
  curw=${COMP_WORDS[COMP_CWORD]}

  local ssh_config
  ssh_config=$(perl -p -e 'if(s/^host(name)? //i){for$a(split/\s+/){next if$a eq"*";$h{$a}=1}}}{print"$_ "for sort keys%h' ~/.ssh/config)

  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "$ssh_config" -- "$curw"))
}

complete -F _ssh ssh

# From https://github.com/jasonrudolph/dotfiles/blob/main/bash/completion_scripts/ssh_completion
## Credit: https://github.com/relevance/etc/blob/8ae7f1f/bash/ssh_autocompletion.sh
#
#SSH_KNOWN_HOSTS=( $(cat ~/.ssh/known_hosts | \
#  cut -f 1 -d ' ' | \
#  sed -e s/,.*//g | \
#  uniq | \
#  egrep -v [0123456789]) )
#SSH_CONFIG_HOSTS=( $(cat ~/.ssh/config | grep "Host " | grep -v "*" | cut -f 2 -d ' ') )
#
#complete -o default -W "${SSH_KNOWN_HOSTS[*]} ${SSH_CONFIG_HOSTS[*]}" ssh
