# .bash_profile is run *first* and *only* on ssh (or terminal) but not when
# shelling out from vim or a new screen instance is being created.

function __basedir() {

  d=$(readlink ~/.bash_profile)

  if [ -n "$d" ]; then d=$(dirname "${d}"); else d="${HOME}"; fi

  echo "${d}"

}

CAN256=$(find /lib/terminfo /usr/share/terminfo -name 'xterm-256color' 2> /dev/null)

if [ -n $CAN256 ]; then

  if [ -n $TMUX ]; then

    TERM='screen-256color'

  elif [ $TERMCAP =~ screen ]; then

    TERM='screen-256color'

  else

    TERM='xterm-256color'

  fi

else

  TERM='xterm-color'

fi

export TERM

if [[ -d ~/.rbenv ]]; then

  PATH="~/.rbenv/plugins/ruby-build/bin:~/.rbenv/bin:${PATH}"
  eval "$(rbenv init -)"

fi

HOSTSPECIFIC="$(__basedir ~/bash_profile)/hostspecific/$(hostname)"
SOURCE=$(ls ${HOSTSPECIFC}/*profile* 2> /dev/null)
for s in ${SOURCE}; do source $s; done

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.Xresources ]] && xrdb ~/.Xresources

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
