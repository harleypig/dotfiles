#!/usr/bin/env bats

# Tests for bin/tmux_window_name — names a tmux window after the repo the
# Claude Code in it works in, and prints an orange busy/idle style for the
# window list.
#
# Most tests stub tmux: the script's one display-message + list-panes call
# answers for one window (STUB_WINDOW) from fixtures shaped like real tmux
# output, and set-option calls are logged. Claude sessions are fixture files
# in a throwaway CLAUDE_CONFIG_DIR. Their pids must be real processes inside
# the pane's tree, so each "Claude" is a background sleep whose parent, this
# test's shell, plays the pane's shell.
#
# The last tests run a real, throwaway tmux server instead (the
# test_tmux_conf.bats harness), since what tmux itself emits differs between
# versions in ways a stub cannot show.

load ../helpers/common

setup() {
  load_bats_libs

  TWN="$(dotfiles_root)/bin/tmux_window_name"
  CONF="$(dotfiles_root)/config/tmux/tmux.conf"
  REAL_TMUX=$(command -v tmux || true)
  REAL_SERVER=

  STUB="$BATS_TEST_TMPDIR/stub"
  mkdir -p "$STUB"

  # shellcheck disable=SC2016  # expanded when the stub runs
  make_script_stub "$STUB" tmux '
case $1 in
  display-message)
    [[ $4 == "$STUB_WINDOW" ]] || exit 1
    cat "$STUB_WINDOW_OPTS" "$STUB_PANES"
    ;;
  set-option) printf "%s\n" "$*" >> "$STUB_LOG" ;;
esac'

  export REAL_JQ
  REAL_JQ=$(command -v jq)
  # shellcheck disable=SC2016  # expanded when the stub runs
  make_script_stub "$STUB" jq \
    'echo ran >> "$STUB_JQ_LOG"; exec "$REAL_JQ" "$@"'

  export PATH="$STUB:$PATH"
  export STUB_WINDOW=@7
  export STUB_PANES="$BATS_TEST_TMPDIR/panes"
  export STUB_WINDOW_OPTS="$BATS_TEST_TMPDIR/window"
  export STUB_JQ_LOG="$BATS_TEST_TMPDIR/jq.log"
  export STUB_LOG="$BATS_TEST_TMPDIR/tmux.log"
  export CLAUDE_CONFIG_DIR="$BATS_TEST_TMPDIR/claude"

  mkdir -p "$CLAUDE_CONFIG_DIR/sessions"
  : > "$STUB_PANES"
  window_opts 1 ''

  REPO="$BATS_TEST_TMPDIR/myrepo"
  make_test_repo "$REPO"

  SHELL_PID=$BASHPID
  CLAUDE_PIDS=()
}

teardown() {
  local pid

  for pid in "${CLAUDE_PIDS[@]}"; do
    kill "$pid" 2> /dev/null || true
  done

  if [[ -n $REAL_SERVER ]]; then
    "$REAL_TMUX" -L twntest kill-server 2> /dev/null || true
  fi
}

# Start a stand-in Claude under this shell; its pid lands in CLAUDE_PID.
# Not called in a command substitution: the sleep's parent must be this
# shell, not a subshell that exits at once.
start_claude() {
  sleep 300 &
  CLAUDE_PID=$!
  CLAUDE_PIDS+=("$CLAUDE_PID")
}

# window_opts <automatic-rename> <@claude_name>: the display-message line,
# which real tmux prints as "1 " when the name is unset.
window_opts() {
  printf '%s %s\n' "$1" "$2" > "$STUB_WINDOW_OPTS"
}

# pane <id> <active> <pid> <command> <path>, one list-panes line.
pane() {
  printf '%s %s %s %s %s\n' "$1" "$2" "$3" "$4" "$5" >> "$STUB_PANES"
}

# session <pid> <cwd> <pane> [status] [procStart]
session() {
  printf '{"pid":%s,"cwd":"%s","tmux":"main:%s.%s","status":"%s"%s}\n' \
    "$1" "$2" "$STUB_WINDOW" "$3" "${4-busy}" \
    "${5:+,\"procStart\":\"$5\"}" \
    > "$CLAUDE_CONFIG_DIR/sessions/$1.json"
}

# Print field 22 of /proc/<pid>/stat, the process start time.
proc_start() {
  local stat
  local -a fields

  read -r stat < "/proc/$1/stat"
  read -r -a fields <<< "${stat##*) }"
  printf '%s' "${fields[19]}"
}

