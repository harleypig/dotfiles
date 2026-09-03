#!/usr/bin/env bats

# Unit tests for config/shell-startup/010-general's wslview BROWSER-override
# block: under WSL2 with wslview installed it overrides BROWSER to 'wslview'
# (taking precedence over the chromium-browser line above it); otherwise it
# leaves BROWSER untouched. The block is a bare `if`/`fi` with no enclosing
# function and 010-general has many unrelated havecmd-gated side effects
# (rust, vault, gcloud, gh, ...), so sourcing the whole file is disproportionate
# — extract just this block by line range and eval it in isolation, per
# bats.md's "Testing non-independently-sourceable shell".

load ../helpers/common

# Print the wslview override block (the `if grep -qi wsl2 ... fi` lines) out
# of 010-general so it can be eval'd without sourcing the rest of the file.
wsl_browser_block() {
  sed -n '/^if grep -qi wsl2/,/^fi$/p' "$(dotfiles_root)/config/shell-startup/010-general"
}

setup() {
  load_bats_libs
}

@test "WSL2 + wslview present: BROWSER is set to wslview" {
  # shellcheck disable=SC2329  # invoked indirectly by the eval'd block
  grep() { return 0; }
  # shellcheck disable=SC2329  # invoked indirectly by the eval'd block
  havecmd() { return 0; }

  unset BROWSER
  eval "$(wsl_browser_block)"

  assert_equal "$BROWSER" wslview
}

@test "not WSL2: BROWSER is left unchanged, even with wslview present" {
  # shellcheck disable=SC2329  # invoked indirectly by the eval'd block
  grep() { return 1; }
  # shellcheck disable=SC2329  # invoked indirectly by the eval'd block
  havecmd() { return 0; }

  unset BROWSER
  eval "$(wsl_browser_block)"

  [ -z "${BROWSER:-}" ]
}

@test "WSL2 but no wslview: BROWSER is left unchanged" {
  # shellcheck disable=SC2329  # invoked indirectly by the eval'd block
  grep() { return 0; }
  # shellcheck disable=SC2329  # invoked indirectly by the eval'd block
  havecmd() { return 1; }

  unset BROWSER
  eval "$(wsl_browser_block)"

  [ -z "${BROWSER:-}" ]
}
