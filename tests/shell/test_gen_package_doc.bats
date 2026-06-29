#!/usr/bin/env bats

# Tests for bin/gen-package-doc, the generator that renders docs/packages.md
# from config/packages/manifest.json. Most tests drive a throwaway fixture
# manifest (PKG_MANIFEST/PKG_DOC overrides) to assert rendering and the
# arg/error paths; the final test is a repo-structure guard that fails CI if
# the committed docs/packages.md drifts from the real manifest.

load ../helpers/common

setup() {
  load_bats_libs

  GEN="$(dotfiles_root)/bin/gen-package-doc"

  # A small fixture covering both install-ordering cases: a docker-viable
  # package (docker leads) and a non-viable one (pipx leads, plus a note).
  FIXDIR="$BATS_TEST_TMPDIR/pkg"
  mkdir -p "$FIXDIR"
  export PKG_MANIFEST="$FIXDIR/manifest.json"
  export PKG_DOC="$FIXDIR/packages.md"

  cat > "$PKG_MANIFEST" << 'EOF'
{
  "priority_note": "Test priority note.",
  "docker_viable_meaning": "Test viability meaning.",
  "packages": [
    {
      "name": "alpha",
      "apps": ["a"],
      "summary": "Alpha tool",
      "category": "linter",
      "language": "node",
      "docker": { "viable": true, "image": "org/alpha", "note": "official" },
      "install": [
        { "method": "docker", "cmd": "docker pull org/alpha" },
        { "method": "pipx", "cmd": "pipx install alpha" }
      ]
    },
    {
      "name": "bravo",
      "apps": ["b", "b2"],
      "summary": "Bravo tool",
      "category": "formatter",
      "note": "project-local",
      "docker": { "viable": false, "image": null, "note": "no dedicated image" },
      "install": [
        { "method": "pipx", "cmd": "pipx install bravo" },
        { "method": "uv", "cmd": "uv tool install bravo" }
      ]
    }
  ],
  "excluded": [
    { "name": "zeta", "reason": "managed elsewhere" }
  ]
}
EOF
}

@test "no arg: writes the doc with packages and excluded sections" {
  run "$GEN"
  [ "$status" -eq 0 ]
  [ -f "$PKG_DOC" ]

  run cat "$PKG_DOC"
  [[ "$output" == *"# Standard Package Set"* ]]
  [[ "$output" == *"#### alpha — Alpha tool"* ]]
  [[ "$output" == *"#### bravo — Bravo tool"* ]]
  [[ "$output" == *"## Excluded (managed elsewhere)"* ]]
  [[ "$output" == *"**zeta**"* ]]
  [[ "$output" == *"2 packages, 1 excluded"* ]]
}

@test "docker-viable package lists docker as the first install step" {
  "$GEN"

  run grep -A8 "#### alpha" "$PKG_DOC"
  [[ "$output" == *"Language:** node"* ]]
  [[ "$output" == *"Docker:** yes — \`org/alpha\`"* ]]
  [[ "$output" == *"1. \`docker pull org/alpha\`"* ]]
  [[ "$output" == *"2. \`pipx install alpha\`"* ]]
}

@test "non-viable package leads with pipx and shows its note" {
  "$GEN"

  run grep -A8 "#### bravo" "$PKG_DOC"
  [[ "$output" == *"Docker:** no"* ]]
  [[ "$output" != *"Language:**"* ]]  # absent language field omits the line
  [[ "$output" == *"Note:** project-local"* ]]
  [[ "$output" == *"1. \`pipx install bravo\`"* ]]
}

@test "--check succeeds when the doc is in sync" {
  "$GEN"

  run "$GEN" --check
  [ "$status" -eq 0 ]
  [[ "$output" == *"in sync"* ]]
}

@test "--check fails when the doc has drifted" {
  "$GEN"
  printf 'DRIFT\n' >> "$PKG_DOC"

  run "$GEN" --check
  [ "$status" -eq 1 ]
  [[ "$output" == *"OUT OF SYNC"* ]]
}

@test "--check errors when the doc does not exist yet" {
  run "$GEN" --check
  [ "$status" -ne 0 ]
  [[ "$output" == *"doc not found"* ]]
}

@test "--help prints usage and exits 0" {
  run "$GEN" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"gen-package-doc - render"* ]]
}

@test "unknown argument exits 2" {
  run "$GEN" --bogus
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown argument"* ]]
}

@test "invalid JSON manifest fails fast" {
  printf 'not json\n' > "$PKG_MANIFEST"

  run "$GEN"
  [ "$status" -ne 0 ]
  [[ "$output" == *"not valid JSON"* ]]
}

@test "missing manifest fails fast" {
  rm -f "$PKG_MANIFEST"

  run "$GEN"
  [ "$status" -ne 0 ]
  [[ "$output" == *"manifest not found"* ]]
}

@test "guard: committed docs/packages.md is in sync with the manifest" {
  # No PKG_MANIFEST/PKG_DOC override: run against the real repo files.
  unset PKG_MANIFEST PKG_DOC

  run "$GEN" --check
  [ "$status" -eq 0 ]
}
