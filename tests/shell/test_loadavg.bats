#!/usr/bin/env bats

# Tests for bin/loadavg — print a colored "Load Avg: <n>" only when the
# 15-minute load average exceeds 2.0, otherwise print nothing.
#
# The threshold branch is white-boxed: loadavg reads the value with
# `awk '{print $3}' /proc/loadavg`, so we stub `awk` to inject a chosen load
# (we can't write /proc/loadavg) while keeping the REAL `bc` — that exercises
# the genuine `> 2.0` comparison and the script's `-eq 0` inversion of bc's
# 0/1 result. `ansi` is stubbed to emit recognizable markers so the colored
# output is deterministic. The /proc/loadavg-unreadable guard isn't covered:
# the path is hardcoded and can't be made unreadable in the sandbox.

load ../helpers/common

setup() {
  load_bats_libs

  STUB="$(make_stub_dir)"

  # awk stub: emit $LA_STUB regardless of program/input, so each test controls
  # the load value the script sees.
  # shellcheck disable=SC2016  # $LA_STUB must stay literal — read at stub runtime
  make_script_stub "$STUB" awk 'printf "%s\n" "$LA_STUB"'

  # ansi stub: echo its args verbatim so the color markers are assertable.
  make_script_stub "$STUB" ansi 'printf "[ansi:%s]" "$*"'

  PATH="$STUB:$(dotfiles_root)/bin:$PATH"
}

@test "loadavg prints a colored line when load is above 2.0" {
  LA_STUB=3.50 run loadavg
  assert_success
  assert_output --partial 'Load Avg: 3.50'
  assert_output --partial '[ansi:-n fg yellow bg red]'
  assert_output --partial '[ansi:-n off]'
}

@test "loadavg prints nothing when load is below 2.0" {
  LA_STUB=0.50 run loadavg
  assert_success
  assert_output ''
}

@test "loadavg prints nothing at exactly 2.0 (threshold is strict >)" {
  LA_STUB=2.0 run loadavg
  assert_success
  assert_output ''
}

@test "loadavg prints just above the threshold" {
  LA_STUB=2.01 run loadavg
  assert_success
  assert_output --partial 'Load Avg: 2.01'
}

@test "loadavg exits silently when bc is unavailable" {
  # PATH without the system dirs → `command -v bc` fails → early exit 0.
  LA_STUB=9.99 run env PATH="$STUB:$(dotfiles_root)/bin" loadavg
  assert_success
  assert_output ''
}
