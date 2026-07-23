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
  assert_output --partial "mvdan/shfmt:v3.13.1"
  assert_output --partial "-d script.sh"
}

@test "the shfmt wrapper image is version-pinned in sync with the gate" {
  # Regression for the version-drift bug: bin/shfmt used a floating
  # mvdan/shfmt:v3 tag while the pre-commit hooks and the CI meta suite pin
  # shfmt v3.13.1, so a local `bin/shfmt` check could silently diverge from
  # the gate on a future shfmt release. All four sources must name the same
  # version. (SC/shfmt SYNC note lives in bin/docker_wrapper + tests.yml.)
  local dw pc pcf ci
  dw=$(grep -oE 'image\[shfmt\]="mvdan/shfmt:v[0-9.]+"' "$ROOT/bin/docker_wrapper" \
    | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
  pc=$(awk '/scop\/pre-commit-shfmt/{f=1} f&&/rev:/{print;exit}' \
    "$ROOT/.pre-commit-config.yaml" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
  pcf=$(awk '/scop\/pre-commit-shfmt/{f=1} f&&/rev:/{print;exit}' \
    "$ROOT/.pre-commit-config-fix.yaml" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
  ci=$(grep -oE 'SHFMT_VER=v[0-9]+\.[0-9]+\.[0-9]+' \
    "$ROOT/.github/workflows/tests.yml" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')

  # Every source must resolve to a version, and they must all agree.
  [ -n "$dw" ] && [ -n "$pc" ] && [ -n "$pcf" ] && [ -n "$ci" ]
  assert_equal "$dw" "$pc"
  assert_equal "$dw" "$pcf"
  assert_equal "$dw" "$ci"
}

@test "the shellcheck wrapper image is version-pinned in sync with the gate" {
  # Same version-drift guard as shfmt above: bin/shellcheck used a floating
  # koalaman/shellcheck:stable tag while the pre-commit hook and the CI meta
  # suite pin shellcheck v0.11.0. shellcheck is check-only, so it lives in
  # .pre-commit-config.yaml only (not -fix.yaml) — three sources, not four.
  local dw pc ci
  dw=$(grep -oE 'image\[shellcheck\]="koalaman/shellcheck:v[0-9.]+"' \
    "$ROOT/bin/docker_wrapper" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
  pc=$(awk '/koalaman\/shellcheck-precommit/{f=1} f&&/rev:/{print;exit}' \
    "$ROOT/.pre-commit-config.yaml" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
  ci=$(grep -oE 'SC_VER=v[0-9]+\.[0-9]+\.[0-9]+' \
    "$ROOT/.github/workflows/tests.yml" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')

  [ -n "$dw" ] && [ -n "$pc" ] && [ -n "$ci" ]
  assert_equal "$dw" "$pc"
  assert_equal "$dw" "$ci"
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

@test "terraform forwards TF_CLI_CONFIG_FILE for every subcommand, incl. validate" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  # validate does NOT forward cloud credentials (credential-free), so it is the
  # case that proves TF_CLI_CONFIG_FILE is forwarded regardless of subcommand.
  # Forwarded by name; a repo points it at, e.g., a credential helper or a
  # provider_installation (filesystem_mirror / network_mirror) block.
  run env "PATH=$STUB:$PATH" \
    TF_CLI_CONFIG_FILE=/mnt/some/provider.tfrc AWS_ACCESS_KEY_ID=akid \
    "$ROOT/bin/terraform" validate
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "--env TF_CLI_CONFIG_FILE"
  # ...while staying credential-free (creds are still gated to state subcommands).
  refute_output --partial "--env AWS_ACCESS_KEY_ID"
}

@test "terraform does not forward TF_CLI_CONFIG_FILE when it is unset" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  run env -u TF_CLI_CONFIG_FILE "PATH=$STUB:$PATH" "$ROOT/bin/terraform" validate
  assert_success

  run cat "$STUB/docker.args"
  refute_output --partial "TF_CLI_CONFIG_FILE"
}

# Leading -e/--env NAME wrapper flags forward named host vars into the container
# (by name, never the value) and are stripped from the tool's own argv.

@test "-e/--env forwards named host vars by name and strips the flags from argv" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  run env "PATH=$STUB:$PATH" \
    MXROUTE_API_KEY=canary_mxroute_key MXROUTE_SERVER=heracles.example \
    "$ROOT/bin/terraform" -e MXROUTE_API_KEY --env MXROUTE_SERVER -chdir=infra plan
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "--env MXROUTE_API_KEY"
  assert_output --partial "--env MXROUTE_SERVER"
  # Forwarded by name only — the secret value never reaches the command line.
  refute_output --partial "canary_mxroute_key"
  # The tool's own argv is preserved (the -e/--env flags were consumed, not
  # passed through to terraform).
  assert_output --partial "-chdir=infra plan"
}

@test "-e skips a host var that is unset" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  run env -u NOPE_VAR "PATH=$STUB:$PATH" "$ROOT/bin/terraform" -e NOPE_VAR plan
  assert_success

  run cat "$STUB/docker.args"
  refute_output --partial "--env NOPE_VAR"
}

@test "-e/--env works for any pwd-mounted tool, not just terraform" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf '# Title\n' > doc.md

  run env "PATH=$STUB:$PATH" MY_TOKEN=canary_tok \
    "$ROOT/bin/markdownlint" -e MY_TOKEN doc.md
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "--env MY_TOKEN"
  assert_output --partial "doc.md"
  refute_output --partial "canary_tok"
}

@test "shellcheck's own -e (exclude) is NOT stolen by the wrapper" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf '#!/usr/bin/env bash\ntrue\n' > script.sh

  run env "PATH=$STUB:$PATH" "$ROOT/bin/shellcheck" -e SC1090 script.sh
  assert_success

  run cat "$STUB/docker.args"
  # -e SC1090 passes through to shellcheck (its --exclude), NOT forwarded as env.
  assert_output --partial "-e SC1090"
  assert_output --partial "script.sh"
  refute_output --partial "--env SC1090"
}

@test "-e without a NAME is a usage error" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  run env "PATH=$STUB:$PATH" "$ROOT/bin/terraform" -e
  assert_failure 2
  assert_output --partial "requires an ENVVAR name"
}
