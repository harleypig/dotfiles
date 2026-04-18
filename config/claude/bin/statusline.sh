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

vars+=('mode')
jq_filter['mode']='.vim.mode'
sl_label['mode']=

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
sl_label['version']='code '

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
# Set colors

declare red yellow cyan reset

if command -v ansi &> /dev/null; then
  red=$(ansi fg red)
  yellow=$(ansi fg yellow)
  cyan=$(ansi fg cyan)
  reset=$(ansi off)
fi

if ((ctx >= 75)); then
  ctx_color=$red
elif ((ctx >= 50)); then
  ctx_color=$yellow
else
  ctx_color=$cyan
fi

#------------------------------------------------------------------------------
# Build output parts and join with ' | '

declare -a parts

parts+=("${sl_label['mode']}")
parts+=("$(git-status)")
parts+=("${sl_label['model']}${model}")
parts+=("${sl_label['ctx']}${ctx_color}${ctx}%${reset}")
parts+=("${sl_label['cost']}${cost}")
parts+=("${sl_label['version']}${version}")

printf '%s\n' "$(join_array ' | ' 'parts')"
