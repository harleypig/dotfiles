#!/usr/bin/env bats

# Guards the docker integration harness helpers in tests/helpers/common.bash
# (#642 - harness build failure skipped): a harness image that will not build
# must turn the calling test red, and only a docker that cannot be used at all
# may skip it.
#
# Most cases run a generated fixture .bats file through a nested bats, because
# what is under test is how bats *reports* the calling test (ok / not ok /
# skip). Calling the helpers directly would not show that: `skip` inside
# $(...) exits only the subshell, which is the defect class these guard. The
# fixture's own test body is `true` on purpose, so the only thing that can make
# it red is its setup -- an assertion there that happened to fail on an empty
# IMAGE would let the old skipping helper pass this suite.
#
# A stub `docker` on PATH stands in for the daemon, so these run without one.
# The last case uses the real docker, and skips without it, to prove docker's
# own build failure reaches the helper as a failure.

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"
  STUB="$BATS_TEST_TMPDIR/stub"
  FIXTURE="$BATS_TEST_TMPDIR/fixture.bats"
  mkdir -p "$STUB"
}

#------------------------------------------------------------------------------
# Write the fixture: one test whose setup is exactly the documented calling
# pattern for the startup image.

write_fixture() {
  cat > "$FIXTURE" << EOF
load '$ROOT/tests/helpers/common'

setup() {
  require_docker
  IMAGE="\$(dotfiles_harness_image)"
}

@test "fixture" {
  echo "IMAGE=\$IMAGE"
  true
}
EOF
}

#------------------------------------------------------------------------------
# A stub docker: `info` exits <info_rc>; `build` prints <build_msg> to stderr
# and exits <build_rc>. Anything else exits 0.

write_docker_stub() {
  local info_rc=$1 build_rc=$2 build_msg=$3

  make_script_stub "$STUB" docker "
case \$1 in
  info) exit $info_rc ;;
  build) echo '$build_msg' >&2; exit $build_rc ;;
esac
exit 0"
}

#------------------------------------------------------------------------------
# Run the fixture under a nested bats with <path> as PATH.

run_fixture() {
  write_fixture
  run env "PATH=$1" bats --formatter tap "$FIXTURE"
}

#------------------------------------------------------------------------------
# Build a one-directory PATH holding everything on the current PATH except
# docker, for the no-docker-CLI case. A copy of the listings rather than a
# trimmed PATH, since docker usually shares a directory (/usr/bin) with bash
# and bats themselves. Earlier PATH entries win, as they would on PATH.

path_without_docker() {
  local dir="$BATS_TEST_TMPDIR/nodocker" pathdir f
  local -a pathdirs

  mkdir -p "$dir"
  IFS=: read -ra pathdirs <<< "$PATH"

  for pathdir in "${pathdirs[@]}"; do
    for f in "$pathdir"/*; do
      [[ -e $f ]] || continue
      [[ ${f##*/} == docker ]] && continue
      [[ -e $dir/${f##*/} ]] || ln -s "$f" "$dir/${f##*/}"
    done
  done

  # Floor: without bats here the fixture cannot run at all, and the test
  # below would fail for that reason instead of the one it is about.
  [[ -e $dir/bats && ! -e $dir/docker ]] || return 1

  printf '%s' "$dir"
}

#------------------------------------------------------------------------------

# Red if a failed build skips the test (the #642 regression) or is swallowed
# into an empty IMAGE -- either way the fixture reports `ok` -- and red if
# docker's own error text no longer reaches the test output.
@test "a harness image that fails to build fails the calling test" {
  write_docker_stub 0 1 'ERROR: stub-broken-from-642'

  run_fixture "$STUB:$PATH"

  assert_failure
  assert_line 'not ok 1 fixture'
  refute_output --partial '# skip'
  assert_output --partial 'docker build of dotfiles-test:latest'
  assert_output --partial 'stub-broken-from-642'
}

# Red if a build that works is mistaken for a failure, or the tag is lost on
# the way back through $(...).
@test "a harness image that builds hands its tag to the calling test" {
  write_docker_stub 0 0 ''

  run_fixture "$STUB:$PATH"

  assert_success
  assert_line 'ok 1 fixture'
  refute_output --partial '# skip'
}

# Red if a docker CLI with no daemon fails the test instead of skipping it.
@test "an unreachable docker daemon skips the calling test" {
  write_docker_stub 1 1 'build must not be reached'

  run_fixture "$STUB:$PATH"

  assert_success
  assert_line 'ok 1 fixture # skip docker daemon not reachable'
  refute_output --partial 'build must not be reached'
}

# Red if a host with no docker at all fails the test instead of skipping it.
@test "no docker CLI skips the calling test" {
  local nodocker
  nodocker=$(path_without_docker)

  run_fixture "$nodocker"

  assert_success
  assert_line 'ok 1 fixture # skip docker not available'
}

# Red if docker's real build failure stops reaching build_harness_image as a
# non-zero status (for example, if a quiet flag ever swallowed it). Builds
# nothing: the Dockerfile fails at parse, before any image or network use.
@test "a real docker build failure is reported by build_harness_image" {
  require_docker

  local ctx="$BATS_TEST_TMPDIR/ctx"
  mkdir -p "$ctx"
  printf 'NOTANINSTRUCTION 642\n' > "$ctx/Dockerfile"

  run build_harness_image dotfiles-harness-probe-642:latest "$ctx"

  assert_failure
  assert_output --partial 'docker build of dotfiles-harness-probe-642:latest'
  assert_output --partial 'NOTANINSTRUCTION'
}
