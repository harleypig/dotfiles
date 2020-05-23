#!/bin/bash

# XXX: Do I need to check for interactive or login here? or leave it to the
# loaded scripts to handle?

##############################################################################
# Sanity checks

if [[ -z $DOTFILES ]] || [[ -z $GLOBAL_DIR ]]; then
  # Don't use debug here, it may not have been loaded at this point.
  ((DEBUG)) && echo 'DOTFILES and/or GLOBAL_DIR is not set, not continuing .bashrc' >&2
  return 1
fi

##############################################################################
# If we are being accessed via 'ssh host command' then .bash_profile needs to
# be processed so we get the environment variables. But if we are being
# accessed because we've shelled out of a program (e.g., vim) then
# .bash_profile has already been processed.

((DONT_RECURSE_ME_BRO)) && return

if ! shopt -q login_shell && [[ $- != *i* ]]; then
  DONT_RECURSE_ME_BRO=1
  source "$HOME/.bash_profile"
fi

unset DONT_RECURSE_ME_BRO

##############################################################################
debug() { true; }
[[ -r "$GLOBAL_LIB/debug" ]] && source "$GLOBAL_LIB/debug"

##############################################################################
# This function takes one directory path and adds it to the existing path,
# make sure you unset it at the end of this script.

function addpath() {
  debug "adding $1 to path"
  PATH="${PATH}:$1"
}

##############################################################################
# If this tty can support 256 colors, set it.

if [[ $- == *i* ]] && [[ -z $TERM ]] && test -t; then
  if nc=$(tput colors); then
    [[ $nc -eq 256 ]] && TERM='xterm-256color'
  else
    debug 'unknown terminal type'
  fi
fi

##############################################################################
# Source global definitions

declare -a global=()

# XXX:Do we need to source /etc/bashrc?
#global+=('/etc/bashrc')
global+=('/etc/bash_completion')
global+=('/etc/profile.d/bash-completion')

for f in "${global[@]}"; do
  [[ -r $f ]] && {
    debug "Sourcing $f ..."
    source "$f" || debug "... unable to source $f"
  }
done

unset global

##############################################################################
declare -a rcdirs

rcdirs+=("$DOTFILES/.bashrc.d")
rcdirs+=("$HOME/.bashrc.d")

for rcdir in "${rcdirs[@]}"; do
  [[ -d $rcdir ]] || continue

  readarray -t rcfiles < <(/usr/bin/find "$rcdir/" -iname '*_rc' | /usr/bin/sort)

  for rcfile in "${rcfiles[@]}"; do
    [[ -r $rcfile ]] && {
      debug "Sourcing $rcfile ..."
      source "$rcfile" || debug "... unable to source $rcfile"
    }
  done
done

unset rcdirs rcdir rcfiles rcfile

##############################################################################
# The project can override anything they want in this file.

profile_file="$SCRIPTS_DIR/profile/profile.project.${PRJ_NAME}.$PRJ_ENVIRONMENT"

[[ -r $profile_file ]] && {
  debug "Sourcing $profile_file ..."
  source "$profile_file" || echo "... unable to source $profile_file"
}

##############################################################################
# Final cleanup of PATH and LD_LIBRARY_PATH environment variables. There are
# some duplicate paths, some paths that don't exist and some paths should come
# at the beginning of the path, while others should appear at the end of the
# path.

#-----------------------------------------------------------------------------
get_real_dir() {
  local d=$1

  # What is the real path for $d?
  dir=$(readlink -ne "$d") || return 1

  # does $dir exist?
  [[ -z $dir ]] && return 1

  # is $dir a directory?
  [[ -d $dir ]] || return 1

  echo "$dir"
  return 0
}

#-----------------------------------------------------------------------------
# join with colon
# No, IFS=':' echo "$*" does not work.
# XXX: will echo -e "${@// /:}" work?

jwc() {
  local IFS=':'
  echo "$*"
  return 0
}

#-----------------------------------------------------------------------------
declare -A SHOULD_BE_FIRST SHOULD_BE_LAST SHOULD_BE_IGNORED SHOULD_BE_STRIPPED

