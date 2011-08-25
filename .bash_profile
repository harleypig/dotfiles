# .bash_profile is run *first* and *only* on ssh (or terminal) but not when
# shelling out from vim or a new screen instance is being created.

HOSTSPECIFIC="$(dirname $(readlink ~/.bash_profile))/hostspecific/$(hostname)_profile"

[[ -f ${HOSTSPECIFIC} ]] && source ${HOSTSPECIFIC}

[[ -f ~/.bashrc ]] && . ~/.bashrc
