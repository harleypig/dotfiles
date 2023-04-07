#!/bin/bash

# Possible way to write a large number of similar tests:
# https://stackoverflow.com/a/50064603/491894

#----------------------------------------------------------------------------
# Print something to output in such a way it doesn't break TAP.

note() {
  local prefix="${BATS_TEST_DESCRIPTION:-}"

  for line in "$@"; do
    printf '# %s%s\n' "$prefix" "$line" >&3
  done
}

export -f note

#----------------------------------------------------------------------------
# Generate a random string

# Generate 32 character random letters and numbers.
# value="$(random_string)"

# Generate 15 character random letters.
# value="$(random_string alpha 10)"

# Generate 5 character random number.
# value="$(random_string numeric 5)"

# Generate random date with default format.
# value="$(random_string date)"

# Generate random date with specified format.
# value="$(random_string date '%Y%m%d')"

random_string() {
  local -l opt="$1"

  case "$opt" in
    'alpha' | 'numeric' | 'date') shift ;;
  esac

  local -i count=32
  local format

  [[ -n $1 ]] && {
    if [[ $opt == 'date' ]]; then
      format="+$1"
    else
      count=$1
    fi
  }

  case "$opt" in
    alpha) tr -dc 'a-zA-Z' < /dev/urandom | fold -w "$count" | head -n 1 ;;
    numeric) tr -dc '0-9' < /dev/urandom | fold -w "$count" | head -n 1 ;;
    date) date -d "@$((RANDOM * RANDOM * RANDOM / 1000))" "$format" ;;
    *) tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "$count" | head -n 1 ;;
  esac
}

#----------------------------------------------------------------------------
# Use test_setup and test_setup_file for your own test file specific needs.

test_setup_file() { return 0; }

setup_file() {
  note "--- Test file: $(basename "$BATS_TEST_FILENAME")"
  test_setup_file
}

#----------------------------------------------------------------------------
# Search for helpers and load them if they exist, bail all tests if they don't
# exist. First found is sourced. Order of search is:

# * A directory called 'helpers' in the same directory as this file.
# * $HOME/.bats/helpers
# * $BATS_LIBEXEC/helpers

# Alternatively, if BATS_LIB_PATH is set, each path in that variable is
# searched. See https://github.com/bats-core/bats-core/pull/27 for discussion
# and possible changes in future versions of bats.

# NOTE: Each path is presumed to be a directory, and anything passed to
# load_helper is presumed to be a directory. Any file with a '.bash' extension
# in that directory is sourced.

load_helper() {
  local helper="${1:?must pass helper name}"

if [[ -n $BATS_LIB_PATH ]]; then
  IFS=: read -ra helper_paths <<< "$BATS_LIB_PATH"

else
  declare -a helper_paths
  helper_paths+=("$(dirname "${BASH_SOURCE[0]}")/helpers")
  helper_paths+=("$HOME/.bats/helpers")
  helper_paths+=("$BATS_LIBEXEC/helpers")
fi


  note "Looking for $helper ..."

  for hp in "${helper_paths[@]}"; do
    #note "... in $hp ..."
    if [[ -d $hp/$helper ]]; then
      #note "... found $hp/$helper ..."
      for f in "$hp/$helper"/*.bash; do
        #note "... source $f ..."
        source "$f" || {
          printf 'Error loading %s\n' "$hp/$f"
          exit 1
        }

        return 0
      done
    fi
  done

  printf 'Could not find %s\n' "$helper"
  exit 1
}

load_helper bats-support
load_helper bats-assert
load_helper bats-file

#----------------------------------------------------------------------------
export TEST_WORKDIR="$BATS_TEST/work"

##############################################################################
# Notes

# Sources
#   bats-core readme:
#   https://stackoverflow.com/a/50022410/491894
#   https://stackoverflow.com/questions/24443777/how-do-you-programmatically-add-a-bats-test

# setup and teardown are run before and after each test, including skipped
# tests.

# redirect anything that isn't 'ok|not ok' to stderr (echo '' >&2).

# To abort *all* files after failure, use exit 1 in global scope.

# To only abort a single file, create a setup function that uses skip to only
# abort the tests in that file.

# To fail tests in a single file, create a setup function that uses return
# 1 to fail the tests in that file.
