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

########################################################################
# PATH setup

if [[ -d $HOME/projects/android-sdk ]]; then

  PATH="${PATH}:~/projects/android-sdk/tools"
  PATH="${PATH}:~/projects/android-sdk/platform-tools"

fi

if [[ -d ~/.rbenv ]]; then

  PATH="~/.rbenv/plugins/ruby-build/bin:~/.rbenv/bin:${PATH}"

  # This eval needs to be included in .bashrc as well because some of it will
  # be lost when switching to an interactive shell.
  eval "$(rbenv init -)"

fi

# Do not alphabetize, order is important here.

BIN_DIRS="${BIN_DIRS} ~/bin"
BIN_DIRS="${BIN_DIRS} ~/.vim/bin"
BIN_DIRS="${BIN_DIRS} ~/.cabal/bin"
BIN_DIRS="${BIN_DIRS} ~/.minecraft/bin"
BIN_DIRS="${BIN_DIRS} ~/Dropbox/bin"
BIN_DIRS="${BIN_DIRS} ~/videos/bin"
BIN_DIRS="${BIN_DIRS} ~/projects/depot_tools"
BIN_DIRS="${BIN_DIRS} ~/projects/dotfiles/bin"

for d in $BIN_DIRS; do

  dir=${d//\~/$HOME}
  dir=$(readlink -nf $dir)

  if [[ -d $dir ]] && [[ $PATH != *"$dir"* ]]; then
      PATH="${PATH}:${dir}"

  fi
done

PATH="${PATH}:."
export PATH

########################################################################
# Source host specific files

__buildpath 'HOSTSPECIFIC' "${BASH_SOURCE}" "/hostspecific/$(hostname)/*profile*"
for s in $(ls $HOSTSPECIFIC 2> /dev/null); do source $s; done

[[ -f ~/.bashrc ]] && . ~/.bashrc
