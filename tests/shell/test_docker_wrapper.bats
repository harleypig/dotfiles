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

@test "markdownlint dispatch assembles the expected docker run command" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf '# Title\n' > doc.md

  run env "PATH=$STUB:$PATH" "$ROOT/bin/markdownlint" doc.md
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "run"
  assert_output --partial "--workdir /mnt"
  assert_output --partial "ghcr.io/igorshubovych/markdownlint-cli:v0.48.0"
  assert_output --partial "doc.md"
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

@test "terraform plan forwards set cloud credentials by name" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  # Credential VALUES use distinctive canaries, not short strings. The wrapper
  # mounts $PWD into docker.args (--volume <PWD>:/mnt), and under bats $PWD is a
  # random tmpdir (e.g. .../bats-run-a9tokQ3/...). A short sentinel like "tok"
  # can appear by chance in that path, so refute_output --partial would match
  # the mount path instead of a real leak — a rare CI flake. A canary can't
  # collide with a 6-char random path component. See the regression test below.
  run env "PATH=$STUB:$PATH" \
    AWS_ACCESS_KEY_ID=canary_aws_access_key AWS_SECRET_ACCESS_KEY=canary_aws_secret \
    AWS_ENDPOINT_URL_S3=https://example.com LINODE_TOKEN=canary_linode_token \
    "$ROOT/bin/terraform" plan
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "hashicorp/terraform:1.15"
  # Forwarded by name only — the value never reaches the command line.
  assert_output --partial "--env AWS_ACCESS_KEY_ID"
  assert_output --partial "--env AWS_SECRET_ACCESS_KEY"
  assert_output --partial "--env AWS_ENDPOINT_URL_S3"
  assert_output --partial "--env LINODE_TOKEN"
  refute_output --partial "canary_aws_access_key"
  refute_output --partial "canary_aws_secret"
  refute_output --partial "canary_linode_token"
}

@test "terraform credential-leak check is not fooled by the mount path" {
  # Regression for the flake above: the mount path (--volume <PWD>:/mnt) lands
  # in docker.args, so a short credential sentinel could collide with $PWD and
  # make the leak check false-positive. Force $PWD to contain the very
  # substrings a naive check would use ("tok", "akid"); the credential value
  # must still be absent while the path (with those substrings) is present.
  make_stub "$STUB" docker
  local workdir="$BATS_TEST_TMPDIR/tok-akid-secret"
  mkdir -p "$workdir"
  cd "$workdir"

  run env "PATH=$STUB:$PATH" LINODE_TOKEN=canary_linode_token \
    "$ROOT/bin/terraform" plan
  assert_success

  run cat "$STUB/docker.args"
  # The mount path — which contains "tok"/"akid" — IS in the args, proving the
  # collision surface a short sentinel would trip on.
  assert_output --partial "tok-akid-secret"
  # The credential is forwarded by name only; its value never leaks.
  assert_output --partial "--env LINODE_TOKEN"
  refute_output --partial "canary_linode_token"
}

@test "terraform plan does not forward credentials that are unset" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  # Clear any creds inherited from the test environment, then set just one.
  # The -u flags must precede the first NAME=VALUE, or env treats them as args.
  run env -u AWS_SECRET_ACCESS_KEY -u AWS_ENDPOINT_URL_S3 \
    -u AWS_REQUEST_CHECKSUM_CALCULATION -u AWS_RESPONSE_CHECKSUM_VALIDATION \
    -u LINODE_TOKEN \
    "PATH=$STUB:$PATH" AWS_ACCESS_KEY_ID=akid \
    "$ROOT/bin/terraform" plan
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "--env AWS_ACCESS_KEY_ID"
  # The Linode token wasn't set, so it must not be forwarded.
  refute_output --partial "--env LINODE_TOKEN"
}

@test "terraform validate stays credential-free even when creds are set" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  run env "PATH=$STUB:$PATH" \
    AWS_ACCESS_KEY_ID=akid AWS_SECRET_ACCESS_KEY=secret LINODE_TOKEN=tok \
    "$ROOT/bin/terraform" validate
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "hashicorp/terraform:1.15"
  # validate is run with dummy creds on purpose (rules/terraform.md), so the
  # wrapper must never leak real ones into it.
  refute_output --partial "--env AWS_ACCESS_KEY_ID"
  refute_output --partial "--env LINODE_TOKEN"
}

@test "terraform forwards credentials past a -chdir global flag" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  run env "PATH=$STUB:$PATH" LINODE_TOKEN=tok \
    "$ROOT/bin/terraform" -chdir=infra plan
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "--env LINODE_TOKEN"
}

@test "terraform keeps stdin open (-i) and adds no TTY without a terminal" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  # `run` captures stdout (not a tty), so the -t branch must stay off while
  # -i is unconditional. (The tty-present path is covered below via script.)
  run env "PATH=$STUB:$PATH" "$ROOT/bin/terraform" plan
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial " -i "
  refute_output --partial " -t "
}

@test "terraform adds a TTY (-t) when run under a terminal" {
  command -v script > /dev/null || skip "no script(1) to allocate a pty"
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  # script(1) gives the wrapper a pseudo-terminal on stdin+stdout so the -t
  # branch fires; the docker stub only records args, no daemon needed. A
  # sandboxed environment that can't allocate a pty leaves no args file --
  # skip there rather than fail.
  script -qec "env PATH=$STUB:$PATH $ROOT/bin/terraform plan" /dev/null \
    > /dev/null 2>&1 || true
  [[ -f "$STUB/docker.args" ]] || skip "pty allocation unavailable here"

  run cat "$STUB/docker.args"
  assert_output --partial " -t "
  assert_output --partial " -i "
}
