#!/bin/bash

# See function at
# https://github.com/wschlich/bashinator/blob/master/bashinator.lib.0.sh#L940
# for ideas on building a better prefix.

DEBUG_PREFIX=${BASH_SOURCE#$HOME/}

__debugit () {
  if [ -f ~/.dot_debug ]; then
    echo "$@" >> ~/.dotfiles_$$_$(date +%s).log
  fi
}

__debugit "${DEBUG_PREFIX}:$LINENO Entering ..."

########################################################################
# Don't delete this, it's for figuring things out sometimes.

#if [[ $- == *i* ]]; then
#  __debugit "${DEBUG_PREFIX} We are interactive ..."
#else
#  __debugit "${DEBUG_PREFIX} We are *not* interactive ..."
#fi
#
#if shopt -q login_shell; then
#  __debugit "${DEBUG_PREFIX} We are in a login shell ..."
#else
#  __debugit "${DEBUG_PREFIX} We are *not* in a login shell ..."
#fi
########################################################################

# Determines the fully qualified path of a file and sets $1 to the path.
# NOTE: Does not validate the path or file.
# Expects, in order:
#   The name of the variable to be set.
#   The name of the path to fully qualify.

__realpath () {

  local varname=$1  ; shift
  local filename=$1 ; shift

  fqfn=${filename//\~/$HOME}
  fqfn=$(readlink -nf $fqfn)

  printf -v "${varname}" "%s" "$fqfn"

}

# Builds a fully qualified path and sets $1 to the value.
# NOTE: Does not validate the path or file.
# Expects, in order:
#   The name of the variable to be set.
#   The name of the file to determine where to load files from.
#   The endpoint the path should have.

__buildpath () {

  local varname=$1    ; shift
  local sourcefile=$1 ; shift
  local endpoint=$1   ; shift

  __realpath 'realpath' "$sourcefile"
  realpath=$(dirname $realpath)

  printf -v "$varname" '%s' "${realpath}${endpoint}"

}

# Sources all files found in $1.
__source_files () {

  __debugit "${DEBUG_PREFIX}:${LINENO} Trying to source $1 ..."

  for s in $(ls $1 2> /dev/null); do
    __debugit "${DEBUG_PREFIX}:${LINENO} Sourcing $s ..."
    source $s

  done
}

# Sources all files found in either a hostspecific directory or a default directory.
__source_host_specific () {

  local endpoint="$1"
  local hostname=$(hostname)

  __buildpath 'path' "${BASH_SOURCE}" '/hostspecific'

  if [ -d "${path}/${hostname}" ]; then
    path="${path}/${hostname}/${endpoint}"
  else
    path="${path}/default/${endpoint}"
  fi

  __source_files $path

}

######################################################################################
# Some of these are found on (and modified to fit):
#
# superuser.com
# commandlinefu.com

# Change to directory and list it
function cdl() { cd $1; l; }

# Make directory and cd to it
function mkcd() { mkdir -p -- "$@" && cd "$_"; }

######################################################################################
# http://stackoverflow.com/questions/1687642/set-screen-title-from-shellscript/1687710#1687710
# XXX: Should check to see if we are in screen and do nothing unless we are.
# XXX: Should check to see if we are in screen or tmux and make appropriate calls.
function set_screen_title { echo -ne "\ek$1\e\\"; }

######################################################################################
# join an array. join must be a single character
## Set the array you want to join in the __JOIN variable.

## XXX: Allow for any size separator if IFS can handle \0

#function __join() {
#
#  SAVE_IFS="$IFS"
#  IFS="$*"
#  local joined="${__JOIN[*]}"
#  IFS="$SAVE_IFS"
#  echo "$joined"
#
#}

# I don't remember where I found this. This allows for arbitrary sized arrays.
# Example:
#   __join <delimiter> "${ARRAY[@]}"
#   joined=$(__join <delimiter> "${ARRAY[@]}"

function __join {

  local delim=$1 ; shift
  echo -n "$1"   ; shift

  printf "%s" "${@/#/$delim}"

}

# if __is_array_empty "${ARRAY[@]}"; then do stuff for empty array; fi
function __is_array_empty {

  local is_empty=0

  if [ "${#@}" -ne 0 ]; then
    is_empty=1
  fi

  return $is_empty

}

######################################################################################

function __duration() {

  local _date="$@"
  local _seconds=$(date --date="$_date" +%s)

  local _duration=$(($now - $_seconds))
  local _days=$(($_duration / (60*60*24) ))
  local _hours=$(($_duration % (60*60*24) / (60*60) ))
  local _minutes=$(($_duration % (60*60) / 60))

  local _string

  if [[ $_days -ne 0 ]]; then
    _string="${_string}${_days}d "
  fi

  if [[ $_hours -ne 0 ]]; then
    _string="${_string}${_hours}h "
  fi

  if [[ $_minutes -ne 0 ]]; then
    _string="${_string}${_minutes}m "
  fi

  echo $_string

}

# Don't remember where I got this. Returns true if the current terminal can do
# 256 colors, otherwise it returns false.
can256 () { [ $(tput Co 2> /dev/null || tput colors 2> /dev/null || echo 0) -gt 2 ] ; }

# bash-completion for aliases
# https://unix.stackexchange.com/questions/4219/how-do-i-get-bash-completion-for-command-aliases
# http://ubuntuforums.org/showthread.php?t=733397
#
# alias gco='git checkout'
# make-completion-wrapper _git _git_checkout git checkout
# complete -F _git_checkout gco
#
# This doesn't work. At least for git.
#
# See also:
# https://stackoverflow.com/questions/342969/how-do-i-get-bash-completion-to-work-with-aliases

function make-completion-wrapper () {
  local function_name="$2"
  local arg_count=$(($#-3))
  local comp_function_name="$1"
  shift 2
  local function="
    function $function_name {
      ((COMP_CWORD+=$arg_count))
      COMP_WORDS=( "$@" \${COMP_WORDS[@]:1} )
      "$comp_function_name"
      return 0
    }"
  eval "$function"
  echo $function_name
  echo "$function"
}

__buildpath 'BIGFUNCTIONS' "${BASH_SOURCE}" "/.bash_functions.d/*"
for s in $(ls $BIGFUNCTIONS 2> /dev/null); do source $s; done

__buildpath 'HOSTSPECIFIC' "${BASH_SOURCE}" "/hostspecific/$(hostname)/*functions*"
for s in $(ls $HOSTSPECIFIC 2> /dev/null); do source $s; done

__debugit "${BASH_SOURCE#$HOME/}:$LINENO Exiting ..."
