#!/bin/bash

# See function at
# https://github.com/wschlich/bashinator/blob/master/bashinator.lib.0.sh#L940
# for ideas on building a better prefix.

function debug() {
  [[ ! -f ~/.dot_debug ]] && return 0

#  {
#    printf '\nBASH_SOURCE'
#    printf ' : %s' "${BASH_SOURCE[@]}"
#    printf '\nFUNCNAME'
#    printf ' : %s' "${FUNCNAME[@]}"
#    printf '\nBASH_LINENO'
#    printf ' : %s' "${BASH_LINENO[@]}"
#    printf '\n'
#  } >>"$HOME/.dotfiles.log"

  local datestamp filename funcname lineno prefix

  datestamp=$(date +'[%Y%m%d %H:%M:%S]')
  filename=$(basename "${BASH_SOURCE[1]:-$0}")
  funcname="${FUNCNAME[1]}"
  lineno="${BASH_LINENO[0]}"

  [[ $funcname =~ ^main|source$ ]] && funcname='not in func'

  prefix=$(printf '%s[%s:%s:%s]' "$datestamp" "$filename" "$funcname" "$lineno")

  printf '%s: %s\n' "$prefix" "$*" >>"$HOME/.dotfiles.log"
}

export -f debug

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
  local dir="$1"

  [[ ! -d $dir ]] && {
    debug "$dir does not exist or is not a directory"
    return
  }

  debug "Loading files in $dir ..."

  readarray -t files < <(find "$dir" -type f)

  for s in "${files[@]}"; do
    debug "Sourcing $s ..."
    # shellcheck disable=SC1090
    source "$s"
  done
}

export -f source_dir
