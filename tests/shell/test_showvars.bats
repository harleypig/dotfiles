#!/usr/bin/env bats

# Tests for bin/showvars — list the variables assigned in a bash script (via
# `shfmt -tojson | jq`). Three pure-bash GUARD paths die before any shfmt/jq
# call and so need no docker:
#   1. no args            → usage heredoc, exit 1
#   2. missing dependency → "depends on <tool>", exit 1 (shfmt/jq absent)
#   3. unreadable file    → "<file> is not readable.", exit 1
# The success path runs the real shfmt docker wrapper + jq, so it is gated on
# docker (skips otherwise). It also regression-guards the docker_wrapper stdin
# fix: showvars pipes `shfmt -tojson < file`, which returns an empty AST unless
# the wrapper forwards stdin (-i).

load ../helpers/common

SHOWVARS() { "$(dotfiles_root)/bin/showvars" "$@"; }

setup() {
  load_bats_libs
}

@test "showvars with no args prints usage and exits 1" {
  run SHOWVARS
  assert_failure 1
  assert_output --partial 'usage: showvars filename'
}

@test "showvars dies when a dependency (shfmt) is unavailable" {
  # Empty PATH → command_exists shfmt fails before the file loop.
  run env PATH="$(make_stub_dir)" "$(dotfiles_root)/bin/showvars" somefile
  assert_failure 1
  assert_output --partial 'depends on shfmt'
}

@test "showvars dies on an unreadable file once dependencies are present" {
  # Stub shfmt + jq so the dependency check passes; the unreadable-file guard
  # in _showvars then fires before either is actually invoked.
  local stub
  stub="$(make_stub_dir)"
  make_stub "$stub" shfmt
  make_stub "$stub" jq

  run env PATH="$stub:$PATH" "$(dotfiles_root)/bin/showvars" \
    "$BATS_TEST_TMPDIR/does-not-exist"
  assert_failure 1
  assert_output --partial 'is not readable.'
}

@test "showvars lists a script's assigned variables (docker integration)" {
  command -v docker > /dev/null 2>&1 || skip "docker not available"
  command -v jq > /dev/null 2>&1 || skip "jq not available"

  local sample="$BATS_TEST_TMPDIR/sample.sh"
  cat > "$sample" << 'SH'
#!/usr/bin/env bash
foo=1
bar="two"
qux=$((foo + 1))
SH

  # bin/ first so showvars resolves the shfmt docker wrapper.
  PATH="$(dotfiles_root)/bin:$PATH" run showvars "$sample"
  assert_success
  assert_output --partial '  bar'
  assert_output --partial '  foo'
  assert_output --partial '  qux'
}
