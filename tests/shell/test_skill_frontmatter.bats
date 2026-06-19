#!/usr/bin/env bats

# Conformance guard: every config/claude/skills/*/SKILL.md must satisfy the
# Agent Skills open standard (agentskills.io) hard constraints for its required
# frontmatter, so a newly added or renamed skill can't silently drift out of
# spec. See config/claude/EXTENDING.md (Skill > Format) and the decision in
# config/claude/audit/decisions-log.md (2026-06-19).
#
# Scope: the REQUIRED fields only — `name` (matches the directory; 1-64 chars;
# lowercase letters/digits/hyphens; no leading/trailing or consecutive hyphen)
# and `description` (present; <= 1024 chars). The optional standard fields
# (license/compatibility/metadata/allowed-tools) are not mandated.
#
# ICEBOX (2026-06-19, keyword-dense: skills-ref validator, external Apache-2.0,
# agentskills validation tool): the standard ships a reference validator,
# `skills-ref validate <dir>`. We deliberately use this self-hosted check
# instead — same posture as the rest of the repo (no external scanner/tool
# dependency just to lint our own files). Revisit only if our own check proves
# insufficient (e.g. we start relying on optional/experimental fields the
# upstream validator understands and ours does not).

load ../helpers/common

setup() {
  load_bats_libs

  SKILLS="$(dotfiles_root)/config/claude/skills"
}

#------------------------------------------------------------------------------
# Print the value of a top-level frontmatter key (first match) from a SKILL.md:
# scan only the first `---`-delimited block, strip the `key: ` prefix.

frontmatter_value() {
  awk -v k="^$2:" '
    /^---$/ { c++; next }
    c == 1 && $0 ~ k { sub(/^[^:]*: */, ""); print; exit }
    c >= 2 { exit }
  ' "$1"
}

@test "every skill has a SKILL.md with name + description frontmatter" {
  local missing=()

  for dir in "$SKILLS"/*/; do
    local f="$dir/SKILL.md"

    [[ -f $f ]] || { missing+=("$(basename "$dir"): no SKILL.md"); continue; }
    [[ -n $(frontmatter_value "$f" name) ]] ||
      missing+=("$(basename "$dir"): missing name")
    [[ -n $(frontmatter_value "$f" description) ]] ||
      missing+=("$(basename "$dir"): missing description")
  done

  ((${#missing[@]} == 0)) || fail "$(printf '%s\n' "${missing[@]}")"
}

@test "every skill name matches its directory and the charset/length rules" {
  local bad=()

  for dir in "$SKILLS"/*/; do
    local f="$dir/SKILL.md"
    [[ -f $f ]] || continue

    local base name
    base="$(basename "$dir")"
    name="$(frontmatter_value "$f" name)"
    name="${name//[\"\']/}"

    [[ $name == "$base" ]] ||
      bad+=("$base: name '$name' != directory")
    [[ $name =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?$ ]] ||
      bad+=("$base: name '$name' not lowercase letters/digits/hyphens")
    [[ $name != *--* ]] ||
      bad+=("$base: name has consecutive hyphens")
    ((${#name} >= 1 && ${#name} <= 64)) ||
      bad+=("$base: name length ${#name} outside 1..64")
  done

  ((${#bad[@]} == 0)) || fail "$(printf '%s\n' "${bad[@]}")"
}

@test "every skill description is within the 1024-char limit" {
  local bad=()

  for dir in "$SKILLS"/*/; do
    local f="$dir/SKILL.md"
    [[ -f $f ]] || continue

    local desc
    desc="$(frontmatter_value "$f" description)"

    ((${#desc} <= 1024)) ||
      bad+=("$(basename "$dir"): description ${#desc} chars > 1024")
  done

  ((${#bad[@]} == 0)) || fail "$(printf '%s\n' "${bad[@]}")"
}
