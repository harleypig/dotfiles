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
# Field definitions — add/remove fields here; the build section below sets
# display order. Every jq expression MUST yield a string (use `// ""` /
# `tostring`) so the join in Gather never sees a null. Fields may be empty
# (effort is absent on models without it); empties are handled downstream.

declare -a vars
declare -A jq_filter sl_label

# Vim mode (NORMAL/INSERT/VISUAL/…), present only with vim editor mode +
# hideVimModeIndicator set, so we render it ourselves instead of the built-in.
vars+=('vim')
jq_filter['vim']='.vim.mode // ""'
sl_label['vim']=''

vars+=('model')
jq_filter['model']='.model.display_name // "unknown"'
sl_label['model']=''

vars+=('effort')
jq_filter['effort']='.effort.level // ""'
sl_label['effort']=''

vars+=('ctx')
jq_filter['ctx']='(.context_window.used_percentage // 0) | floor | tostring'
sl_label['ctx']='Ctx:'

# Subscriber rate-limit usage (5-hour + 7-day caps), absent on non-subscriber
# sessions — empty string when missing so the segment is simply skipped.
vars+=('r5h')
jq_filter['r5h']='(.rate_limits.five_hour.used_percentage // "") | if . == "" then "" else (floor | tostring) end'
sl_label['r5h']=''

vars+=('r7d')
jq_filter['r7d']='(.rate_limits.seven_day.used_percentage // "") | if . == "" then "" else (floor | tostring) end'
sl_label['r7d']=''

vars+=('cost')
jq_filter['cost']='.cost.total_cost_usd // 0 | tostring'
sl_label['cost']='$'

vars+=('version')
jq_filter['version']='.version // ""'
sl_label['version']='code v'

#------------------------------------------------------------------------------
# Gather data — single jq call, one read.
#
# Fields are joined on the ASCII unit separator (US, 0x1f) rather than @tsv:
# a tab is an IFS whitespace char, so `read` would collapse a leading/empty
# field and shift every value left (an absent effort/version would scramble
# the line). US is non-whitespace, so `read` preserves empty fields in place.

data=$(cat)

jq_parts=()
for v in "${vars[@]}"; do
  jq_parts+=("(${jq_filter[$v]})")
done

IFS=$'\x1f' read -r "${vars[@]}" < <(
  printf '%s' "$data" | jq -r "[ $(
    IFS=','
    printf '%s' "${jq_parts[*]}"
  ) ] | join(\"\u001f\")" 2> /dev/null
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

declare cyan bright_yellow alarm vim_normal reset

if command -v ansi &> /dev/null; then
  cyan=$(ansi fg cyan)
  bright_yellow=$(ansi fg bright_yellow)
  alarm="$(ansi bg red)$(ansi fg bright_white)"
  vim_normal="$(ansi bg red)$(ansi fg bright_yellow)"
  reset=$(ansi off)
fi

# NORMAL mode stands out (bright yellow on red — command keystrokes are live);
# INSERT and the rest use the terminal's standard color.
case $vim in
  NORMAL) vim_color=$vim_normal ;;
  *) vim_color='' ;;
esac

# Percentage fields (context %, the rate-limit usage caps) share one ramp:
# calm cyan < 60, bright yellow 60–79, alarm block >= 80. An empty value
# (a missing rate limit) ranks as 0 — its color is unused anyway.
pct_color() {
  local v=$((${1:-0} + 0))

  if ((v >= 80)); then
    printf '%s' "$alarm"
  elif ((v >= 60)); then
    printf '%s' "$bright_yellow"
  else
    printf '%s' "$cyan"
  fi
}

ctx_color=$(pct_color "$ctx")
r5h_color=$(pct_color "$r5h")
r7d_color=$(pct_color "$r7d")

# Effort reuses the same calm/warn/alarm colors, ranked by how expensive
# the reasoning level is (higher effort burns more, like a fuller window).
case $effort in
  max | xhigh) effort_color=$alarm ;;
  high) effort_color=$bright_yellow ;;
  *) effort_color=$cyan ;;
esac

#------------------------------------------------------------------------------
# Build output parts and join with ' | '. Empty fields are dropped so a blank
# value (e.g. git-status outside a repo) leaves no stray ' | '.

declare -a parts

add_part() { [[ -n $1 ]] && parts+=("$1"); }

# Vim mode leads the line (we render it; the built-in indicator is hidden).
[[ -n $vim ]] && add_part "${vim_color}${vim}${reset}"
# --plain: no wrapping parens / leading space; the ' | ' join handles spacing.
add_part "$(git-status --plain)"
# Effort rides with the model (no ' | ' between them), colored by level and
# bracketed — only when the model reports one.
model_part="${sl_label['model']}${model}"
[[ -n $effort ]] && model_part+=" ${effort_color}[$effort]${reset}"
add_part "$model_part"
# Context % and the rate-limit usage caps (5h / 7-day) ride together as one
# segment — no ' | ' between them — each colored by the shared pct ramp.
# Percentages are right-aligned in 3 columns so the values line up.
ctx_part="${sl_label['ctx']}${ctx_color}$(printf '%3d' "$ctx")%${reset}"
[[ -n $r5h ]] && ctx_part+=" 5h:${r5h_color}$(printf '%3d' "$r5h")%${reset}"
[[ -n $r7d ]] && ctx_part+=" 7d:${r7d_color}$(printf '%3d' "$r7d")%${reset}"
add_part "$ctx_part"
add_part "${sl_label['cost']}${cost}"
add_part "${sl_label['version']}${version}"

printf '%s\n' "$(join_array ' | ' 'parts')"
