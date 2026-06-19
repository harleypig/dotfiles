#!/usr/bin/env bash
# Claude Code statusline — reads JSON session data from stdin, outputs one line.
# Docs: https://code.claude.com/docs/en/statusline

# XXX: Does tput support OSC 8 escape codes for clickable links? If so,
# consider modifying bin/ansi to support that for more global support.

command -v jq &> /dev/null || {
  printf 'claude | jq not found\n'
  exit 0
}

#------------------------------------------------------------------------------
# Copied from config/shell-startup/bash_prompt. Takes a delimiter string and
# an array name (by reference), prints elements joined by the delimiter.

join_array() {
  (($# != 2)) && {
    printf 'join_array: must pass delimiter and array name\n' >&2
    return 1
  }

  local delim="$1"
  local -n _array_="$2"

  first="${_array_[0]}"
  rest=("${_array_[@]:1}")

  printf '%s' "$first"
  printf '%s' "${rest[@]/#/$delim}"
}

#------------------------------------------------------------------------------
# Field definitions — add/remove fields here; vars order sets display order.
# jq expressions receive the full session JSON object.

declare -a vars
declare -A jq_filter sl_label

vars+=('model')
jq_filter['model']='.model.display_name // "unknown"'
sl_label['model']=''

vars+=('ctx')
jq_filter['ctx']='(.context_window.used_percentage // 0) | floor | tostring'
sl_label['ctx']='Ctx: '

vars+=('cost')
jq_filter['cost']='.cost.total_cost_usd // 0 | tostring'
sl_label['cost']='$'

vars+=('version')
jq_filter['version']='.version'
sl_label['version']='code v'

#------------------------------------------------------------------------------
# Gather data — single jq call via @tsv, one read
#
# @tsv formats the jq array as tab-separated values so that a single
# IFS=$'\t' read can split all fields into their named variables in one pass.

data=$(cat)

jq_parts=()
for v in "${vars[@]}"; do
  jq_parts+=("(${jq_filter[$v]})")
done

IFS=$'\t' read -r "${vars[@]}" < <(
  printf '%s' "$data" | jq -r "[ $(
    IFS=','
    printf '%s' "${jq_parts[*]}"
  ) ] | @tsv" 2> /dev/null
) || true

#------------------------------------------------------------------------------
# Post-process typed fields

ctx=$((${ctx%%.*} + 0))
cost=$(printf '%.2f' "$cost" 2> /dev/null || printf '?.??')

#------------------------------------------------------------------------------
# Set colors. Context % escalates so a near-full window is hard to miss —
# compaction is manual, so the percentage is the only warning: calm cyan, then
# bright yellow past 60%, then an alarm block (bright text on a red background)
# once it crosses 80%.

declare cyan bright_yellow alarm reset

if command -v ansi &> /dev/null; then
  cyan=$(ansi fg cyan)
  bright_yellow=$(ansi fg bright_yellow)
  alarm="$(ansi bg red)$(ansi fg bright_white)"
  reset=$(ansi off)
fi

if ((ctx >= 80)); then
  ctx_color=$alarm
elif ((ctx >= 60)); then
  ctx_color=$bright_yellow
else
  ctx_color=$cyan
fi

#------------------------------------------------------------------------------
# Build output parts and join with ' | '. Empty fields are dropped so a blank
# value (e.g. git-status outside a repo) leaves no stray ' | '.

declare -a parts

add_part() { [[ -n $1 ]] && parts+=("$1"); }

add_part "$(git-status)"
add_part "${sl_label['model']}${model}"
add_part "${sl_label['ctx']}${ctx_color}${ctx}%${reset}"
add_part "${sl_label['cost']}${cost}"
add_part "${sl_label['version']}${version}"

printf '%s\n' "$(join_array ' | ' 'parts')"
