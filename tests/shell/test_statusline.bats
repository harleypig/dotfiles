#!/usr/bin/env bats

# Regression tests for config/claude/bin/statusline.sh.
#
# Guards the leading-empty-field bug (parts[0] was an empty mode label, so the
# line rendered as ' | (dotfiles: …)') and the context-% colour escalation.
# jq is real; ansi + git-status are stubbed (ansi echoes its args so colour
# choices are assertable).

load ../helpers/common

setup() {
  load_bats_libs
  command -v jq > /dev/null || skip "jq not installed"

  ROOT="$(dotfiles_root)"
  SL="$ROOT/config/claude/bin/statusline.sh"
  BASH_BIN="$(command -v bash)"
  STUB="$(make_stub_dir)"

  cat > "$STUB/ansi" << 'STUBEOF'
#!/usr/bin/env bash
printf '<%s>' "$*"
STUBEOF

  cat > "$STUB/git-status" << 'STUBEOF'
#!/usr/bin/env bash
printf 'REPO'
STUBEOF

  chmod +x "$STUB/ansi" "$STUB/git-status"

  JSON='{"model":{"display_name":"Opus 4.8"},"context_window":{"used_percentage":20},"cost":{"total_cost_usd":10.36},"version":"2.1.183"}'
}

teardown() {
  rm -rf "$STUB"
}

@test "output has no leading empty field / separator" {
  run env PATH="$STUB:$PATH" "$BASH_BIN" "$SL" <<< "$JSON"
  assert_success
  refute_output --regexp '^[[:space:]]*\|'
}

@test "all expected fields are present" {
  run env PATH="$STUB:$PATH" "$BASH_BIN" "$SL" <<< "$JSON"
  assert_success
  assert_output --partial 'REPO'
  assert_output --partial 'Opus 4.8'
  assert_output --partial 'Ctx: '
  assert_output --partial '20%'
  # shellcheck disable=SC2016  # literal '$' cost prefix, not a variable
  assert_output --partial '$10.36'
  assert_output --partial 'code v2.1.183'
}

@test "an empty git-status leaves no stray separator" {
  cat > "$STUB/git-status" << 'STUBEOF'
#!/usr/bin/env bash
STUBEOF
  chmod +x "$STUB/git-status"

  run env PATH="$STUB:$PATH" "$BASH_BIN" "$SL" <<< "$JSON"
  assert_success
  refute_output --regexp '^[[:space:]]*\|'
  refute_output --regexp '\|[[:space:]]+\|'
}

@test "high context (>=80) uses the alarm colour" {
  local json='{"model":{"display_name":"X"},"context_window":{"used_percentage":85},"cost":{"total_cost_usd":1},"version":"1"}'
  run env PATH="$STUB:$PATH" "$BASH_BIN" "$SL" <<< "$json"
  assert_success
  assert_output --partial '<bg red>'
}

@test "low context uses the calm cyan colour" {
  run env PATH="$STUB:$PATH" "$BASH_BIN" "$SL" <<< "$JSON"
  assert_success
  assert_output --partial '<fg cyan>'
}

@test "missing jq prints a graceful notice and exits 0" {
  run env PATH="$STUB" "$BASH_BIN" "$SL" <<< "$JSON"
  assert_success
  assert_output --partial 'jq not found'
}
