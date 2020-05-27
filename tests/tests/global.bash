#!/bin/bash

# Possible way to write a large number of similar tests:
# https://stackoverflow.com/a/50064603/491894

#----------------------------------------------------------------------------
# Print something to output in such a way it doesn't break TAP.
note() { printf '# %s\n' "$*" >&3; }

# Use test_setup for your own test file specific needs.
test_setup() { return 0; }

setup() {
  ((BATS_TEST_NUMBER == 1)) \
    && note "--- $(basename "$BATS_TEST_FILENAME")"

  declare -gx BATS_WORK="$WORK_DIR"
  [[ -z $WORK_DIR ]] && BATS_WORK="$BATS_TEST/tmp"

  mkdir -p "$BATS_WORK" || {
    echo "Cannot create $BATS_WORK"
    exit 1
  }

  test_setup
}

#----------------------------------------------------------------------------
BASEDIR="$(dirname "${BASH_SOURCE[0]}")/helpers"

readarray -t HELPERS < <(find "$BASEDIR" -iname '*.bash')

for h in "${HELPERS[@]}"; do
  source "$h"
done

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
