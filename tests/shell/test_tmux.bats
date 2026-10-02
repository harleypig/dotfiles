#!/usr/bin/env bats

# Tests for config/shell-startup/tmux's tmux_winidx_circled() — it maps the
# current tmux window index to a circled-digit glyph, falling back to "(N)"
# once the index passes 20 (past the glyph table). The index comes from
# `tmux display-message`, so the tests stub `tmux` to feed a chosen index and
# assert the boundary + per-index glyph selection.
#
# The function is extracted from the module and eval'd in isolation (the module
# also wires aliases/`ta`); this is the same in-isolation approach as
# test_havecmd. The `circled_digits` glyph table lives *inside* the function
# (function-local, so it doesn't pollute module scope), so extracting the
# function body carries the table with it.

load ../helpers/common

TMUX_MODULE_REL="config/shell-startup/tmux"

# Pull the tmux_winidx_circled function (table included) out of the module.
extract_winidx() {
  sed -n '/^tmux_winidx_circled()/,/^}/p' "$(dotfiles_root)/$TMUX_MODULE_REL"
}

setup() {
  load_bats_libs

  # Stub tmux so `tmux display-message -p '#I'` yields the index under test.
  # shellcheck disable=SC2329  # invoked indirectly by the eval'd function
  tmux() { printf '%s\n' "$STUB_WINIDX"; }

  eval "$(extract_winidx)"
}

@test "tmux_winidx_circled wraps an index above 20 in parentheses" {
  STUB_WINIDX=21 run tmux_winidx_circled
  assert_success
  assert_output '(21)'
}

@test "tmux_winidx_circled wraps a large index in parentheses" {
  STUB_WINIDX=99 run tmux_winidx_circled
  assert_success
  assert_output '(99)'
}

@test "tmux_winidx_circled uses a glyph (not parens) at the boundary of 20" {
  STUB_WINIDX=20 run tmux_winidx_circled
  assert_success
  refute_output ''
  refute_output --partial '('
}

@test "tmux_winidx_circled selects a distinct glyph per window index" {
  STUB_WINIDX=5 run tmux_winidx_circled
  local g5=$output
  STUB_WINIDX=6 run tmux_winidx_circled
  local g6=$output

  [ -n "$g5" ]
  [ "$g5" != "$g6" ]
}

# Env-pollution hygiene guards (source-level): the interactive helpers must not
# be pushed into child processes, and no module-scope scratch var should leak.

@test "the tmux module does not export helpers into child processes" {
  run grep -nE '^[[:space:]]*export -f' "$(dotfiles_root)/$TMUX_MODULE_REL"
  assert_failure
}

@test "circled_digits is function-local, not a module-scope global" {
  # A module-scope assignment would be a line beginning `circled_digits=`;
  # inside the function it is preceded by `local`.
  run grep -nE '^circled_digits=' "$(dotfiles_root)/$TMUX_MODULE_REL"
  assert_failure
}

# ta(): attach a tmux session, choosing among several with bin/pickone. The
# function is extracted from the module and run in a child bash against a
# `tmux` and a `pickone` stubbed on PATH; each stub logs its arguments, so a
# test reads the `tmux -2 a -t <name>` line to see which session attached.
# The picker runs only with a terminal on stdin, which bats does not give a
# test, so the TTY cases run the driver under `script` to get a pty.

# Pull the indented ta function out of the module's else-branch.
extract_ta() {
  sed -n '/^  ta() {/,/^  }/p' "$(dotfiles_root)/$TMUX_MODULE_REL"
}

# Stub tmux and pickone on PATH and write a driver that defines and runs ta.
# STUB_SESSIONS (newline-separated) is what `tmux list-sessions` reports and
# what `tmux has-session` finds; STUB_PICK is pickone's answer, and an empty
# one makes pickone fail the way it does when input ends.
setup_ta() {
  STUB=$BATS_TEST_TMPDIR/stub
  mkdir -p "$STUB"

  cat > "$STUB/tmux" << 'STUBEOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${0%/*}/tmux.args"

case $1 in
  list-sessions)
    [[ -n $STUB_SESSIONS ]] || exit 1
    printf '%s\n' "$STUB_SESSIONS"
    ;;

  has-session) grep -qxF -- "$3" <<< "$STUB_SESSIONS" ;;
esac
STUBEOF

  cat > "$STUB/pickone" << 'STUBEOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${0%/*}/pickone.args"
[[ -n $STUB_PICK ]] || exit 1
printf '%s\n' "$STUB_PICK"
STUBEOF

  chmod +x "$STUB/tmux" "$STUB/pickone"

  DRIVER=$BATS_TEST_TMPDIR/driver

  # The driver sets TMUX only from FAKE_TMUX, so a run from inside a real tmux
  # does not leak its own TMUX into the not-in-tmux cases.
  {
    cat << 'DRIVEREOF'
unset TMUX
[[ -n $FAKE_TMUX ]] && TMUX=$FAKE_TMUX
DRIVEREOF
    extract_ta
    echo 'ta'
  } > "$DRIVER"

  export PATH="$STUB:$PATH" USER=me STUB_SESSIONS STUB_PICK FAKE_TMUX
}

# Run ta with no terminal on stdin.
run_ta() { run bash "$DRIVER" < /dev/null; }

# Run ta with a pseudo-terminal on stdin, as a user at a shell has one.
run_ta_tty() { run script -qec "bash $DRIVER" /dev/null < /dev/null; }

# Print the session name(s) ta asked tmux to attach.
attached() { sed -n 's/^-2 a -t //p' "$STUB/tmux.args"; }

@test "ta with no sessions starts and attaches the \$USER session" {
  setup_ta
  STUB_SESSIONS='' run_ta_tty

  run grep -xF 'new-session -d -s me' "$STUB/tmux.args"
  assert_success

  run attached
  assert_output 'me'
  assert_file_not_exists "$STUB/pickone.args"
}

@test "ta with one session attaches it without prompting" {
  setup_ta
  STUB_SESSIONS='work' run_ta_tty

  run attached
  assert_output 'work'
  assert_file_not_exists "$STUB/pickone.args"

  run grep -F 'new-session' "$STUB/tmux.args"
  assert_failure
}

@test "ta with several sessions attaches the one picked" {
  setup_ta
  STUB_SESSIONS=$'me\nwork\nplay' STUB_PICK=play run_ta_tty

  run attached
  assert_output 'play'

  run cat "$STUB/pickone.args"
  assert_output --partial 'me work play'
}

@test "ta offers \$USER as the picker's default when it is a session" {
  setup_ta
  STUB_SESSIONS=$'work\nme' STUB_PICK=me run_ta_tty

  run cat "$STUB/pickone.args"
  assert_output --partial '-d me'
}

@test "ta attaches nothing when the picker is cancelled" {
  setup_ta
  STUB_SESSIONS=$'me\nwork' STUB_PICK='' run_ta_tty
  assert_failure

  run attached
  assert_output ''
}

@test "ta with several sessions and no terminal attaches \$USER, no prompt" {
  setup_ta
  STUB_SESSIONS=$'work\nme' run_ta

  run attached
  assert_output 'me'
  assert_file_not_exists "$STUB/pickone.args"
}

@test "ta inside tmux keeps the \$USER attach and does not prompt" {
  setup_ta
  STUB_SESSIONS=$'work\nplay' FAKE_TMUX=/tmp/sock,1,0 run_ta_tty

  run attached
  assert_output 'me'
  assert_file_not_exists "$STUB/pickone.args"
}
