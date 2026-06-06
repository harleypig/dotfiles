#!/usr/bin/env bash

# bats-toolbox — a first-class bats helper library of test conveniences.
#
# Load it like any other bats helper:
#   bats_load_library bats-toolbox
# It resolves from BATS_LIB_PATH; this repo's shell-startup puts
# $DOTFILES/lib/bats on that path so every repo on the machine can load it.
# (CI sets BATS_LIB_PATH to include the checkout's lib/bats.)
#
# It bundles TAP-safe diagnostics, random test data, temp-workspace helpers,
# and run wrappers. It is a plain utility library: it does NOT define
# setup_file/setup_suite, because a library loaded inside setup() runs after
# bats has already fired those file/suite hooks — imposing them here would be
# a no-op footgun. Consumers wire their own setup()/teardown().

#------------------------------------------------------------------------------
# Print a diagnostic line without breaking TAP output (goes to fd 3). One line
# per argument. Usage: note "message" or note "line 1" "line 2".

note() {
  local line

  for line in "$@"; do
    printf '# %s\n' "$line" >&3
  done
}

#------------------------------------------------------------------------------
# Generate a random string for test data.
#   random_string                 # 32-char alphanumeric
#   random_string alpha 15        # 15 letters
#   random_string numeric 8       # 8 digits
#   random_string date '%Y%m%d'   # a random date in the given format

random_string() {
  local -l kind="$1"

  case "$kind" in
    alpha | numeric | date) shift ;;
    *) kind="alnum" ;;
  esac

  if [[ $kind == date ]]; then
    local fmt="+${1:-%Y-%m-%d}"
    date -d "@$((RANDOM * RANDOM))" "$fmt"
    return
  fi

  local -i count="${1:-32}"
  local class

  case "$kind" in
    alpha) class='a-zA-Z' ;;
    numeric) class='0-9' ;;
    *) class='a-zA-Z0-9' ;;
  esac

  # Suppress tr's "write error: Broken pipe" when head closes the pipe early;
  # otherwise that warning can leak into captured output (run merges stderr).
  LC_ALL=C tr -dc "$class" < /dev/urandom 2> /dev/null | head -c "$count"
}

#------------------------------------------------------------------------------
# Per-test temporary workspace. setup_temp_dir sets TEST_TEMP_DIR; pair it with
# cleanup_temp_dir in teardown.

setup_temp_dir() {
  TEST_TEMP_DIR="$(mktemp -d)"
  export TEST_TEMP_DIR
}

cleanup_temp_dir() {
  [[ -n ${TEST_TEMP_DIR-} ]] || return 0

  rm -rf "$TEST_TEMP_DIR"
  unset TEST_TEMP_DIR
}

#------------------------------------------------------------------------------
# `run` with leading run-options forwarded (e.g. --separate-stderr,
# --keep-empty-lines) followed by the command. Usage:
#   run_with_options --separate-stderr some-cmd arg

run_with_options() {
  local -a opts=()

  while [[ ${1-} == -* ]]; do
    opts+=("$1")
    shift
  done

  run "${opts[@]}" "$@"
}

#------------------------------------------------------------------------------
# Run a pipeline through bats_pipe (so the exit status is the pipeline's).
# Usage: run_pipe cmd1 \| cmd2

run_pipe() {
  bats_pipe "$@"
}
