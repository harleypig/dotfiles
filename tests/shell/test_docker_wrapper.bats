#!/usr/bin/env bats

# Tests for bin/docker_wrapper dispatch. Tool runs are exercised against a
# `docker` PATH-stub, so no docker daemon is required.

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"
  STUB="$(make_stub_dir)"
}

teardown() {
  rm -rf "$STUB"
}

@test "an unregistered tool name is rejected with exit 2" {
  ln -s "$ROOT/bin/docker_wrapper" "$STUB/bogustool"
  run "$STUB/bogustool"
  assert_failure 2
  assert_output --partial "unknown tool 'bogustool'"
}

@test "running docker_wrapper directly (not via a tool symlink) is rejected" {
  run "$ROOT/bin/docker_wrapper"
  assert_failure 2
  assert_output --partial "unknown tool 'docker_wrapper'"
}

@test "a host-gated tool refuses on a non-beaker host" {
  [[ "$(hostname -s)" == beaker ]] && skip "on beaker, the gate would pass"
  run "$ROOT/bin/ollama"
  assert_failure 1
  assert_output --partial "refusing to run"
}

@test "shfmt dispatch assembles the expected docker run command" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf '#!/usr/bin/env bash\necho hi\n' > script.sh

  run env "PATH=$STUB:$PATH" "$ROOT/bin/shfmt" -d script.sh
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "run"
  assert_output --partial "--rm"
  assert_output --partial "--workdir /mnt"
  assert_output --partial "mvdan/shfmt:v3"
  assert_output --partial "-d script.sh"
}

@test "the path guard blocks a file outside PWD before docker runs" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  run env "PATH=$STUB:$PATH" "$ROOT/bin/shellcheck" /etc/passwd
  assert_failure
  assert_output --partial "not under the current directory"
  # docker must not have been invoked
  assert_file_not_exist "$STUB/docker.args"
}
