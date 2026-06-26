#!/usr/bin/env bats

# Tests for bin/check-dotvim: the presence/link check and the --setup
# clone+link of the companion dotvim repo. Runs against an isolated HOME and
# dotvim location, so it never touches the real ones.

load ../helpers/common

setup() {
  load_bats_libs
  SCRIPT="$(dotfiles_root)/bin/check-dotvim"

  export HOME="$BATS_TEST_TMPDIR/home"
  export XDG_DOTVIM="$BATS_TEST_TMPDIR/dotvim"
  mkdir -p "$HOME"
  unset PROJECTS_DIR
}

present_dotvim() {
  mkdir -p "$XDG_DOTVIM/.vim"
  touch "$XDG_DOTVIM/.vimrc"
}

# --- check mode -------------------------------------------------------------

@test "check warns and fails when dotvim is absent" {
  run "$SCRIPT"
  assert_failure 1
  assert_output --partial "not present"
}

@test "check creates the ~/.vim and ~/.vimrc symlinks when dotvim is present" {
  present_dotvim
  run "$SCRIPT"
  assert_success
  assert_equal "$(readlink -f "$HOME/.vim")" "$(readlink -f "$XDG_DOTVIM/.vim")"
  assert_equal "$(readlink -f "$HOME/.vimrc")" "$(readlink -f "$XDG_DOTVIM/.vimrc")"
}

@test "check is idempotent and quiet on a clean second run" {
  present_dotvim
  run "$SCRIPT"
  assert_success
  run "$SCRIPT"
  assert_success
  refute_output
}

@test "check warns on a mismatched link" {
  present_dotvim
  ln -s /somewhere/else "$HOME/.vimrc"
  run "$SCRIPT"
  assert_failure 1
  assert_output --partial "linked elsewhere"
}

@test "check refuses to clobber a real (non-symlink) ~/.vimrc" {
  present_dotvim
  printf 'real file\n' > "$HOME/.vimrc"
  run "$SCRIPT"
  assert_failure 1
  assert_output --partial "not a symlink"
  run cat "$HOME/.vimrc"
  assert_output "real file"
}

@test "the login opt-out (~/.nocheckdotvim) short-circuits the check" {
  touch "$HOME/.nocheckdotvim"
  run "$SCRIPT"
  assert_success
  refute_output
}

# --- --setup ----------------------------------------------------------------

@test "--setup clones dotvim with submodules when missing, then links" {
  STUB="$(make_stub_dir)"
  cat > "$STUB/git" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$(dirname "$0")/git.args"
if [[ ${1-} == clone ]]; then
  args=("$@")
  dest=${args[-1]}
  mkdir -p "$dest/.vim"
  touch "$dest/.vimrc"
fi
exit 0
EOF
  chmod +x "$STUB/git"

  run env "PATH=$STUB:$PATH" "$SCRIPT" --setup
  assert_success

  run cat "$STUB/git.args"
  assert_output --partial "clone --recurse-submodules"
  assert_output --partial "$XDG_DOTVIM"

  assert_equal "$(readlink -f "$HOME/.vim")" "$(readlink -f "$XDG_DOTVIM/.vim")"
  rm -rf "$STUB"
}

@test "--setup ignores the opt-out and links an already-present dotvim" {
  present_dotvim
  touch "$HOME/.nocheckdotvim"
  run "$SCRIPT" --setup
  assert_success
  assert_equal "$(readlink -f "$HOME/.vimrc")" "$(readlink -f "$XDG_DOTVIM/.vimrc")"
}

# --- usage ------------------------------------------------------------------

@test "check-dotvim -h prints usage and exits 0" {
  run "$SCRIPT" -h
  assert_success
  assert_output --partial "Usage: check-dotvim"
}

@test "check-dotvim rejects an unknown option (exit 2)" {
  run "$SCRIPT" --bogus
  assert_failure 2
  assert_output --partial "unknown option"
}
