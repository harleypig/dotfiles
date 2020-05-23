#!/bin/bash

# Debug tty login (ssh user@server):
# ssh -t localhost "PS4='[\$BASH_SOURCE[0]:\$LINENO]: ' bash -xl" |& tee login.log

# Debug no tty login (ssh user@server somecommand)
# ssh localhost "PS4='[\$BASH_SOURCE[0]:\$LINENO]: ' bash -xl" |& tee login.log

##############################################################################
# XXX: When ksh scripts are gone (or not depending on setting global
#      variables), remove this.

if [[ $BASH != */bash ]]; then
  # XXX: Deprecate 2020/06/01
  cat << EOM
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!!                                     !!!
!!! .bash_profile: exec /bin/bash $0 $* !!!
!!! THIS IS GOING AWAY June 1 2020!     !!!
!!! FIX YOUR SCRIPT!                    !!!
!!!                                     !!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
EOM

  exec /bin/bash "$0" "$@"
fi

################################################################################
# Base Global variables

MOUNT_DIR='/nas_pp'
[[ $HOSTNAME == 'txlxa370' ]] && [[ ! -d /nas_pp ]] && MOUNT_DIR='/nas_projects'

if [[ -L ${BASH_SOURCE[0]} ]]; then
  DOTFILES=$(dirname "$(readlink -nf "${BASH_SOURCE[0]}")")

  # Set assumed default ...
  GLOBAL_DIR="$(dirname "$DOTFILES")"

else
  DOTFILES="$HOME"
  GLOBAL_DIR="$HOME"

  cat << EOT

This .bash_profile is developed to be linked and executed from a repository as
a symbolic link. This is not being done here and results will be unreliable.

EOT
fi

export GLOBAL_LIB="$GLOBAL_DIR/scripts/lib"
export GLOBAL_BIN="$DOTFILES/bin"

export DOTFILES GLOBAL_DIR

# XXX: Load site specific variables instead of including them in this generic
#      file. Can override already created variables here.
# source $GLOBAL_DIR/site.setup

debug() { true; }
[[ -r "$GLOBAL_LIB/debug" ]] && source "$GLOBAL_LIB/debug"

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

addpath "$HOME/bin"
addpath "$GLOBAL_BIN"

# XXX: FIXME
addpath "$DOTFILES/etladm/bin"

################################################################################
# Extract project name and environment from username.

# XXX: Convert this to pure bash
# XXX: Move from this line to the export line out of this file, but where can
#      I put it?

eval "$(perl -e '@a=$ENV{USER}=~/^(.*?)(dev|test|stg|prod|adm)$/;printf"PRJ_NAME=%s;PRJ_ENVIRONMENT=%s",@a')"

# Override PRJ_NAME and PRJ_ENVIRONMENT if the user wants.
# This must be a valid bash script.

[[ -r $HOME/.bash_profile.d/override ]] && source "$HOME/.bash_profile.d/override"

################################################################################
# Test if dev account is pointing .bash_profile to the correct location, warn
# if not.

((DEBUG)) && {
  for v in 'MOUNT_DIR' 'GLOBAL_DIR' 'DOTFILES' 'NAME' 'PRJ_NAME' 'PRJ_ENVIRONMENT'; do
    debug "$v: ${!v}"
  done

  unset v
}

export MOUNT_DIR NAME PRJ_ENVIRONMENT PRJ_NAME

################################################################################
# Check if various dotfiles are linked properly

# XXX: Add cleanup routine (e.g., .screenrc is no longer needed, links to it
#      should be removed.
#      No. Account owner should be responsible for removing link.

# XXX: Add a way to check for links to arbitrary locations (e.g. .vim and
#      .vimrc might be in their own repository).

# XXX: Expand no checking so that we can ignore individual files. Or, perhaps,
#      have a file in $HOME containing a list of files that should be linked. Or,
#      both ignore and include.

nochecklinks="$HOME/.nochecklinks"

if [[ ! -e $nochecklinks ]]; then
  debug "Checking dotfiles ..."

  declare -a CHECK_DOTFILES

  CHECK_DOTFILES+=('.bashrc')
  CHECK_DOTFILES+=('.gitconfig')
  CHECK_DOTFILES+=('.inputrc')
  CHECK_DOTFILES+=('.mailrc')
  CHECK_DOTFILES+=('.tmux.conf')
  CHECK_DOTFILES+=('.vim')
  CHECK_DOTFILES+=('.vimrc')

  badlinks=0

  for checkfile in "${CHECK_DOTFILES[@]}"; do
    # Do we actually have a checkfile in our repository?
    [[ -r $DOTFILES/$checkfile ]] || continue

    if [[ ! -e $HOME/$checkfile ]]; then
      debug "Linking $DOTFILES/$checkfile ..."
      ln -s "$DOTFILES/$checkfile" "$HOME/$checkfile"

    else
      debug "$DOTFILES/$checkfile exists, checking if it's ours ..."
      linkdir=$(dirname "$(readlink -nf "$checkfile")")

      if [[ $linkdir != "$DOTFILES" ]]; then
        [[ $- == *i* ]] && echo "$checkfile is not linked to $DOTFILES"
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

    ## Checks added to prevent .bash_profile sourcing itself.
    baseprofile=$(basename "${profilefile}")
    [[ ${baseprofile} == ".bash_profile" ]] && continue

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
