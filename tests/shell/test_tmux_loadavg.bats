#!/usr/bin/env bats

# Tests for bin/tmux_loadavg — the load average, styled for tmux's status
# line. Load averages come from fixture files passed as the argument; the
# CPU count from an nproc stub, so the thresholds are fixed by the test.

load ../helpers/common

setup() {
  load_bats_libs

  TLA="$(dotfiles_root)/bin/tmux_loadavg"
  LOADAVG="$BATS_TEST_TMPDIR/loadavg"

  STUB="$BATS_TEST_TMPDIR/stub"
  mkdir -p "$STUB"
  make_script_stub "$STUB" nproc 'echo 2'
  export PATH="$STUB:$PATH"
}

loadavg() {
  printf '%s\n' "$1" > "$LOADAVG"
}

@test "more than one argument is a usage error" {
  run "$TLA" a b
  assert_failure 2
  assert_output --partial 'Usage:'
}

@test "loads at or under one per CPU are unstyled, space-separated" {
  loadavg '0.50 1.25 2.00 1/123 4567'

  run "$TLA" "$LOADAVG"
  assert_success
  assert_output '0.50 1.25 2.00 '
}

@test "a load over one per CPU is yellow, over two per CPU red" {
  loadavg '2.01 4.01 4.00 1/123 4567'

  run "$TLA" "$LOADAVG"
  assert_success
  assert_output '#[fg=yellow]2.01#[default] #[fg=red]4.01#[default] #[fg=yellow]4.00#[default] '
}

@test "a value with a leading zero is not read as octal" {
  loadavg '0.08 0.09 0.10 1/123 4567'

  run "$TLA" "$LOADAVG"
  assert_success
  assert_output '0.08 0.09 0.10 '
}

@test "with no CPU count, one CPU is assumed" {
  make_script_stub "$STUB" nproc 'exit 1'
  make_script_stub "$STUB" getconf 'exit 1'
  loadavg '1.01 0.99 2.01 1/123 4567'

  run "$TLA" "$LOADAVG"
  assert_success
  assert_output '#[fg=yellow]1.01#[default] 0.99 #[fg=red]2.01#[default] '
}

@test "a missing loadavg file prints nothing and succeeds" {
  run "$TLA" "$BATS_TEST_TMPDIR/absent"
  assert_success
  assert_output ''
}

@test "an unreadable loadavg file prints nothing and succeeds" {
  ((EUID != 0)) || skip "root reads files regardless of mode"

  loadavg '0.50 0.50 0.50 1/123 4567'
  chmod 000 "$LOADAVG"

  run "$TLA" "$LOADAVG"
  assert_success
  assert_output ''
}

@test "a loadavg file that does not parse prints nothing and succeeds" {
  loadavg 'not a load average'

  run "$TLA" "$LOADAVG"
  assert_success
  assert_output ''
}

@test "a file with fewer than three values prints nothing" {
  loadavg '0.50 0.50'

  run "$TLA" "$LOADAVG"
  assert_success
  assert_output ''
}
