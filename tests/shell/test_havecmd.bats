#!/usr/bin/env bats

# Tests for shell-startup's havecmd(). havecmd is a `command -v` wrapper that
# drops WSL's slow /mnt/c (Windows-interop) PATH entries for the duration of
# one lookup, then restores PATH, returning command -v's success/failure.
#
# havecmd lives inside the shell-startup orchestrator (not independently
# sourceable), so the tests extract just its definition from the file and eval
# it in isolation rather than running the whole orchestrator.

load ../helpers/common

setup() {
  load_bats_libs
  # havecmd isn't independently sourceable (it lives inside the shell-startup
  # orchestrator), so eval just its definition in isolation.
  eval "$(source_funcs "$(dotfiles_root)/shell-startup" havecmd)"
  setup_temp_dir
}

teardown() {
  cleanup_temp_dir
}

@test "havecmd succeeds for a command on PATH" {
  printf '#!/bin/sh\n' > "$TEST_TEMP_DIR/mytool"
  chmod +x "$TEST_TEMP_DIR/mytool"

  PATH="$TEST_TEMP_DIR:$PATH" run havecmd mytool
  assert_success
}

@test "havecmd fails for a command not on PATH" {
  run havecmd this-command-does-not-exist-xyz
  assert_failure
}

@test "havecmd finds a shell builtin regardless of PATH" {
  PATH="" run havecmd cd
  assert_success
}

@test "havecmd restores PATH after the lookup" {
  local before="/mnt/c/Windows:$TEST_TEMP_DIR:/usr/bin"
  PATH="$before"
  havecmd ls
  assert_equal "$PATH" "$before"
}

@test "havecmd ignores commands reachable only via /mnt/c" {
  # White-box: with PATH = only a /mnt/c dir plus an empty temp dir, a tool
  # planted in a (stripped) /mnt/c-pattern entry must not be found. We cannot
  # create a real /mnt/c here, so prove the filter on a real WSL host where a
  # /mnt/c-resolved command exists; skip elsewhere.
  local wincmd="" c
  for c in cmd.exe powershell.exe notepad.exe explorer.exe; do
    if command -v "$c" > /dev/null 2>&1 \
      && [[ $(command -v "$c") == /mnt/c/* ]]; then
      wincmd=$c
      break
    fi
  done

  [[ -n $wincmd ]] || skip "no /mnt/c-resolved command available (not WSL)"

  # command -v finds it (it is on PATH); havecmd must not (it strips /mnt/c).
  run command -v "$wincmd"
  assert_success
  run havecmd "$wincmd"
  assert_failure
}
