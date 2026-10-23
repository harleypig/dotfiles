#!/usr/bin/env bats

# Guards the path selector that decides whether the required perl-compile
# job in tests.yml builds a real Perl. A selector that misses a toolchain
# path does not fail: the job skips the build and still reports green, so a
# regression here is invisible in CI. The regex is read out of the workflow
# itself, so these cases test what CI actually runs.

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"
}

#----------------------------------------------------------------------------
# Print the single-quoted ERE from the perl-compile job's change detection.
selector_regex() {
  awk '
    /^  perl-compile:/      { in_job = 1; next }
    in_job && /^  [^ ]/     { exit }
    in_job && /'"'"'\^\(/   {
      sub(/^[^'"'"']*'"'"'/, "")
      sub(/'"'"'.*$/, "")
      print
      exit
    }
  ' "$ROOT/.github/workflows/tests.yml"
}

#----------------------------------------------------------------------------
# Assert the selector does (want=match) or does not (want=skip) select path.
check_path() {
  local want=$1 path=$2 re

  re="$(selector_regex)"

  if grep -qE "$re" <<< "$path"; then
    [[ $want == match ]] || fail "selector wrongly matched: $path"

  else
    [[ $want == skip ]] || fail "selector missed: $path"
  fi
}

@test "the perl-compile selector regex can be found in tests.yml" {
  run selector_regex
  assert_success
  assert_output --regexp '^\^\(.*\)\$$'
}

@test "the selector matches every perl-toolchain file" {
  check_path match lib/version-managers/perl
  check_path match config/vmgr/perl
  check_path match config/shell-startup/perl
  check_path match tests/shell/test_integration_vmgr_perl.bats
  check_path match tests/helpers/common.bash
}

@test "the selector matches files under tests/docker/perl/" {
  check_path match tests/docker/perl/Dockerfile
  check_path match tests/docker/perl/some/nested/file
}

@test "the selector skips files outside the perl toolchain" {
  check_path skip tests/docker/vmgr/Dockerfile
  check_path skip tests/docker/perlish/Dockerfile
  check_path skip config/vmgr/python
  check_path skip lib/version-managers/perl.bak
  check_path skip docs/lib/version-managers/perl
  check_path skip README.md
}
