# .bash_profile is run *first* and *only* on ssh (or terminal) but not when
# shelling out from vim or a new screen instance is being created.

function __basedir() {

  d=$(readlink ~/.bash_profile)

  if [ -n "$d" ]; then d=$(dirname "${d}"); else d="${HOME}"; fi

  echo "${d}"

}

#CAN256=$(find /lib/terminfo /usr/share/terminfo -name 'xterm-256color' 2> /dev/null)
#
#if [ "${CAN256}x" != "x" ]
#then
#
#  TERM='xterm-256color'
#
#else
#
  TERM='xterm-color'
#
#fi

HOSTSPECIFIC="$(__basedir ~/bash_profile)/hostspecific/$(hostname)"
SOURCE=$(ls ${HOSTSPECIFC}/*profile* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

export TERM

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.Xresources ]] && xrdb ~/.Xresources
