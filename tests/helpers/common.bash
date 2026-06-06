#!/usr/bin/env bash

# Shared helpers for the dotfiles bats suite. Loaded with `load helpers/common`
# from a test file in tests/.

#------------------------------------------------------------------------------
# Load the apt-installed bats helper libraries. bats_load_library resolves them
# from BATS_LIB_PATH; on Debian/Ubuntu the default (/usr/lib/bats) already
# holds bats-support / bats-assert / bats-file.

load_bats_libs() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file
}

#------------------------------------------------------------------------------
# Absolute path to the repo root (tests/ sits one level below it).

dotfiles_root() {
  cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd
}

#------------------------------------------------------------------------------
# Make a throwaway stub of an external command (e.g. docker, npx) that records
# each invocation's arguments to <dir>/<name>.args and exits <rc>. Put <dir> on
# PATH ahead of the real command to capture how a script would have called it,
# without actually running it.
#   stub=$(make_stub_dir); make_stub "$stub" docker
#   run env "PATH=$stub:$PATH" some-script ...
#   run cat "$stub/docker.args"

make_stub_dir() { mktemp -d; }

make_stub() {
  local dir=$1 name=$2 rc=${3:-0}

  cat > "$dir/$name" << EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >> "$dir/${name}.args"
exit $rc
EOF

  chmod +x "$dir/$name"
}
