#!/bin/bash

# Debug tty login (ssh user@server):
# ssh -t localhost "PS4='[\$BASH_SOURCE[0]:\$LINENO]: ' bash -xl" |& tee login.log

# Debug no tty login (ssh user@server somecommand)
# ssh localhost "PS4='[\$BASH_SOURCE[0]:\$LINENO]: ' bash -xl" |& tee login.log

################################################################################
# Base Global variables

if [[ -L ${BASH_SOURCE[0]} ]]; then
  DOTFILES=$(dirname "$(readlink -nf "${BASH_SOURCE[0]}")")
  GLOBAL_DIR="$(dirname "$DOTFILES")"

  OLDPWD="$PWD"

  # shellcheck disable=SC2164
  cd "$DOTFILES"
  GLOBAL_DIR="$(git rev-parse --show-toplevel 2> /dev/null)" \
    || echo "Unable to determine top level of repository, weird things are going to happen."

  cd "$OLDPWD"
  unset OLDPWD

else
  DOTFILES="$HOME"
  GLOBAL_DIR="$HOME"

  cat << EOT

This .bash_profile is developed to be linked and executed from a repository as
a symbolic link. This is not being done here and results will be unreliable.

EOT
fi

export GLOBAL_LIB="$GLOBAL_DIR/lib"
export GLOBAL_BIN="$GLOBAL_DIR/bin"

export DOTFILES GLOBAL_DIR

##############################################################################
# Don't delete this, it's for figuring things out sometimes.
# XXX: Maybe move this into debug?

((DEBUG)) && {
  if [[ $- == *i* ]]; then
    debug "We are interactive ..."
  else
    debug "We are *not* interactive ..."
  fi

  if shopt -q login_shell; then
    debug "We are in a login shell ..."
  else
    debug "We are *not* in a login shell ..."
  fi
}

# XXX: Use $GLOBAL_LIB instead (but how to solve the chicken and the egg
# problem?)
source "$GLOBAL_LIB/debug"

##############################################################################
# This script, and any scripts in the .bash_profile.d directories, should
# focus on setting environment variables.

# Including a function at this level should be considered, and very rarely
# done.

# It is recommended that the only time a function is included at this level is
# to provide a script that absolutely every script ever called, either
# interactive (ssh) or not (ssh login:8,) will need to use said function. Even
# then, it would probably be better to load the function through other means.

# this function takes one directory path and adds it to the existing path
function addpath() {
  debug "adding $1 to path"
  PATH="${PATH}:$1"
}

declare -a BIN_DIRS

# !!! Do not alphabetize, order is important here.

BIN_DIRS+=("$GLOBAL_LIB")
BIN_DIRS+=("$GLOBAL_BIN")
BIN_DIRS+=("$HOME/bin")
BIN_DIRS+=('/usr/lib/ccache/bin')
BIN_DIRS+=("/usr/lib/dart/bin")
BIN_DIRS+=("$HOME/bin")
BIN_DIRS+=("$HOME/.vim/bin")
BIN_DIRS+=("$HOME/.cabal/bin")
BIN_DIRS+=("$HOME/.minecraft/bin")
BIN_DIRS+=("$HOME/Dropbox/bin")
BIN_DIRS+=("$HOME/videos/bin")
BIN_DIRS+=("$HOME/projects/depot_tools")
BIN_DIRS+=("$HOME/projects/android-sdk/tools")
BIN_DIRS+=("$HOME/projects/android-sdk/platform-tools")

for d in "${BIN_DIRS[@]}"; do
  addpath "$d"
done

unset BIN_DIRS

################################################################################
# Check if various dotfiles are linked properly

# XXX: Add cleanup routine (e.g., .screenrc is no longer needed, links to it
#      should be removed.

# XXX: Add a way to check for links to arbitrary locations (e.g. .vim and
#      .vimrc might be in their own repository).

nochecklinks="$HOME/.nochecklinks"

if [[ ! -e $nochecklinks ]]; then
  debug "Checking dotfiles ..."

  declare -a CHECK_DOTFILES

  CHECK_DOTFILES+=('.bash_logout')
  CHECK_DOTFILES+=('.bashrc')
  CHECK_DOTFILES+=('.cvsrc')
  CHECK_DOTFILES+=('.flexget')
  CHECK_DOTFILES+=('.gitconfig')
  CHECK_DOTFILES+=('.gitignore')
  CHECK_DOTFILES+=('.gitignore_global')
  CHECK_DOTFILES+=('.htoprc')
  CHECK_DOTFILES+=('.inputrc')
  CHECK_DOTFILES+=('.mplayer')
  CHECK_DOTFILES+=('.perlcriticrc')
  CHECK_DOTFILES+=('.perldb')
  CHECK_DOTFILES+=('.perltidyrc')
  CHECK_DOTFILES+=('.tmux.conf')

  badlinks=0

  for checkfile in "${CHECK_DOTFILES[@]}"; do
    if [[ ! -e $HOME/$checkfile ]]; then
      debug "Linking $DOTFILES/$checkfile ..."
      ln -s "$DOTFILES/$checkfile" "$HOME/$checkfile"

    else
      debug "$DOTFILES/$checkfile exists, checking if it's ours ..."
      linkdir=$(dirname "$(readlink -nf "$checkfile")")

      if [[ $linkdir != "$DOTFILES" ]]; then
        echo "$checkfile is not linked to $DOTFILES"
        badlinks=1
      fi
    fi
  done

  if ((badlinks)); then
    cat << EOT

Move those files out of the way and then run '. .bash_profile' if you want to
fix those.

If you like those files the way they are, then run '> $nochecklinks' and they
will be ignored.

EOT
  fi

  unset CHECK_DOTFILES badlinks checkfile
fi

unset nochecklinks

##############################################################################
declare -a profiledirs

profiledirs+=("$DOTFILES/.bash_profile.d")
profiledirs+=("$HOME/.bash_profile.d")

for profiledir in "${profiledirs[@]}"; do
  [[ -d $profiledir ]] || continue

  readarray -t profilefiles < <(/usr/bin/find "$profiledir" -iname '*_profile' | /usr/bin/sort)

  for profilefile in "${profilefiles[@]}"; do
    [[ -r $profilefile ]] && {
      debug "Sourcing $profilefile ..."
      source "$profilefile" || debug "... unable to source $profilefile"
    }
  done
done

unset profiledirs profiledir profilefiles profilefile

################################################################################
# XXX: Move these. To general_profile?
export LANG=en_US.utf-8
export LC_ALL=en_US.utf-8

################################################################################
# Get the aliases and functions

debug "Sourcing $DOTFILES/.bashrc"
[[ -f $DOTFILES/.bashrc ]] && source "$DOTFILES/.bashrc"

unset addpath
