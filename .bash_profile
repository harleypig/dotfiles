# .bash_profile is run *first* and *only* on ssh (or terminal) but not when
# shelling out from vim or a new screen instance is being created.

HOSTSPECIFIC="$(dirname $(readlink ~/.bash_functions))/hostspecific/$(hostname)_functions"

[[ -x ${HOSTSPECIFIC} ]] && source ${HOSTSPECIFIC}

[[ -f ~/.bashrc ]] && . ~/.bashrc
