#!/usr/bin/env bats

# Tests for bin/envsubstitute — a custom envsubst supporting $WORD / ${WORD}
# and %WORD% (via SUBST_DELIM), backslash escaping, and NO_WARN handling.
# Replaces the old manual demo tests/test_envsubstitute (archived).

# shellcheck disable=SC2016  # tests deliberately pass/expect literal $WORD text
load ../helpers/common

setup() {
  load_bats_libs
  cd "$(dotfiles_root)" || return 1
}

@test "envsubstitute expands \$NAME" {
  NAME=John run bin/envsubstitute '$NAME'
  assert_success
  assert_output 'John'
}

@test "envsubstitute expands \${NAME} in context" {
  NAME=John run bin/envsubstitute 'a ${NAME} b'
  assert_success
  assert_output 'a John b'
}

@test "envsubstitute expands %NAME% with SUBST_DELIM=%" {
  SUBST_DELIM='%' NAME=John run bin/envsubstitute '%NAME%'
  assert_success
  assert_output 'John'
}

@test "envsubstitute keeps a backslash-escaped \$NAME literal" {
  NAME=John run bin/envsubstitute '\$NAME'
  assert_success
  assert_output '\$NAME'
}

@test "envsubstitute keeps a backslash-escaped \${NAME} literal" {
  NAME=John run bin/envsubstitute '\${NAME}'
  assert_success
  assert_output '\${NAME}'
}

@test "envsubstitute reads from stdin" {
  NAME=Jane run bash -c 'echo "p \$NAME" | bin/envsubstitute'
  assert_success
  assert_output 'p Jane'
}

@test "envsubstitute with NO_WARN preserves unknown variables silently" {
  NO_WARN=1 run bin/envsubstitute 'x $BADVAR y'
  assert_success
  assert_output 'x $BADVAR y'
}

@test "envsubstitute marks an unknown variable NOT FOUND and warns" {
  run bin/envsubstitute '$BADVAR'
  assert_success
  assert_output --partial '${BADVAR: NOT FOUND}'
  assert_output --partial 'does not exist'
}

@test "envsubstitute -h prints usage" {
  run bin/envsubstitute -h
  assert_success
  assert_output --partial 'Usage:'
}
