#!/bin/bash

##############################################################################
export PATH="$PATH:$DOTFILES/lib:$DOTFILES/bin"

##############################################################################
debug() { true; }
command -v debug &> /dev/null && source debug

[[ -r $GLOBAL_LIB/BashCompletions ]] && source "$GLOBAL_LIB/BashCompletions"
[[ -r $GLOBAL_LIB/LoadRCs ]] && source "$GLOBAL_LIB/LoadRCs"

##############################################################################
# this function takes one directory path and adds it to the existing path

# Move this into utility?

function addpath() {
  debug "adding $1 to path"
  PATH="${PATH}:$1"
}

##############################################################################
# Source global definitions

#declare -a global=()
#
#global+=('/etc/bashrc')
#global+=('/etc/bash_completion')
#global+=('/etc/profile.d/bash-completion')
#
#for f in "${global[@]}"; do
#  [[ -r $f ]] && {
#    debug "Sourcing $f ..."
#    source "$f" || debug "... unable to source $f"
#  }
#done
#
#unset global

load_completions

###############################################################################
## If this tty can support 256 colors, set it.
#
#if [[ -z $TERM ]] && test -t; then
#  if nc=$(tput colors); then
#    [[ $nc -eq 256 ]] && TERM='xterm-256color'
#  else
#    debug 'unknown terminal type'
#  fi
#fi
#
###############################################################################
#declare -a rcdirs
#
#rcdirs+=("$DOTFILES/.bashrc.d")
#rcdirs+=("$HOME/.bashrc.d")
#
#for rcdir in "${rcdirs[@]}"; do
#  [[ -d $rcdir ]] || continue
#
#  readarray -t rcfiles < <(/usr/bin/find "$rcdir" -iname '*_rc' | /usr/bin/sort)
#
#  for rcfile in "${rcfiles[@]}"; do
#    [[ -r $rcfile ]] && {
#      debug "Sourcing $rcfile ..."
#      source "$rcfile" || debug "... unable to source $rcfile"
#    }
#  done
#done
#
#unset rcdirs rcdir rcfiles rcfile

load_rcs

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

# If using ccache, it needs to be first on the path
SHOULD_BE_FIRST['/usr/lib/ccache/bin']=1

NEWPATH=$(build_path 'PATH')
export PATH="$NEWPATH:."

#-----------------------------------------------------------------------------
# Cleanup LD_LIBRARY_PATH variable
debug "Cleaning ld library path ..."

LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/lib:/usr/lib64"

SHOULD_BE_FIRST=()
#SHOULD_BE_LAST=()
#SHOULD_BE_IGNORED=()
#SHOULD_BE_STRIPPED=()

SHOULD_BE_FIRST['/usr/lib']=1
SHOULD_BE_FIRST['/usr/lib64']=1

NEWLDPATH=$(build_path 'LD_LIBRARY_PATH')
export LD_LIBRARY_PATH="$NEWLDPATH"

unset -f get_real_dir jwc build_path debug addpath
unset NEWPATH NEWLDPATH SHOULD_BE_FIRST SHOULD_BE_LAST
unset SHOULD_BE_IGNORED SHOULD_BE_STRIPPED f

#-----------------------------------------------------------------------------
# Miscellaneous

[[ -f $DOTFILES/.Xresources ]] && command -v xrdb &> /dev/null && xrdb "$DOTFILES/.Xresources"

#-----------------------------------------------------------------------------
source "$DOTFILES/.bash_prompt"
