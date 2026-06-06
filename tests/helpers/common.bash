#!/usr/bin/env bash

# Shared helpers for the dotfiles bats suite. Loaded with `load helpers/common`
# from a test file in tests/.

#------------------------------------------------------------------------------
# Load the apt-installed bats helper libraries. bats_load_library resolves them
# from BATS_LIB_PATH; on Debian/Ubuntu the default (/usr/lib/bats) already
# holds bats-support / bats-assert / bats-file.

load_bats_libs() {
  # Make this repo's first-class helper lib (lib/bats) resolvable alongside the
  # system libs, so `bats tests/` works without relying on shell-startup having
  # exported BATS_LIB_PATH (e.g. in CI or a bare checkout).
  local libdir
  libdir="$(dotfiles_root)/lib/bats"
  export BATS_LIB_PATH="${libdir}:${BATS_LIB_PATH:-/usr/lib/bats}"

  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-toolbox
}

#------------------------------------------------------------------------------
# Absolute path to the repo root (tests/ sits one level below it).

dotfiles_root() {
  # Repo root = two levels up from this file (tests/helpers/common.bash), so
  # it is independent of how deep the calling test sits under tests/.
  cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
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
