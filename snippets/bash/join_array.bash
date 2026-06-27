# shellcheck shell=bash

# join_array — join the elements of a named array with a delimiter.
#
# Usage: join_array <delimiter> <array-name>
#   arr=(a b c); join_array ' | ' arr   # -> "a | b | c"
#
# Passes the array by *name* (a bash nameref, `local -n`), so the caller's
# array is read in place without copying — requires bash 4.3+. Calls the
# dotfiles `die` on misuse; swap in your own error handling when reusing this
# outside that environment.

# shellcheck disable=SC2329  # snippet: defined for reuse, not called here
join_array() {
  (($# != 2)) && die "must pass delimiter and array name"

  local delim="$1"
  local -n _array_="$2"

  local first="${_array_[0]}"
  local rest=("${_array_[@]:1}")

  printf '%s' "$first"
  printf '%s' "${rest[@]/#/$delim}"
}
