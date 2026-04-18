#!/usr/bin/env bash
# Claude Code statusline — reads JSON session data from stdin, outputs one line.
# Docs: https://code.claude.com/docs/en/statusline

command -v jq &>/dev/null || { printf 'claude | jq not found\n'; exit 0; }

data=$(cat)

model=$(    printf '%s' "$data" | jq -r '.model.display_name // "unknown"'               2>/dev/null || printf 'unknown')
ctx=$(      printf '%s' "$data" | jq -r '(.context_window.used_percentage // 0) | floor' 2>/dev/null || printf '0')
cost_raw=$( printf '%s' "$data" | jq -r '.cost.total_cost_usd // 0'                      2>/dev/null || printf '0')

# Ensure plain integer for arithmetic (jq may emit 45.0)
ctx=$(( ${ctx%%.*} + 0 ))
cost=$(printf '%.2f' "$cost_raw" 2>/dev/null || printf '?.??')

red=$'\033[31m'
yellow=$'\033[33m'
cyan=$'\033[36m'
reset=$'\033[0m'

if   (( ctx >= 75 )); then ctx_color=$red
elif (( ctx >= 50 )); then ctx_color=$yellow
else                       ctx_color=$cyan
fi

printf '%s | ctx %s%d%%%s | $%s\n' "$model" "$ctx_color" "$ctx" "$reset" "$cost"
