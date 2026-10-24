#!/usr/bin/env bats

# Tests for bin/s3cmd — runs the next s3cmd on PATH, and when that one is a
# Python script with a Windows-path #! line (uv's install on Windows) runs it
# with that interpreter, with any directory holding MSYS's libmagic dropped
# from PATH.
#
# Every s3cmd, interpreter and cygpath here is a stub in a throwaway dir, so
# the tests run the same on Linux and Git Bash.

load ../helpers/common

bats_require_minimum_version 1.5.0

setup() {
  load_bats_libs
  wrapper="$(dotfiles_root)/bin/s3cmd"
  stub="$(make_stub_dir)"
  real="$(make_stub_dir)"
}

teardown() {
  rm -rf "$stub" "$real"
}

@test "execs the next s3cmd on PATH with the arguments" {
  make_stub "$real" s3cmd
  run env "PATH=$(dotfiles_root)/bin:$real:$PATH" "$wrapper" ls s3://bucket
  assert_success
  assert_equal "$(cat "$real/s3cmd.args")" 'ls s3://bucket'
}

@test "runs a Windows-#! s3cmd with its interpreter, without MSYS libmagic on PATH" {
  local magic
  magic="$(make_stub_dir)"
  touch "$magic/msys-magic-1.dll"

  # The "interpreter" reports its arguments and whether $magic is on PATH.
  # Its #! is absolute: the PATH it runs under has MSYS's /usr/bin removed
  # (that holds msys-magic-1.dll too), so `env bash` could find WSL's bash.
  # shellcheck disable=SC2016 # $* and $PATH expand when the stub runs
  printf '#!/bin/bash\n%s\n' \
    'echo "args: $*"; case ":$PATH:" in *":'"$magic"':"*) echo magic-on-path ;; *) echo magic-off-path ;; esac' \
    > "$stub/python"
  chmod +x "$stub/python"
  # shellcheck disable=SC2016 # expands when the stub runs
  make_script_stub "$stub" cygpath "echo '$stub/python'"
  printf '#!C:\\Users\\u\\s3cmd\\Scripts\\python.exe\r\nprint("x")\n' > "$real/s3cmd"
  chmod +x "$real/s3cmd"

  run env "PATH=$stub:$magic:$(dotfiles_root)/bin:$real:$PATH" "$wrapper" --version
  assert_success
  assert_line "args: $real/s3cmd --version"
  assert_line magic-off-path
  rm -rf "$magic"
}

@test "fails with 127 when no other s3cmd is on PATH" {
  run -127 env "PATH=$(dotfiles_root)/bin:/usr/bin:/bin" "$wrapper" --version
  assert_output --partial 'no s3cmd on PATH besides this wrapper'
}
