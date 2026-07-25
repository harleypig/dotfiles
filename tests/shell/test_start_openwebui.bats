#!/usr/bin/env bats

# Tests for bin/start-openwebui — the host-gated, startup-safe launcher. The
# host is faked with a `hostname` PATH-stub, and `docker` is stubbed, so no
# daemon (and no real beaker host) is required.

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"
  STUB="$(make_stub_dir)"
}

teardown() {
  rm -rf "$STUB"
}

# Fake `hostname` to report $1 (start-openwebui and docker_wrapper both call
# `hostname -s`).
fake_hostname() {
  cat > "$STUB/hostname" << EOF
#!/usr/bin/env bash
printf '%s\n' "$1"
EOF
  chmod +x "$STUB/hostname"
}

@test "off the target host it quietly no-ops (exit 0) and starts nothing" {
  fake_hostname sweetums
  make_stub "$STUB" docker

  run env "PATH=$STUB:$PATH" "$ROOT/bin/start-openwebui"
  assert_success
  assert_output --partial "nothing to do"

  # It must not have delegated / touched docker.
  [ ! -f "$STUB/docker.args" ]
}

@test "on the target host it delegates to the openwebui launcher" {
  # hostname -> beaker so both this launcher's gate and docker_wrapper's
  # dw_require_host pass; docker stubbed so no real containers run.
  fake_hostname beaker
  make_stub "$STUB" docker

  run env "PATH=$STUB:$PATH" "$ROOT/bin/start-openwebui"
  assert_success

  # It reached docker_wrapper's openwebui(), which runs the open-webui
  # container detached.
  run cat "$STUB/docker.args"
  assert_output --partial "open-webui"
}
