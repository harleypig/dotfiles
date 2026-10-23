#!/usr/bin/env bats

# Repo-structure guard: README.md's *Modular Configuration* list names
# exactly the shell-startup modules the loader sources. Without it the list
# drifts every time a module is added or retired (#548).
#
# A module is a tracked file in config/shell-startup/ that the loader in
# shell-startup would source: not a dotfile, and not *_inactive (both are
# skipped by its find).

load ../helpers/common

setup() {
  load_bats_libs
  ROOT="$(dotfiles_root)"
}

# Module names from the README's list entries (`- **`name`**: ...`), read
# only between the section heading and the next heading of the same level.
readme_modules() {
  awk '
    /^### Modular Configuration$/ { in_section = 1; next }
    in_section && /^#{1,3} /      { exit }
    in_section && match($0, /^- \*\*`[^`]+`\*\*:/) {
      name = substr($0, 6, RLENGTH - 9)
      print name
    }
  ' "$ROOT/README.md" | sort
}

# Tracked modules the loader would source.
tracked_modules() {
  git -C "$ROOT" ls-files config/shell-startup/ \
    | sed 's|^config/shell-startup/||' \
    | grep -v -e '^\.' -e '_inactive$' -e '/' \
    | sort
}

@test "the README module list parses to at least one entry" {
  run readme_modules
  assert_success
  refute_output ''
}

@test "git ls-files finds at least one active shell-startup module" {
  run tracked_modules
  assert_success
  refute_output ''
}

@test "every README module entry is a tracked, active module" {
  run comm -23 <(readme_modules) <(tracked_modules)
  assert_success
  assert_output ''
}

@test "every tracked, active module has a README entry" {
  run comm -13 <(readme_modules) <(tracked_modules)
  assert_success
  assert_output ''
}
