#!/usr/bin/env bats

# Tests for bin/duration — print the elapsed time since a given date as
# "Nd Nh Nm" (omitting any zero component, nothing for ~now).

load ../helpers/common

setup() {
  load_bats_libs
  PATH="$(dotfiles_root)/bin:$PATH"
}

@test "duration prints minutes" {
  run duration "5 minutes ago"
  assert_success
  assert_output --partial '5m'
}

@test "duration prints hours and minutes" {
  run duration "90 minutes ago"
  assert_success
  assert_output --partial '1h 30m'
}

@test "duration prints days" {
  run duration "2 days ago"
  assert_success
  assert_output --partial '2d'
}

@test "duration prints nothing for ~now" {
  # No components to print; the trailing `[[ -n $string ]] && echo` leaves a
  # non-zero exit, so assert only the (empty) output.
  run duration "now"
  assert_output ''
}

@test "duration surfaces the date error for an unparseable argument" {
  # bin/duration does not validate its argument: an unparseable date makes the
  # underlying `date --date=...` fail and emit "invalid date" (on stderr, which
  # `run` captures). LC_ALL=C pins the English wording. This pins the
  # visible-error behavior, not validation the script doesn't (yet) do.
  LC_ALL=C run duration "not a real date"
  assert_output --partial 'invalid date'
}
