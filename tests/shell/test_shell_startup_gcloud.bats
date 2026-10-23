#!/usr/bin/env bats

# Tests for config/shell-startup/gcloud: gcloud-sa, which switches this
# shell's gcloud named configuration and the GOOGLE_APPLICATION_CREDENTIALS
# that client libraries read, and its completion. The functions are extracted
# from the module (which returns early in a non-interactive shell) and gcloud
# is stubbed, so the real command never runs.
#
# The switch tests call gcloud-sa directly rather than through `run`, because
# `run` executes in a subshell and the exported variables are the behaviour
# under test.

# Each @test runs in its own subshell by design, so the per-test exports that
# are flagged as lost to that subshell are meant to be.
# shellcheck disable=SC2030,SC2031

load ../helpers/common

setup() {
  load_bats_libs

  eval "$(source_funcs "$(dotfiles_root)/config/shell-startup/gcloud" \
    gcloud-sa _gcloud_sa)"

  STUB="$(make_stub_dir)"

  # The stub knows one configuration, "work"; describing any other fails,
  # as gcloud does for a configuration that does not exist. Its list output
  # is what value[separator="|"] prints; STUB_ACCOUNT stands in for the
  # configuration's core/account, and may be empty.
  # shellcheck disable=SC2016 # expanded when the stub runs
  make_script_stub "$STUB" gcloud '
printf "%s\n" "$*" >> "${0}.args"
case "$*" in
  "config configurations describe work") exit 0 ;;
  "config configurations describe "*) exit 1 ;;
  "config configurations list "*)
    printf "%s|%s|%s\n" "${CLOUDSDK_ACTIVE_CONFIG_NAME:-default}" \
      "${STUB_ACCOUNT-sa@proj-1.iam.gserviceaccount.com}" proj-1
    ;;
esac'

  PATH="$STUB:$PATH"
  XDG_DATA_HOME="$BATS_TEST_TMPDIR/data"
  KEYS="$XDG_DATA_HOME/gcloud/keys"
  mkdir -p "$KEYS"

  unset CLOUDSDK_ACTIVE_CONFIG_NAME GOOGLE_APPLICATION_CREDENTIALS
}

teardown() {
  rm -rf "$STUB"
}

#-----------------------------------------------------------------------------
# Showing the current one

@test "with no argument, shows the active configuration, account, project" {
  run gcloud-sa
  assert_success
  assert_line --partial "configuration: default"
  assert_line --partial "account:       sa@proj-1.iam.gserviceaccount.com"
  assert_line --partial "project:       proj-1"
  assert_line --partial "credentials:   (unset)"
}

@test "an unset account does not shift the project into its place" {
  STUB_ACCOUNT='' run gcloud-sa
  assert_success
  assert_line --partial "account:       (unset)"
  assert_line --partial "project:       proj-1"
}

@test "shows the credentials path, never the key's contents" {
  echo 'NOT-FOR-OUTPUT' > "$KEYS/work.json"
  export GOOGLE_APPLICATION_CREDENTIALS="$KEYS/work.json"

  run gcloud-sa
  assert_success
  assert_line --partial "credentials:   $KEYS/work.json"
  refute_output --partial 'NOT-FOR-OUTPUT'
}

@test "flags a credentials path whose file is missing" {
  export GOOGLE_APPLICATION_CREDENTIALS="$KEYS/gone.json"

  run gcloud-sa
  assert_success
  assert_line --partial "credentials:   $KEYS/gone.json (missing)"
}

#-----------------------------------------------------------------------------
# Switching

@test "switches the configuration and points ADC at its key" {
  echo 'NOT-FOR-OUTPUT' > "$KEYS/work.json"

  gcloud-sa work > "$BATS_TEST_TMPDIR/out"

  assert_equal "$CLOUDSDK_ACTIVE_CONFIG_NAME" work
  assert_equal "$GOOGLE_APPLICATION_CREDENTIALS" "$KEYS/work.json"

  run cat "$BATS_TEST_TMPDIR/out"
  assert_line --partial "configuration: work"
  refute_output --partial 'NOT-FOR-OUTPUT'
}

@test "switching does not change gcloud's global active configuration" {
  gcloud-sa work > /dev/null

  run cat "$STUB/gcloud.args"
  refute_output --partial 'activate'
}

@test "switching to a configuration with no key clears a stale key" {
  export GOOGLE_APPLICATION_CREDENTIALS="$KEYS/previous.json"

  gcloud-sa work > "$BATS_TEST_TMPDIR/out"

  assert_equal "$CLOUDSDK_ACTIVE_CONFIG_NAME" work
  [[ -z ${GOOGLE_APPLICATION_CREDENTIALS+x} ]]

  run cat "$BATS_TEST_TMPDIR/out"
  assert_line --partial "no key at $KEYS/work.json"
}

@test "an unknown configuration fails and leaves the environment alone" {
  export CLOUDSDK_ACTIVE_CONFIG_NAME=before
  export GOOGLE_APPLICATION_CREDENTIALS="$KEYS/before.json"

  run gcloud-sa nosuch
  assert_failure
  assert_output --partial "no gcloud configuration named 'nosuch'"

  gcloud-sa nosuch 2> /dev/null || true
  assert_equal "$CLOUDSDK_ACTIVE_CONFIG_NAME" before
  assert_equal "$GOOGLE_APPLICATION_CREDENTIALS" "$KEYS/before.json"
}

@test "rejects a name gcloud would not accept, without calling gcloud" {
  run gcloud-sa ../work
  assert_failure
  assert_output --partial "not a valid configuration name"
  [[ ! -f "$STUB/gcloud.args" ]]
}

@test "rejects more than one argument" {
  run gcloud-sa work other
  assert_failure
  assert_output --partial "Usage: gcloud-sa"
  [[ ! -f "$STUB/gcloud.args" ]]
}

@test "--help prints usage without calling gcloud" {
  run gcloud-sa --help
  assert_success
  assert_output --partial "Usage: gcloud-sa"
  [[ ! -f "$STUB/gcloud.args" ]]
}

#-----------------------------------------------------------------------------
# Completion

@test "completes configuration names without calling gcloud" {
  export CLOUDSDK_CONFIG="$BATS_TEST_TMPDIR/gcloud"
  mkdir -p "$CLOUDSDK_CONFIG/configurations"
  touch "$CLOUDSDK_CONFIG/configurations/config_work" \
    "$CLOUDSDK_CONFIG/configurations/config_personal"

  COMP_WORDS=(gcloud-sa w)
  COMP_CWORD=1
  _gcloud_sa

  assert_equal "${COMPREPLY[*]}" work
  [[ ! -f "$STUB/gcloud.args" ]]
}
