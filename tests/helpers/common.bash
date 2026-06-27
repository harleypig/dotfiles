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

#------------------------------------------------------------------------------
# Write an executable bash stub <dir>/<name> with <body> as its body — for a
# stand-in command whose custom behaviour or output make_stub (which only
# records args and exits a code) can't express:
#   make_script_stub "$dir" ansi 'echo -n "[ansi:$*]"'   # echo args back
#   make_script_stub "$dir" awk  'printf "%s\n" "$VAL"'   # emit a value
# <body> is written verbatim, so single-quote it to keep $vars literal — they
# expand when the stub runs, not when it is created (shellcheck SC2016 on the
# call is expected for that case; disable it with a reason there).

make_script_stub() {
  local dir=$1 name=$2 body=$3

  printf '#!/usr/bin/env bash\n%s\n' "$body" > "$dir/$name"
  chmod +x "$dir/$name"
}

#------------------------------------------------------------------------------
# Create a throwaway git repo at <dir> with a pinned test identity and one
# empty initial commit. The git-* test files all need a real repo to run
# against; this centralizes the init + identity + first-commit boilerplate they
# would otherwise each repeat.
#   make_test_repo "$BATS_TEST_TMPDIR/sample"

make_test_repo() {
  local dir=$1

  git init -q "$dir"
  git -C "$dir" config user.email t@example.com
  git -C "$dir" config user.name test
  git -C "$dir" commit -q --allow-empty -m init
}

#------------------------------------------------------------------------------
# Print the definitions of the named shell functions found in <file>, so a test
# can exercise functions from a file that is not sourceable on its own (a
# shell-startup module, or a lib guarded by an interactive check):
#   eval "$(source_funcs config/shell-startup/git gtoplevel gtl)"
# Matches both `name() {` and `function name() {` header styles. (A test that
# also needs a non-function definition from the file, or that must strip a
# guard out of the middle, extracts that part itself — see test_tmux /
# test_bash_prompt.)

source_funcs() {
  local file=$1
  shift

  local names
  names=$(
    IFS='|'
    printf '%s' "$*"
  )

  awk -v names="$names" '
    $0 ~ "^(function[[:space:]]+)?(" names ")\\(\\)" { capture = 1 }
    capture                                          { print }
    capture && /^\}/                                 { capture = 0 }
  ' "$file"
}

#------------------------------------------------------------------------------
# Docker integration harness. Build (cached) the dotfiles test image and echo
# its tag; skip the calling test when docker is unavailable or the build
# fails. The image is the runtime only — tests mount the repo read-only at
# /dotfiles (see tests/docker/).

dotfiles_harness_image() {
  command -v docker > /dev/null 2>&1 || skip "docker not available"

  local tag=dotfiles-test:latest
  docker build -q -t "$tag" "$(dotfiles_root)/tests/docker" > /dev/null 2>&1 \
    || skip "could not build the dotfiles test image"

  printf '%s' "$tag"
}

#------------------------------------------------------------------------------
# Run a command in a throwaway container with the repo mounted read-only at
# /dotfiles, inside a login shell that has the dotfiles deployed (the image's
# default entrypoint). Sets $output/$status via bats `run`.
#   dotfiles_login "$IMAGE" 'echo "$DOTFILES"'              # non-interactive
#   dotfiles_login_interactive "$IMAGE" 'echo "${PS1:+x}"' # interactive

dotfiles_login() {
  local image=$1 cmd=$2
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" "$image" -lc "$cmd"
}

dotfiles_login_interactive() {
  local image=$1 cmd=$2
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" "$image" -lic "$cmd"
}
