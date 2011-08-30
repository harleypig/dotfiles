# .bash_profile is run *first* and *only* on ssh (or terminal) but not when
# shelling out from vim or a new screen instance is being created.

HOSTSPECIFIC="$(dirname $(readlink ~/.bash_profile))/hostspecific/$(hostname)_profile"

CAN256=$(find /lib/terminfo /usr/share/terminfo -name 'xterm-256color')

if [ "${CAN256}x" != "x" ]
then

  export TERM='xterm-256color'

else

  export TERM='xterm-color'

fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
