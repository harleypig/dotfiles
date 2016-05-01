# .bash_profile is run *first* and *only* on ssh (or terminal) but not when
# shelling out from vim or a new screen instance is being created.

# These functions are needed before we load the main functions file, so we do
# it here. We don't export them here because if something gets messed up here,
# we can't access the terminal, even from a non-gui login! Yipes!

function __realdir { printf -v "$1" "%s" $(dirname $(readlink -nf "$2")) ; }

function __buildpath {

  local varname=$1 ; shift
  local source=$1  ; shift
  local addon=$1   ; shift

  __realdir 'REALDIR' "$source"

  printf -v "$varname" "${REALDIR}${addon}"

}

if [[ -d ~/.rbenv ]]; then

  PATH="~/.rbenv/plugins/ruby-build/bin:~/.rbenv/bin:${PATH}"
  eval "$(rbenv init -)"

fi

__buildpath 'HOSTSPECIFIC' "${BASH_SOURCE}" "/hostspecific/$(hostname)/*profile*"
for s in $(ls $HOSTSPECIFIC 2> /dev/null); do source $s; done

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.Xresources ]] && xrdb ~/.Xresources

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
