#!/usr/bin/env bats

# Conformance guard: every config/claude/rules/*.md must declare its load tier
# in frontmatter — either a `paths:` key (path-scoped, on-demand) or a
# `# No paths — <why>` comment (deliberately always-on). This stops a new rule
# silently joining the per-turn always-on tier "by omission" (no paths and no
# documenting comment), which an audit otherwise has to catch by hand. See
# config/claude/SETUP-AUDIT.md, config/claude/rule-TEMPLATE.md, and the
# decision in config/claude/audit/decisions-log.md (2026-06-19).
#
# This is the rules counterpart to test_skill_frontmatter.bats. Same posture:
# a self-hosted check, no external linter just to lint our own files.

load ../helpers/common

setup() {
  load_bats_libs

  RULES="$(dotfiles_root)/config/claude/rules"
}

#------------------------------------------------------------------------------
# Print the first `---`-delimited frontmatter block of a file (the lines
# between the opening and closing `---`). Prints nothing when the file does not
# open with a frontmatter block.

frontmatter_block() {
  awk '
    NR == 1 && $0 != "---" { exit }
    /^---$/ { c++; next }
    c == 1 { print }
    c >= 2 { exit }
  ' "$1"
}

@test "every rule declares its load tier (paths: or a documented # No paths)" {
  local bad=()

  for f in "$RULES"/*.md; do
    [[ -f $f ]] || continue

    local fm
    fm="$(frontmatter_block "$f")"

    if [[ -z $fm ]]; then
      bad+=("$(basename "$f"): no frontmatter block — add 'paths:' or a '# No paths — <why>' comment")
      continue
    fi

    if ! grep -qE '^paths:' <<<"$fm" &&
      ! grep -qiE '^#[[:space:]]*no paths' <<<"$fm"; then
      bad+=("$(basename "$f"): frontmatter has neither 'paths:' nor a '# No paths' comment")
    fi
  done

  ((${#bad[@]} == 0)) || fail "$(printf '%s\n' "${bad[@]}")"
}
