#!/usr/bin/env bats

# Tests for bin/gcloud-auth: the two back-to-back gcloud logins, the --help
# path, and the guard when gcloud is absent. gcloud is stubbed so the real
# command never runs.

load ../helpers/common

setup() {
  load_bats_libs
  SCRIPT="$(dotfiles_root)/bin/gcloud-auth"
  STUB="$(make_stub_dir)"
}

teardown() {
  rm -rf "$STUB"
}

@test "runs both gcloud logins with --no-launch-browser" {
  make_stub "$STUB" gcloud

  run env "PATH=$STUB:$PATH" "$SCRIPT"
  assert_success

  run cat "$STUB/gcloud.args"
  assert_line "auth login --no-launch-browser"
  assert_line "auth application-default login --no-launch-browser"
}

@test "--help prints usage without invoking gcloud" {
  make_stub "$STUB" gcloud

  run env "PATH=$STUB:$PATH" "$SCRIPT" --help
  assert_success
  assert_output --partial "Usage: gcloud-auth"
  [[ ! -f "$STUB/gcloud.args" ]]
}

@test "fails when gcloud is not installed" {
  # Run bash by absolute path (so the shebang's env lookup isn't affected),
  # but give the script an empty PATH so its own gcloud lookup finds nothing.
  run env "PATH=$STUB" "$(command -v bash)" "$SCRIPT"
  assert_failure 1
  assert_output --partial "gcloud is not installed"
}

@test "stops after the first login fails" {
  make_stub "$STUB" gcloud 1

  run env "PATH=$STUB:$PATH" "$SCRIPT"
  assert_failure

  # set -e + the failing first call means only one invocation was recorded.
  run cat "$STUB/gcloud.args"
  assert_line "auth login --no-launch-browser"
  refute_line "auth application-default login --no-launch-browser"
}