# Start a throwaway tmux server and point the script's `tmux` at it. The
# socket sits under the test's tmpdir, so nothing outlives the test.
real_server() {
  [[ -n $REAL_TMUX ]] || skip "tmux not installed"

  # A Unix socket path is capped near 104 bytes; tmux appends about 20.
  ((${#BATS_TEST_TMPDIR} < 80)) \
    || skip "BATS_TEST_TMPDIR too long for a tmux socket"

  export TMUX_TMPDIR=$BATS_TEST_TMPDIR
  unset TMUX

  make_script_stub "$STUB" tmux "exec '$REAL_TMUX' -L twntest \"\$@\""

  tmux -f /dev/null new-session -d -x 80 -y 24 -c "$BATS_TEST_TMPDIR"
  REAL_SERVER=1
  WIN=$(tmux display-message -p '#{window_id}')
}

@test "no argument is a usage error" {
  run "$TWN"
  assert_failure 2
  assert_output --partial 'Usage:'
}

@test "an argument that is not a window id is a usage error" {
  run "$TWN" 7
  assert_failure 2
  assert_output --partial 'Usage:'
}

@test "a window tmux does not know fails" {
  run "$TWN" @99
  assert_failure 1
  assert_output --partial 'no such window: @99'
}

@test "a window without Claude gets no style and no option" {
  pane %1 1 "$SHELL_PID" bash "$REPO"

  run "$TWN" @7
  assert_success
  assert_output ''
  assert_file_not_exists "$STUB_LOG"
}

@test "a window Claude has left has its name cleared and re-evaluated" {
  window_opts 1 myrepo
  pane %1 1 "$SHELL_PID" bash "$REPO"

  run "$TWN" @7
  assert_success
  assert_output ''
  assert_file_contains "$STUB_LOG" 'set-option -wqu -t @7 @claude_name ;'
  assert_file_contains "$STUB_LOG" 'automatic-rename on'
}

@test "a busy Claude in a main checkout names the window after the repo" {
  start_claude
  pane %1 1 "$SHELL_PID" claude "$REPO"
  session "$CLAUDE_PID" "$REPO" %1 busy

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour172]'
  assert_file_contains "$STUB_LOG" \
    'set-option -wq -t @7 @claude_name myrepo ;'
}

@test "a waiting Claude in a linked worktree is repo[worktree], idle" {
  git -C "$REPO" worktree add -q "$BATS_TEST_TMPDIR/wt-feature"
  start_claude
  pane %1 1 "$SHELL_PID" claude "$BATS_TEST_TMPDIR/wt-feature/sub"
  session "$CLAUDE_PID" "$BATS_TEST_TMPDIR/wt-feature" %1 waiting

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour214]'
  assert_file_contains "$STUB_LOG" '@claude_name myrepo\[wt-feature\] ;'
}

@test "a subdirectory of a main checkout still names the repo" {
  mkdir "$REPO/sub"
  start_claude
  pane %1 1 "$SHELL_PID" claude "$REPO/sub"
  session "$CLAUDE_PID" "$REPO/sub" %1

  run "$TWN" @7
  assert_success
  assert_file_contains "$STUB_LOG" '@claude_name myrepo ;'
}

@test "outside git the window is named after the directory" {
  mkdir "$BATS_TEST_TMPDIR/plain dir"
  start_claude
  pane %1 1 "$SHELL_PID" claude /
  session "$CLAUDE_PID" "$BATS_TEST_TMPDIR/plain dir" %1

  run "$TWN" @7
  assert_success
  assert_file_contains "$STUB_LOG" '@claude_name plain dir ;'
}

@test "a session file whose pid has exited is ignored" {
  sleep 0 &
  local gone=$!
  wait "$gone"
  pane %1 1 "$SHELL_PID" bash "$REPO"
  session "$gone" "$REPO" %1

  run "$TWN" @7
  assert_success
  assert_output ''
  assert_file_not_exists "$STUB_LOG"
}

@test "a live pid outside the pane's process tree is ignored" {
  start_claude
  local elsewhere=$CLAUDE_PID
  start_claude
  pane %1 1 "$elsewhere" bash "$REPO"
  session "$CLAUDE_PID" "$REPO" %1

  run "$TWN" @7
  assert_success
  assert_output ''
}

@test "a session file for a pane in another window never reaches jq" {
  start_claude
  pane %1 1 "$SHELL_PID" bash "$REPO"
  session "$CLAUDE_PID" "$REPO" %12

  run "$TWN" @7
  assert_success
  assert_output ''
  assert_file_not_exists "$STUB_JQ_LOG"
}

@test "a session file with no status is shown as busy" {
  start_claude
  pane %1 1 "$SHELL_PID" claude "$REPO"
  printf '{"pid":%s,"cwd":"%s","tmux":"main:@7.%%1"}' "$CLAUDE_PID" "$REPO" \
    > "$CLAUDE_CONFIG_DIR/sessions/$CLAUDE_PID.json"

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour172]'
  assert_file_exists "$STUB_JQ_LOG"
}

@test "a session whose procStart matches its pid is used" {
  [[ -d /proc ]] || skip "no /proc"
  start_claude
  pane %1 1 "$SHELL_PID" bash "$REPO"
  session "$CLAUDE_PID" "$REPO" %1 waiting "$(proc_start "$CLAUDE_PID")"

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour214]'
}

@test "a session whose procStart differs, a reused pid, is ignored" {
  [[ -d /proc ]] || skip "no /proc"
  start_claude
  pane %1 1 "$SHELL_PID" bash "$REPO"
  session "$CLAUDE_PID" "$REPO" %1 waiting 1

  run "$TWN" @7
  assert_success
  assert_output ''
}

