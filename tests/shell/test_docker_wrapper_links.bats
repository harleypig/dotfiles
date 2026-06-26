#!/usr/bin/env bats

# Tests for docker_wrapper's registry interface (--known-tools / --images)
# and the bin/docker_wrapper-links symlink maintainer. The maintainer is
# also a repo-structure guard: the "live symlinks match the registry" test
# fails CI if a registered tool loses its bin/<tool> symlink (or a stray
# one appears).

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"
}

# A throwaway bin/ holding a stub dispatcher (answers --known-tools with
# three fake tools) plus a copy of the real maintainer, for drift scenarios.
fake_bindir() {
  local d="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$d"

  cat > "$d/docker_wrapper" << 'EOF'
#!/usr/bin/env bash
[[ ${1-} == --known-tools ]] && { printf '%s\n' alpha bravo charlie; exit 0; }
exit 0
EOF
  chmod +x "$d/docker_wrapper"

  cp "$ROOT/bin/docker_wrapper-links" "$d/docker_wrapper-links"
  printf '%s' "$d"
}

# --- registry interface -----------------------------------------------------

@test "docker_wrapper --known-tools lists the registry, sorted and non-empty" {
  run "$ROOT/bin/docker_wrapper" --known-tools
  assert_success
  assert_line "shellcheck"
  assert_line "trivy"

  # output is sorted
  run bash -c '"$1" --known-tools | sort -c' _ "$ROOT/bin/docker_wrapper"
  assert_success
}

@test "docker_wrapper --images lists each known tool with its image" {
  run "$ROOT/bin/docker_wrapper" --images
  assert_success
  assert_output --partial "shellcheck"
  assert_output --partial "koalaman/shellcheck:stable"

  # the tool column is exactly the registry
  run bash -c 'diff <("$1" --known-tools) <("$1" --images | cut -d" " -f1)' \
    _ "$ROOT/bin/docker_wrapper"
  assert_success
}

@test "a tool symlink passes --known-tools through to the tool, not the registry" {
  STUB="$(make_stub_dir)"
  make_stub "$STUB" docker
  cd "$BATS_TEST_TMPDIR"
  printf '#!/usr/bin/env bash\n' > x.sh

  run env "PATH=$STUB:$PATH" "$ROOT/bin/shellcheck" --known-tools x.sh
  assert_success

  # --known-tools reached the container args; it was not intercepted.
  run cat "$STUB/docker.args"
  assert_output --partial "--known-tools"
  rm -rf "$STUB"
}

# --- the maintainer ---------------------------------------------------------

@test "the live bin/<tool> symlinks match docker_wrapper's registry" {
  run "$ROOT/bin/docker_wrapper-links"
  assert_success
  assert_output --partial "consistent"
}

@test "docker_wrapper-links reports missing symlinks and fails" {
  d="$(fake_bindir)"
  ln -s docker_wrapper "$d/alpha"

  run "$d/docker_wrapper-links"
  assert_failure 1
  assert_output --partial "missing"
  assert_output --partial "bravo"
  assert_output --partial "charlie"
}

@test "docker_wrapper-links reports a stray symlink and fails" {
  d="$(fake_bindir)"
  ln -s docker_wrapper "$d/alpha"
  ln -s docker_wrapper "$d/bravo"
  ln -s docker_wrapper "$d/charlie"
  ln -s docker_wrapper "$d/zulu"

  run "$d/docker_wrapper-links"
  assert_failure 1
  assert_output --partial "stray"
  assert_output --partial "zulu"
}

@test "docker_wrapper-links --fix creates the missing symlinks" {
  d="$(fake_bindir)"
  ln -s docker_wrapper "$d/alpha"

  run "$d/docker_wrapper-links" --fix
  assert_output --partial "created bin/bravo"
  assert_output --partial "created bin/charlie"

  # created with the right target (not byte-compared)
  assert_equal "$(readlink "$d/bravo")" docker_wrapper
  assert_equal "$(readlink "$d/charlie")" docker_wrapper

  # a clean re-check now passes
  run "$d/docker_wrapper-links"
  assert_success
}

@test "docker_wrapper-links -h prints usage and exits 0" {
  run "$ROOT/bin/docker_wrapper-links" -h
  assert_success
  assert_output --partial "Usage: docker_wrapper-links"
}

@test "docker_wrapper-links rejects an unknown option (exit 2)" {
  run "$ROOT/bin/docker_wrapper-links" --bogus
  assert_failure 2
  assert_output --partial "unknown option"
}
