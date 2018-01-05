#!/bin/bash

# See function at
# https://github.com/wschlich/bashinator/blob/master/bashinator.lib.0.sh#L940
# for ideas on building a better prefix.

function debug() {
  [[ ! -f ~/.dot_debug ]] && return 0

  local datestamp filename function lineno prefix

  datestamp=$(date +'[%Y%m%d %H:%M:%S]')
  filename=$(basename "${BASH_SOURCE[1]:-$0}")
  funcname="${FUNCNAME[1]}"
  [[ $funcname == 'main' ]] && funcname='-'
  lineno="${BASH_LINENO[0]}"

  prefix=$(printf '%s[%s:%s:%s]' "$datestamp" "$filename" "$function" "$lineno")

  printf '%s: %s\n' "$prefix" "$*" >> "$HOME/.dotfiles.log"
}

export -f debug

debug "After defining debug ..."

########################################################################
# Don't delete this, it's for figuring things out sometimes.

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

#-----------------------------------------------------------------------
# Determines the fully qualified path of a file and sets $1 to the path.
# NOTE: Does not validate the path or file.
# Expects, in order:
#   The name of the variable to be set.
#   The name of the path to fully qualify.

function realpath() {

  local filename=$1

  fqfn=${filename//\~/$HOME}
  fqfn=$(readlink -nf "$fqfn")

  debug "filename: $filename fqfn: $fqfn"

  printf '%s' "$fqfn"

}

export -f realpath

#-----------------------------------------------------------------------
# Sources all files found in $1.
function source_dir() {
  debug "Loading files in $1 ..."

  #local -a files
  #files=$(find "$1" -type f)
  readarray -t files < <(find "$1" -type f)

  for s in "${files[@]}"; do
    debug "Sourcing $s ..."
    # shellcheck disable=SC1090
    source "$s"
  done
}

export -f source_dir