@test "a pane path with spaces is read whole" {
  mkdir "$BATS_TEST_TMPDIR/plain dir"
  pane %1 1 "$SHELL_PID" claude "$BATS_TEST_TMPDIR/plain dir"

  run "$TWN" @7
  assert_success
  assert_file_contains "$STUB_LOG" '@claude_name plain dir ;'
}

@test "a malformed session file is skipped and a good one still counts" {
  start_claude
  printf '{"pid": ' > "$CLAUDE_CONFIG_DIR/sessions/1.json"
  printf '[]' > "$CLAUDE_CONFIG_DIR/sessions/2.json"
  pane %1 1 "$SHELL_PID" claude "$REPO"
  session "$CLAUDE_PID" "$REPO" %1 waiting

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour214]'
  assert_file_contains "$STUB_LOG" '@claude_name myrepo ;'
}

@test "with no session file a pane running claude is used, as busy" {
  mkdir "$BATS_TEST_TMPDIR/elsewhere"
  pane %1 0 "$SHELL_PID" bash "$BATS_TEST_TMPDIR/elsewhere"
  pane %2 1 "$SHELL_PID" claude "$REPO"

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour172]'
  assert_file_contains "$STUB_LOG" '@claude_name myrepo ;'
}

@test "the active Claude pane wins over an earlier one" {
  mkdir "$BATS_TEST_TMPDIR/first"
  pane %1 0 "$SHELL_PID" claude "$BATS_TEST_TMPDIR/first"
  pane %2 1 "$SHELL_PID" claude "$REPO"

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour172]'
  assert_file_contains "$STUB_LOG" '@claude_name myrepo ;'
}

@test "with the active pane not Claude, the first Claude pane is used" {
  mkdir "$BATS_TEST_TMPDIR/second"
  pane %1 0 "$SHELL_PID" claude "$REPO"
  pane %2 0 "$SHELL_PID" claude "$BATS_TEST_TMPDIR/second"
  pane %3 1 "$SHELL_PID" bash /

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour172]'
  assert_file_contains "$STUB_LOG" '@claude_name myrepo ;'
}

@test "an unchanged name sets nothing" {
  window_opts 1 myrepo
  pane %1 1 "$SHELL_PID" claude "$REPO"

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour172]'
  assert_file_not_exists "$STUB_LOG"
}

@test "a manually named window gets the option but not automatic-rename" {
  window_opts 0 ''
  pane %1 1 "$SHELL_PID" claude "$REPO"

  run "$TWN" @7
  assert_success
  assert_output '#[fg=colour172]'
  assert_file_contains "$STUB_LOG" '@claude_name myrepo$'
  assert_file_not_contains "$STUB_LOG" 'automatic-rename'
}

@test "real tmux: a stale @claude_name on a window without Claude is unset" {
  real_server
  tmux set-option -w -t "$WIN" @claude_name stale

  run "$TWN" "$WIN"
  assert_success
  assert_output ''

  run tmux show-options -wqv -t "$WIN" @claude_name
  assert_output ''
}

@test "real tmux: automatic-rename-format prefers @claude_name when set" {
  real_server
  tmux source-file "$CONF"

  local cmd
  cmd=$(tmux display-message -p -t "$WIN" '#{pane_current_command}')

  run tmux display-message -p -t "$WIN" '#{E:automatic-rename-format}'
  assert_output "$cmd"

  tmux set-option -w -t "$WIN" @claude_name 'my repo'
  run tmux display-message -p -t "$WIN" '#{E:automatic-rename-format}'
  assert_output 'my repo'

  # A plain #{?@claude_name,...} would read "0" as false.
  tmux set-option -w -t "$WIN" @claude_name 0
  run tmux display-message -p -t "$WIN" '#{E:automatic-rename-format}'
  assert_output '0'
}

@test "real tmux: a window running claude is named after its repo" {
  real_server

  # bash under the name claude, so its process name and argv[0] both read
  # "claude": tmux 3.6 reports argv[0], where a #!/bin/sh script named
  # claude shows as "sh". Not sleep: a multi-call coreutils (uutils) reads
  # argv[0] and refuses "claude". Separate arguments, so tmux execs it
  # directly: one string goes through default-shell, and where that falls
  # back to /bin/sh (dash) the pane reads "sh".
  mkdir "$BATS_TEST_TMPDIR/bin"
  ln -s "$(command -v bash)" "$BATS_TEST_TMPDIR/bin/claude"

  local win cmd tries
  win=$(tmux new-window -d -P -F '#{window_id}' -c "$REPO" \
    "$BATS_TEST_TMPDIR/bin/claude" -c 'while :; do sleep 1; done')

  for ((tries = 0; tries < 20; tries++)); do
    cmd=$(tmux display-message -p -t "$win" '#{pane_current_command}')
    [[ $cmd == claude ]] && break
    sleep 0.1
  done

  run "$TWN" "$win"
  assert_success
  assert_output '#[fg=colour172]'

  run tmux show-options -wqv -t "$win" @claude_name
  assert_output 'myrepo'
}
