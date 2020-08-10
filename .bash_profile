#!/bin/bash

echo "$0"

# XXX: Move to a file that .bash_profile, .profile and whoever else will need
#      to read it can do so.

# Debug tty login (ssh user@server):
# ssh -t localhost "PS4='[\$BASH_SOURCE[0]:\$LINENO]: ' bash -xl" |& tee login.log

# Debug no tty login (ssh user@server somecommand)
# ssh localhost "PS4='[\$BASH_SOURCE[0]:\$LINENO]: ' bash -xl" |& tee login.log

################################################################################
# Base Global variables

DOTFILES="$HOME"

[[ -L ${BASH_SOURCE[0]} ]] \
  && DOTFILES=$(dirname "$(readlink -nf "${BASH_SOURCE[0]}")")

export DOTFILES

##############################################################################
export PATH="$PATH:$DOTFILES/lib:$DOTFILES/bin"

##############################################################################
debug() { true; }
command -v debug &> /dev/null && source debug

##############################################################################
# This script, and any scripts in the .bash_profile.d directories, should
# focus on setting environment variables.

# Including a function at this level should be considered carefully, and very
# rarely done.

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

# XXX: Move to a file to be read from
# !!! Do not alphabetize, order is important here.

BIN_DIRS+=("$GLOBAL_LIB")
BIN_DIRS+=("$GLOBAL_BIN")
BIN_DIRS+=("$HOME/bin")
BIN_DIRS+=("$HOME/.local/bin")
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

[[ -x "$(command -v check-dotfiles 2> /dev/null)" ]] && check-dotfiles

##############################################################################
declare -a includedirs

includedirs+=("$DOTFILES/.bash_profile.d")
includedirs+=("$HOME/.bash_profile.d")
includedirs+=("$DOTFILES/.bashrc.d")
includedirs+=("$HOME/.bashrc.d")

# Run each directory instead of doing a find on all directories at once
# because we want these files loaded in this particular order.

for includedir in "${includedirs[@]}"; do
  [[ -d $includedir ]] || continue

  readarray -t includefiles < <(/usr/bin/find "$includedir" -iregex '.*_\(profile\|rc\)' | /usr/bin/sort)

  for includefile in "${includefiles[@]}"; do
    [[ -r $includefile ]] && {
      debug "Sourcing $includefile ..."
      source "$includefile" || debug "... unable to source $includefile"
    }
  done
done

##############################################################################
unset includedirs includedir includefiles includefile addpath
