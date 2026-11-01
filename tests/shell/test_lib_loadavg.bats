#!/usr/bin/env bats

# Tests for lib/loadavg — loadavg_classify, the load-average reader shared by
# bin/loadavg, bin/tmux_loadavg and bin/motd. Load averages come from fixture
# files; the CPU count from an nproc stub, so the thresholds are fixed by the
# test.

load ../helpers/common

setup() {
  load_bats_libs

  LIB="$(dotfiles_root)/lib/loadavg"
  LOADAVG="$BATS_TEST_TMPDIR/loadavg"

  STUB="$BATS_TEST_TMPDIR/stub"
  mkdir -p "$STUB"
  make_script_stub "$STUB" nproc 'echo 2'
  export PATH="$STUB:$PATH"

  # shellcheck source=/dev/null
  source "$LIB"
}

fixture() {
  printf '%s\n' "$1" > "$LOADAVG"
}

# Prints "<load>:<level>" for each value, space-separated, so one assertion
# checks both arrays.
classify() {
  local loads=() levels=() i out=

  loadavg_classify loads levels "$@" || return

  for i in "${!loads[@]}"; do
    out+="${loads[i]}:${levels[i]} "
  done

  printf '%s' "$out"
}

@test "lib/loadavg refuses to be executed" {
  run bash "$LIB"
  assert_failure
  assert_output --partial 'is a library'
}

@test "sourcing lib/loadavg leaves no variables behind" {
  run bash -c 'a= b=; a=$(compgen -v); source "$1"; b=$(compgen -v); [[ $a == "$b" ]]' _ "$LIB"
  assert_success
}

@test "loads at or under one per CPU are ok" {
  fixture '0.50 1.25 2.00 1/123 4567'

  run classify "$LOADAVG"
  assert_success
  assert_output '0.50:ok 1.25:ok 2.00:ok '
}

@test "above one load per CPU is warn, above two is alert" {
  fixture '2.01 4.01 4.00 1/123 4567'

  run classify "$LOADAVG"
  assert_success
  assert_output '2.01:warn 4.01:alert 4.00:warn '
}

@test "the thresholds scale with the CPU count" {
  make_script_stub "$STUB" nproc 'echo 8'
  fixture '8.00 8.01 16.01 1/123 4567'

  run classify "$LOADAVG"
  assert_success
  assert_output '8.00:ok 8.01:warn 16.01:alert '
}

@test "a value with a leading zero is not read as octal" {
  fixture '0.08 0.09 0.10 1/123 4567'

  run classify "$LOADAVG"
  assert_success
  assert_output '0.08:ok 0.09:ok 0.10:ok '
}

@test "getconf supplies the CPU count when nproc fails" {
  make_script_stub "$STUB" nproc 'exit 1'
  make_script_stub "$STUB" getconf 'echo 4'
  fixture '4.01 8.00 8.01 1/123 4567'

  run classify "$LOADAVG"
  assert_success
  assert_output '4.01:warn 8.00:warn 8.01:alert '
}

@test "with no CPU count, one CPU is assumed" {
  make_script_stub "$STUB" nproc 'exit 1'
  make_script_stub "$STUB" getconf 'exit 1'
  fixture '1.01 0.99 2.01 1/123 4567'

  run classify "$LOADAVG"
  assert_success
  assert_output '1.01:warn 0.99:ok 2.01:alert '
}

@test "a missing file returns 1 and empties both arrays" {
  local loads=(stale) levels=(stale) rc=0

  loadavg_classify loads levels "$BATS_TEST_TMPDIR/absent" || rc=$?

  assert_equal "$rc" 1
  assert_equal "${#loads[@]}" 0
  assert_equal "${#levels[@]}" 0
}

@test "an unreadable file returns 1" {
  ((EUID != 0)) || skip "root reads files regardless of mode"

  fixture '0.50 0.50 0.50 1/123 4567'
  chmod 000 "$LOADAVG"

  run classify "$LOADAVG"
  assert_failure 1
  assert_output ''
}

@test "a file that does not parse returns 1 and empties both arrays" {
  local loads=() levels=() rc=0

  fixture '0.50 0.50 high 1/123 4567'

  loadavg_classify loads levels "$LOADAVG" || rc=$?

  assert_equal "$rc" 1
  assert_equal "${#loads[@]}" 0
  assert_equal "${#levels[@]}" 0
}

@test "a file with fewer than three values returns 1" {
  fixture '0.50 0.50'

  run classify "$LOADAVG"
  assert_failure 1
  assert_output ''
}

@test "with no file argument, /proc/loadavg is read" {
  [[ -r /proc/loadavg ]] || skip "no /proc/loadavg on this system"

  run classify
  assert_success
  assert_output --regexp '^([0-9]+\.[0-9]{2}:(ok|warn|alert) ){3}$'
}