build_path() {
  local path="${1?Must pass path}"

  declare -a PATHS PATH_FIRST PATH_NEW PATH_LAST
  declare -A PATH_CHECK

  IFS=':' read -ra PATHS <<< "${!path}"

  for d in "${PATHS[@]}"; do
    debug "Checking $d ..."

    # Ignore blank entries
    [[ -z $d ]] && continue

    # Ignore dot
    [[ $d == '.' ]] && continue

    # Have we already handled this directory?
    [[ ${PATH_CHECK[$d]+isset} -ne 0 ]] && continue

    if [[ ${SHOULD_BE_IGNORED[$d]+isset} -ne 0 ]]; then
      PATH_NEW+=("$d")
      PATH_CHECK[$d]=1
      debug "IGNORE: $d"
      continue

    elif [[ ${SHOULD_BE_STRIPPED[$d]+isset} -ne 0 ]]; then
      PATH_CHECK[$dir]=1
      debug "STRIP: $d"
      continue
    fi

    # Get the real path, if it really exists.
    dir=$(get_real_dir "$d") || continue

    # Have we already handled this directory?
    [[ ${PATH_CHECK[$dir]+isset} -ne 0 ]] && continue

    if [[ ${SHOULD_BE_STRIPPED[$dir]+isset} -ne 0 ]]; then
      debug "STRIP: $dir"

    elif [[ ${SHOULD_BE_FIRST[$dir]+isset} -ne 0 ]]; then
      PATH_FIRST+=("$dir")
      debug "FIRST: $dir"

    elif [[ ${SHOULD_BE_LAST[$dir]+isset} -ne 0 ]]; then
      PATH_LAST+=("$dir")
      debug "LAST: $dir"

    else
      PATH_NEW+=("$dir")
      debug "DIR: $dir"
    fi

    PATH_CHECK[$dir]=1
  done

  jwc "${PATH_FIRST[@]}" "${PATH_NEW[@]}" "${PATH_LAST[@]}"

  return 0
}

#-----------------------------------------------------------------------------
# Entries in PATH_SHOULD_BE_{FIRST,LAST} should be the 'real' path; i.e., the
# path returned from the above 'get_real_dir' function.

# These paths should appear at the beginning of the PATH list.
#PATH_SHOULD_BE_FIRST['/first']=1

# These paths should appear at the end of the PATH list.
#SHOULD_BE_LAST['/last']=1

#-----------------------------------------------------------------------------
# Cleanup PATH variable
debug "Cleaning path ..."

#SHOULD_BE_FIRST=()
#SHOULD_BE_LAST=()
#SHOULD_BE_IGNORED=()
#SHOULD_BE_STRIPPED=()

SHOULD_BE_LAST['/app/teradata/client/16.20/bin']=1
SHOULD_BE_LAST['/app/teradata/client/16.20/datamover/commandline']=1
SHOULD_BE_LAST['/usr/lib64/qt-3.3/bin']=1
SHOULD_BE_LAST['/app/dmexpress/bin']=1
SHOULD_BE_LAST['/app/fileport/bin']=1
SHOULD_BE_LAST['/app/gp/greenplum-loaders/bin']=1
SHOULD_BE_LAST['/app/gp/greenplum-loaders/ext/python/bin']=1
SHOULD_BE_LAST['/app/gp/greenplum-clients/bin']=1
SHOULD_BE_LAST['/app/gp/greenplum-loaders-5.15.1/bin']=1
SHOULD_BE_LAST['/app/gp/greenplum-loaders-5.15.1/ext/python/bin']=1
SHOULD_BE_LAST['/app/gp/greenplum-clients-5.15.1/bin']=1

NEWPATH=$(build_path 'PATH')
export PATH="$NEWPATH:."

#-----------------------------------------------------------------------------
# Cleanup LD_LIBRARY_PATH variable
debug "Cleaning ld library path ..."

LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib:/usr/lib64"

#SHOULD_BE_FIRST=()
SHOULD_BE_LAST=()
#SHOULD_BE_IGNORED=()
#SHOULD_BE_STRIPPED=()

SHOULD_BE_FIRST['/usr/lib']=1
SHOULD_BE_FIRST['/usr/lib64']=1

NEWLDPATH=$(build_path 'LD_LIBRARY_PATH')
export LD_LIBRARY_PATH="$NEWLDPATH"

unset -f get_real_dir jwc build_path addpath
unset NEWPATH NEWLDPATH SHOULD_BE_FIRST SHOULD_BE_LAST
unset SHOULD_BE_IGNORED SHOULD_BE_STRIPPED f

#-----------------------------------------------------------------------------
# Setup the prompt

# XXX: Maybe don't do this if .bash_prompt.d doesn't exist
#      somewhere?

[[ $PRJ_ENVIRONMENT =~ adm|dev|test ]] && {
  debug "Setting prompt ..."
  source "$DOTFILES/.bash_prompt"
}

[[ $USER =~ z[0-9]* ]] && {
  debug "Setting prompt ..."
  source "$DOTFILES/.bash_prompt"
}

# Don't want to see error here if it PRJHOME doesn't exist
# shellcheck disable=SC2164
[[ -n $PRJHOME ]] && [[ -d $PRJHOME ]] && cd "$PRJHOME"
