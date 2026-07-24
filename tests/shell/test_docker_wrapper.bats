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
  # code-tools has no ENTRYPOINT, so the tool is named after the image.
  assert_output --partial "ghcr.io/harleypig/code-tools"
  assert_output --partial "shfmt -d script.sh"
}

# Version-sync: after ADR-0006 shfmt/shellcheck run from the code-tools image
# (the wrapper AND the pre-commit hooks reference the SAME image, so they can't
# drift), and the tool VERSION lives in ONE place — the code-tools Dockerfile
# FROM tag. The CI meta suite still installs a pinned binary, so its
# SHFMT_VER/SC_VER must stay in step with the Dockerfile.
@test "the shfmt version matches across the code-tools Dockerfile and the CI meta gate" {
  local df ci
  df=$(grep -oE 'FROM mvdan/shfmt:v[0-9.]+' \
    "$ROOT/config/docker/code-tools/Dockerfile" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
  ci=$(grep -oE 'SHFMT_VER=v[0-9]+\.[0-9]+\.[0-9]+' \
    "$ROOT/.github/workflows/tests.yml" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')

  [ -n "$df" ] && [ -n "$ci" ]
  assert_equal "$df" "$ci"
}

@test "the shellcheck version matches across the code-tools Dockerfile and the CI meta gate" {
  local df ci
  df=$(grep -oE 'FROM koalaman/shellcheck:v[0-9.]+' \
    "$ROOT/config/docker/code-tools/Dockerfile" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')
  ci=$(grep -oE 'SC_VER=v[0-9]+\.[0-9]+\.[0-9]+' \
    "$ROOT/.github/workflows/tests.yml" | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')

  [ -n "$df" ] && [ -n "$ci" ]
  assert_equal "$df" "$ci"
}

@test "every code-tools consumer references one identical image ref" {
  # The consolidation invariant (ADR-0006): the docker_wrapper image[] entries
  # and the pre-commit hook entries all name the SAME code-tools image, so a
  # digest bump can't leave one behind. Collect every code-tools ref across the
  # three files; there must be exactly one distinct value.
  local -a refs
  mapfile -t refs < <(
    grep -hoE 'ghcr.io/harleypig/code-tools:[^" ]+' \
      "$ROOT/bin/docker_wrapper" \
      "$ROOT/.pre-commit-config.yaml" \
      "$ROOT/.pre-commit-config-fix.yaml" | sort -u
  )
  assert_equal "${#refs[@]}" 1
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
  # code-tools has no ENTRYPOINT, so the tool is named after the image.
  assert_output --partial "ghcr.io/harleypig/code-tools"
  assert_output --partial "markdownlint doc.md"
}

@test "ansible-lint dispatch assembles the expected docker run command" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf -- '---\n- hosts: all\n' > playbook.yml

  run env "PATH=$STUB:$PATH" "$ROOT/bin/ansible-lint" playbook.yml
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "run"
  assert_output --partial "--workdir /mnt"
  assert_output --partial "--env HOME=/tmp"
  # No ENTRYPOINT in the image, so the binary is named explicitly after it.
  assert_output --partial "ghcr.io/harleypig/ansible-lint:26.6.0 ansible-lint"
  assert_output --partial "playbook.yml"
  # ansible-lint operates on paths, not stdin — no --interactive.
  refute_output --partial "--interactive"
}

@test "ruff dispatch assembles the expected docker run command" {
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf 'import os\n' > mod.py

  run env "PATH=$STUB:$PATH" "$ROOT/bin/ruff" check mod.py
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "run"
  assert_output --partial "--workdir /mnt"
  # Cache is kept out of the mounted repo.
  assert_output --partial "--env RUFF_CACHE_DIR=/tmp/ruff-cache"
  # The combined code-tools image has no ENTRYPOINT, so the tool is named after
  # it (like ansible-lint / perltidy).
  assert_output --partial "ghcr.io/harleypig/code-tools"
  assert_output --partial "ruff check mod.py"
}

@test "hadolint dispatch names the tool on the combined code-tools image" {
  # Re-pointed (ADR-0005 Phase 2) off the standalone hadolint image onto
  # code-tools; the image has no ENTRYPOINT, so the binary is named after it.
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf 'FROM alpine:3.19\n' > Dockerfile

  run env "PATH=$STUB:$PATH" "$ROOT/bin/hadolint" Dockerfile
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "--workdir /mnt"
  assert_output --partial "ghcr.io/harleypig/code-tools"
  assert_output --partial "hadolint Dockerfile"
}

@test "prettier dispatch names the tool on the combined code-tools image" {
  # Re-pointed (ADR-0005 Phase 2) off the unpinned prettier:latest onto
  # code-tools; no ENTRYPOINT, so the binary is named after it.
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf 'const x = 1\n' > f.js

  run env "PATH=$STUB:$PATH" "$ROOT/bin/prettier" --check f.js
  assert_success

  run cat "$STUB/docker.args"
  assert_output --partial "--workdir /mnt"
  assert_output --partial "ghcr.io/harleypig/code-tools"
  assert_output --partial "prettier --check f.js"
}

# --- stdin-safety (the piped-stdin gap) ---------------------------------------

@test "stdin-accepting wrappers keep stdin open (--interactive) when piped" {
  # Each tool has a real stdin/`-` filter mode, so the wrapper must forward
  # stdin (via dw_stdin_if_piped). `run` gives a non-tty stdin, so the -t 0
  # guard is false and --interactive must be added. Tools without a stdin mode
  # (trivy, dive, tflint, terraform-docs) deliberately omit it — see below.
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf '#!/usr/bin/env bash\necho hi\n' > f.sh

  local t
  for t in shellcheck shfmt yamllint prettier hadolint markdownlint \
    perltidy perlcritic packer ruff; do
    rm -f "$STUB/docker.args"
    run env "PATH=$STUB:$PATH" "$ROOT/bin/$t" f.sh
    assert_success
    run cat "$STUB/docker.args"
    assert_output --partial "--interactive"
  done
}

@test "a non-stdin wrapper does not add --interactive when piped" {
  # tflint operates on a directory, not stdin, so it must NOT forward stdin.
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"

  run env "PATH=$STUB:$PATH" "$ROOT/bin/tflint" --version
  assert_success

  run cat "$STUB/docker.args"
  refute_output --partial "--interactive"
}

@test "a stdin wrapper omits --interactive when stdin is a terminal" {
  command -v script > /dev/null || skip "no script(1) to allocate a pty"
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf '#!/usr/bin/env bash\necho hi\n' > f.sh

  # script(1) gives the wrapper a pty on stdin, so the -t 0 guard is true and
  # dw_stdin_if_piped is a no-op — an interactive run must not be turned
  # non-interactive. Skip where a pty can't be allocated (sandbox/CI).
  script -qec "env PATH=$STUB:$PATH $ROOT/bin/shellcheck f.sh" /dev/null \
    > /dev/null 2>&1 || true
  [[ -f "$STUB/docker.args" ]] || skip "pty allocation unavailable here"

  run cat "$STUB/docker.args"
  refute_output --partial "--interactive"
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
