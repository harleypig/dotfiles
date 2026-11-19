#!/usr/bin/env bats

# Tests for bin/proj — print the path to cd into ($PROJECTS_DIR or
# $PROJECTS_DIR/<name>); for a missing name, offer a select menu to create it,
# go to $PROJECTS_DIR, or cancel. (It only prints a path; the proj() shell
# wrapper does the cd.) With -c/--claude it cds to the project and execs
# claude, adding each directory listed in the project's .proj.
#
# claude is always a stub on PATH. It writes $STUB/claude.log: the pwd, whether
# CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD is set, then one arg per line —
# so a missing log means claude was never launched.

# shellcheck disable=SC2016  # .proj lines and the claude stub body are
# written with their $VARs literal on purpose; proj or the stub expands them.

load ../helpers/common

# --separate-stderr needs bats 1.5.
bats_require_minimum_version 1.5.0

setup() {
  load_bats_libs
  PROJ="$(dotfiles_root)/bin/proj"
  export PROJECTS_DIR="$BATS_TEST_TMPDIR/projects"
  mkdir -p "$PROJECTS_DIR"

  STUB="$BATS_TEST_TMPDIR/stub"
  mkdir -p "$STUB"

  make_script_stub "$STUB" claude '{
  printf "pwd=%s\n" "$PWD"
  printf "env=%s\n" "${CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD:-unset}"
  for a in "$@"; do printf "arg=%s\n" "$a"; done
} > "${0%/*}/claude.log"
echo claude-ran'

  # bin/ too, so the proj() wrapper's `command proj` finds this checkout's.
  PATH="$STUB:$(dotfiles_root)/bin:$PATH"
  unset CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD
  LOG="$STUB/claude.log"
}

# Print the proj() wrapper out of 010-general so it can be eval'd without
# sourcing the rest of the file (bats.md "Testing non-independently-sourceable
# shell").
proj_wrapper() {
  sed -n '/^proj() {/,/^}$/p' "$(dotfiles_root)/config/shell-startup/010-general"
}

@test "no argument prints PROJECTS_DIR" {
  run "$PROJ"
  assert_success
  assert_output "$PROJECTS_DIR"
}

@test "an existing project prints its path" {
  mkdir -p "$PROJECTS_DIR/foo"
  run "$PROJ" foo
  assert_success
  assert_output "$PROJECTS_DIR/foo"
}

@test "-h prints usage and exits 0" {
  run "$PROJ" -h
  assert_success
  assert_output --partial 'Usage: proj'
}

@test "an unknown option exits 2" {
  run "$PROJ" --bogus
  assert_failure 2
  assert_output --partial 'Unknown option'
}

@test "extra arguments without -c warn, print the path and exit 0" {
  mkdir -p "$PROJECTS_DIR/foo"
  run --separate-stderr "$PROJ" foo bar baz
  assert_success
  assert_output "$PROJECTS_DIR/foo"
  [[ $stderr == *'ignoring extra arguments: bar baz'* ]]
  assert_file_not_exists "$LOG"
}

@test "unset PROJECTS_DIR errors" {
  run env -u PROJECTS_DIR "$PROJ"
  assert_failure 1
  assert_output --partial 'PROJECTS_DIR is not set'
}

@test "missing project: select 'create' makes and prints it" {
  run "$PROJ" newproj <<< '1'
  assert_success
  assert_output --partial "$PROJECTS_DIR/newproj"
  assert_dir_exists "$PROJECTS_DIR/newproj"
}

@test "missing project: select 'cancel' exits 1 without creating" {
  run "$PROJ" nope <<< '3'
  assert_failure 1
  run [ -d "$PROJECTS_DIR/nope" ]
  assert_failure
}

@test "-c without .proj runs plain claude in the project" {
  mkdir -p "$PROJECTS_DIR/foo"
  run "$PROJ" foo -c
  assert_success
  assert_output claude-ran
  run cat "$LOG"
  assert_output "pwd=$PROJECTS_DIR/foo
env=unset"
}

