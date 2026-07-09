#!/usr/bin/env bats

# Conformance guard: the language/tool layering (EXTENDING.md *The language &
# tool stacks*). Every config/claude/rules/*.md declares a `layer:` in its
# frontmatter — one of generic|language|framework|tool|process — and this test
# enforces the layering invariants automatically (previously a by-hand
# claude-audit step that re-derived the taxonomy and grepped for up-references):
#
#   - a `language` rule references UP to code-style.md / EXTENDING.md
#     (specific -> generic; the generic layer itself never lists languages);
#   - a `tool` (language-agnostic) rule must NOT link a language file — it
#     declares the languages it applies to by name instead (the coupling lives
#     on the tool side, pointing out);
#   - `generic` (code-style.md) links no language file either.
#
# `framework` (single-language: fastapi->python, react->typescript, ...) rules
# are exempt from the tool rule — building on their one language rule is the
# allowed specific->less-generic direction. `process` rules (git/qa/docs/...)
# carry no layering constraint.
#
# The language set is DERIVED from the `layer: language` tags themselves, so
# there is no hardcoded language list to drift. See config/claude/EXTENDING.md,
# config/claude/rule-TEMPLATE.md, and the decision in
# config/claude/audit/decisions-log.md. Sibling guard: test_rule_frontmatter.bats
# (the load-tier check) — same self-hosted posture.

load ../helpers/common

VALID_LAYERS="generic language framework tool process"

setup() {
  load_bats_libs

  RULES="$(dotfiles_root)/config/claude/rules"
}

#------------------------------------------------------------------------------
# Print the value of the `layer:` key inside a file's opening frontmatter
# block (nothing if the file has no frontmatter or no `layer:` key).

layer_of() {
  awk '
    NR == 1 && $0 != "---" { exit }
    /^---$/ { c++; next }
    c == 1 && /^layer:[[:space:]]*/ { sub(/^layer:[[:space:]]*/, ""); print; exit }
    c >= 2 { exit }
  ' "$1"
}

#------------------------------------------------------------------------------
# Print the basename (no .md) of every rule tagged `layer: language` — the
# self-derived language set the tool/generic checks forbid linking to.

language_bases() {
  local f

  for f in "$RULES"/*.md; do
    [[ -f $f ]] || continue

    [[ "$(layer_of "$f")" == language ]] && basename "$f" .md
  done
}

#------------------------------------------------------------------------------
# An ERE alternation matching any `<language>.md` reference, e.g.
# `(bash|css|go|...)\.md`, built from the derived language set.

language_link_re() {
  local bases
  mapfile -t bases < <(language_bases)

  local IFS='|'
  printf '(%s)\\.md' "${bases[*]}"
}

@test "every rule declares a valid layer:" {
  local bad=()

  for f in "$RULES"/*.md; do
    [[ -f $f ]] || continue

    local l
    l="$(layer_of "$f")"

    if [[ -z $l ]]; then
      bad+=("$(basename "$f"): no 'layer:' key in frontmatter (expected one of: $VALID_LAYERS)")

    elif [[ " $VALID_LAYERS " != *" $l "* ]]; then
      bad+=("$(basename "$f"): invalid layer '$l' (expected one of: $VALID_LAYERS)")
    fi
  done

  ((${#bad[@]} == 0)) || fail "$(printf '%s\n' "${bad[@]}")"
}

@test "language rules reference up to the generic layer (code-style.md / EXTENDING.md)" {
  local bad=()

  for f in "$RULES"/*.md; do
    [[ -f $f ]] || continue
    [[ "$(layer_of "$f")" == language ]] || continue

    grep -qE 'code-style\.md|EXTENDING\.md' "$f" ||
      bad+=("$(basename "$f"): language rule must reference up to code-style.md or EXTENDING.md")
  done

  ((${#bad[@]} == 0)) || fail "$(printf '%s\n' "${bad[@]}")"
}

@test "tool and generic rules do not link a language file" {
  local re
  re="$(language_link_re)"

  local bad=()

  for f in "$RULES"/*.md; do
    [[ -f $f ]] || continue

    local l
    l="$(layer_of "$f")"
    [[ $l == tool || $l == generic ]] || continue

    local hit
    hit="$(grep -oE "$re" "$f" | sort -u | paste -sd, -)"

    [[ -z $hit ]] ||
      bad+=("$(basename "$f") ($l): must not link a language file, found: $hit")
  done

  ((${#bad[@]} == 0)) || fail "$(printf '%s\n' "${bad[@]}")"
}
