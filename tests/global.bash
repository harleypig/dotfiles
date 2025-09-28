#!/bin/bash

# Modern bats-core global test setup
# Updated for bats-core 1.7.0+ with modern best practices
#
# This file provides common utilities and setup functions shared across all
# BATS test files. It should be sourced by individual test files for consistent
# testing infrastructure.
#
# Modern bats-core documentation:
# - https://bats-core.readthedocs.io/
# - https://github.com/bats-core/bats-core
# - https://github.com/bats-core/bats-assert
# - https://github.com/bats-core/bats-file

#----------------------------------------------------------------------------
# Version Requirements and Modern Setup

# Require minimum bats-core version for modern features
bats_require_minimum_version "1.7.0"

# Load modern bats-core helper libraries
# These provide essential testing utilities and assertions
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'
load 'test_helper/bats-file/load'

#----------------------------------------------------------------------------
# Debug Output Function

# Print debug information during tests without breaking TAP output
# Usage: note "Debug message" or note "Line 1" "Line 2"
note() {
  local prefix="${BATS_TEST_DESCRIPTION:-}"

  for line in "$@"; do
    printf '# %s%s\n' "$prefix" "$line" >&3
  done
}

export -f note

#----------------------------------------------------------------------------
# Enhanced Random String Generator

# Generate random strings for testing purposes with improved portability
# 
# Examples:
#   value="$(random_string)"                    # 32 char alphanumeric
#   value="$(random_string alpha 15)"           # 15 char letters only
#   value="$(random_string numeric 8)"          # 8 char numbers only
#   value="$(random_string date)"               # Random date (default format)
#   value="$(random_string date '%Y%m%d')"      # Random date (custom format)

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
    alpha) 
      if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 "$count" | tr -d '=+/' | tr -dc 'a-zA-Z' | head -c "$count"
      else
        tr -dc 'a-zA-Z' < /dev/urandom | fold -w "$count" | head -n 1
      fi
      ;;
    numeric) 
      if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 "$count" | tr -d '=+/' | tr -dc '0-9' | head -c "$count"
      else
        tr -dc '0-9' < /dev/urandom | fold -w "$count" | head -n 1
      fi
      ;;
    date) 
      date -d "@$((RANDOM * RANDOM * RANDOM / 1000))" "$format" ;;
    *) 
      if command -v openssl >/dev/null 2>&1; then
        openssl rand -base64 "$count" | tr -d '=+/' | head -c "$count"
      else
        tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w "$count" | head -n 1
      fi
      ;;
  esac
}

#----------------------------------------------------------------------------
# Modern Setup and Teardown Framework

# Override this function in your test files for file-specific setup
test_setup_file() { return 0; }

# Override this function in your test files for suite-specific setup
test_setup_suite() { return 0; }

# Override this function in your test files for suite-specific teardown
test_teardown_suite() { return 0; }

# File-level setup (runs once per test file)
setup_file() {
  note "--- Test file: $(basename "$BATS_TEST_FILENAME")"
  test_setup_file
}

# Suite-level setup (runs once for entire test suite)
# Place this in setup_suite.bash for automatic execution
setup_suite() {
  note "--- Test suite setup"
  test_setup_suite
}

# Suite-level teardown (runs once for entire test suite)
# Place this in setup_suite.bash for automatic execution
teardown_suite() {
  note "--- Test suite teardown"
  test_teardown_suite
}

#----------------------------------------------------------------------------
# Modern Run Command Helpers

# Enhanced run command with options support
# Usage: run_with_options --separate-stderr --keep-empty-lines command args
run_with_options() {
  local options=()
  while [[ $1 == -* ]]; do
    options+=("$1")
    shift
  done
  run "${options[@]}" "$@"
}

# Run commands with pipes using bats_pipe
# Usage: run_pipe command1 \| command2 \| command3
run_pipe() {
  bats_pipe "$@"
}

#----------------------------------------------------------------------------
# Temporary Directory Management

# Create a temporary directory for the current test
# Usage: setup_temp_dir (sets TEST_TEMP_DIR variable)
setup_temp_dir() {
  TEST_TEMP_DIR="$(temp_make)"
  export TEST_TEMP_DIR
  note "Created temp directory: $TEST_TEMP_DIR"
}

# Clean up temporary directory
# Usage: cleanup_temp_dir (cleans up TEST_TEMP_DIR)
cleanup_temp_dir() {
  if [[ -n "$TEST_TEMP_DIR" ]]; then
    temp_del "$TEST_TEMP_DIR"
    note "Cleaned up temp directory: $TEST_TEMP_DIR"
    unset TEST_TEMP_DIR
  fi
}

#----------------------------------------------------------------------------
# Modern Error Handling

# Global failure hook - runs when any test fails
bats::on_failure() {
  note "Test failed: ${BATS_TEST_NAME:-unknown}"
  note "Status: ${status:-unknown}"
  note "Output: ${output:-none}"
  if [[ -n "${stderr:-}" ]]; then
    note "Stderr: $stderr"
  fi
}

#----------------------------------------------------------------------------
# Environment Configuration

# Set up test working directory
export TEST_WORKDIR="$BATS_TEST/work"

# Modern BATS environment variables
export BATS_TEST_TIMEOUT="${BATS_TEST_TIMEOUT:-60}"
export BATS_FILE_PATH_REM="${BATS_FILE_PATH_REM:-}"
export BATS_FILE_PATH_ADD="${BATS_FILE_PATH_ADD:-}"

# Enable preservation of temp directories on failure for debugging
export BATSLIB_TEMP_PRESERVE_ON_FAILURE="${BATSLIB_TEMP_PRESERVE_ON_FAILURE:-0}"

##############################################################################
# Modern BATS Best Practices and Notes

# Setup and Teardown Functions:
# - setup() / teardown(): Run before/after each test (including skipped tests)
# - setup_file() / teardown_file(): Run once per test file
# - setup_suite() / teardown_suite(): Run once for entire test suite
#
# Modern Features Available:
# - bats_pipe: Run commands with pipes correctly
# - run --separate-stderr: Split stdout and stderr
# - run --keep-empty-lines: Preserve empty lines in output
# - bats::on_failure: Hook for test failure handling
# - temp_make / temp_del: Temporary directory management
# - bats_require_minimum_version: Version compatibility checking
#
# Best Practices:
# - Use assert_* functions instead of raw bash comparisons
# - Use printf instead of echo for consistent output
# - Use [[ ]] instead of [ ] for conditionals
# - Use local variables in functions
# - Use return instead of exit in functions (except severe errors)
#
# Error Handling:
# - To abort all files after failure: exit 1 in global scope
# - To abort single file: create setup function that uses skip
# - To fail tests in single file: create setup function that returns 1
#
# Modern Assertions Available:
# - assert_output, assert_success, assert_failure
# - assert_file_exists, assert_dir_exists, assert_file_executable
# - assert_equal, assert_not_equal, assert_regex
# - And many more from bats-assert and bats-file libraries