@test "-c with .proj adds each directory and sets the env var" {
  mkdir -p "$PROJECTS_DIR/foo/sub" "$PROJECTS_DIR/bar" "$PROJECTS_DIR/baz"
  mkdir -p "$PROJECTS_DIR/bar/inner"
  printf '%s\n' '$PROJECTS_DIR/bar' '' '${PROJECTS_DIR}/baz' 'sub' \
    > "$PROJECTS_DIR/foo/.proj"
  # An added repo's own .proj is never read.
  printf '%s\n' 'inner' > "$PROJECTS_DIR/bar/.proj"

  run "$PROJ" foo --claude
  assert_success
  run cat "$LOG"
  assert_output "pwd=$PROJECTS_DIR/foo
env=1
arg=--add-dir
arg=$PROJECTS_DIR/bar
arg=--add-dir
arg=$PROJECTS_DIR/baz
arg=--add-dir
arg=$PROJECTS_DIR/foo/sub"
}

@test "-c passes every later argument to claude, a later -c included" {
  mkdir -p "$PROJECTS_DIR/foo"
  run "$PROJ" foo -c -c --model 'two words'
  assert_success
  run cat "$LOG"
  assert_output "pwd=$PROJECTS_DIR/foo
env=unset
arg=-c
arg=--model
arg=two words"
}

@test "-c with an unset variable in .proj errors without launching" {
  mkdir -p "$PROJECTS_DIR/foo"
  printf '%s\n' '$PROJ_TEST_NOT_SET/x' > "$PROJECTS_DIR/foo/.proj"
  run "$PROJ" foo -c
  assert_failure 1
  assert_output --partial "variable 'PROJ_TEST_NOT_SET' is not set"
  assert_file_not_exists "$LOG"
}

@test "-c does not expand proj's own unexported variables" {
  mkdir -p "$PROJECTS_DIR/foo"
  printf '%s\n' '$target' > "$PROJECTS_DIR/foo/.proj"
  run "$PROJ" foo -c
  assert_failure 1
  assert_output --partial "variable 'target' is not set"
  assert_file_not_exists "$LOG"
}

@test "-c with a missing directory in .proj errors without launching" {
  mkdir -p "$PROJECTS_DIR/foo"
  printf '%s\n' '$PROJECTS_DIR/nowhere' > "$PROJECTS_DIR/foo/.proj"
  run "$PROJ" foo -c
  assert_failure 1
  assert_output --partial "no such directory: $PROJECTS_DIR/nowhere"
  assert_file_not_exists "$LOG"
}

@test "-c never executes \$(...) or backticks in .proj" {
  local pwned="$BATS_TEST_TMPDIR/pwned"
  local lit1="\$(touch $pwned)" lit2="\`touch $pwned\`"

  mkdir -p "$PROJECTS_DIR/foo/$lit1" "$PROJECTS_DIR/foo/$lit2"
  printf '%s\n' "$lit1" "$lit2" > "$PROJECTS_DIR/foo/.proj"

  run "$PROJ" foo -c
  assert_success
  assert_file_not_exists "$pwned"
  run cat "$LOG"
  assert_line "arg=$PROJECTS_DIR/foo/$lit1"
  assert_line "arg=$PROJECTS_DIR/foo/$lit2"
}

@test "-c on a missing project launches claude only after Create" {
  run "$PROJ" newproj -c <<< '1'
  assert_success
  assert_dir_exists "$PROJECTS_DIR/newproj"
  run cat "$LOG"
  assert_line "pwd=$PROJECTS_DIR/newproj"
}

@test "-c on a missing project: Go to prints PROJECTS_DIR, no launch" {
  run "$PROJ" newproj -c <<< '2'
  assert_success
  assert_output --partial "$PROJECTS_DIR"
  assert_file_not_exists "$LOG"
}

@test "-c on a missing project: Cancel exits 1, no launch" {
  run "$PROJ" newproj -c <<< '3'
  assert_failure 1
  assert_file_not_exists "$LOG"
  assert_dir_not_exists "$PROJECTS_DIR/newproj"
}

@test "wrapper: -c neither captures claude's output nor cds" {
  mkdir -p "$PROJECTS_DIR/foo"
  eval "$(proj_wrapper)"

  # Called directly, not through run, so a cd would reach this shell.
  cd "$BATS_TEST_TMPDIR"
  proj foo -c > out
  assert_equal "$PWD" "$BATS_TEST_TMPDIR"
  assert_file_contains out '^claude-ran$'
}

@test "wrapper: without -c it cds to the project" {
  mkdir -p "$PROJECTS_DIR/foo"
  eval "$(proj_wrapper)"

  cd "$BATS_TEST_TMPDIR"
  proj foo
  assert_equal "$PWD" "$PROJECTS_DIR/foo"
  assert_file_not_exists "$LOG"
}
