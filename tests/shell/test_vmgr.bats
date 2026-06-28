#!/usr/bin/env bats

# Unit tests for bin/vmgr's dispatch logic. These exercise argument handling,
# listing, and the language/manager resolution against throwaway fixture
# modules (VMGR_LIB_DIR override) plus a read-only check of the real lib dir -
# no managers are actually installed here. The real install/update/remove
# lifecycle is proven in test_integration_vmgr.bats (docker).

load ../helpers/common

setup() {
  load_bats_libs

  VMGR="$(dotfiles_root)/bin/vmgr"

  # A fixture lib dir: one single-manager language (foo -> barmgr) and one
  # ambiguous multi-manager language (baz -> uno, dos). The manager functions
  # just echo so we can assert dispatch without side effects.
  FIX="$BATS_TEST_TMPDIR/vm"
  mkdir -p "$FIX"

  cat > "$FIX/foo" << 'EOF'
#!/usr/bin/env bash
vmgr_managers=(barmgr)
barmgr_install() { echo "barmgr_install ran"; }
barmgr_update() { echo "barmgr_update ran"; }
barmgr_report() { echo "barmgr_report ran"; }
barmgr_help() { echo "barmgr_help ran"; }
EOF

  cat > "$FIX/baz" << 'EOF'
#!/usr/bin/env bash
vmgr_managers=(uno dos)
uno_install() { echo "uno ran"; }
dos_install() { echo "dos ran"; }
uno_report() { echo "uno report"; }
dos_report() { echo "dos report"; }
EOF
}

@test "no args lists available languages and their managers" {
  VMGR_LIB_DIR="$FIX" run "$VMGR"
  assert_success
  assert_output --partial 'foo: barmgr'
  assert_output --partial 'baz: uno dos'
}

@test "an action with no language lists rather than acting" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" install
  assert_success
  assert_output --partial 'foo: barmgr'
}

@test "explicit list action lists" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" list
  assert_success
  assert_output --partial 'baz: uno dos'
}

@test "single-manager language dispatches the matching function" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" install foo
  assert_success
  assert_output --partial 'barmgr_install ran'
}

@test "the action selects the function (update vs install)" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" update foo
  assert_success
  assert_output --partial 'barmgr_update ran'
}

@test "report is a standard action dispatched to <manager>_report" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" report foo
  assert_success
  assert_output --partial 'barmgr_report ran'
}

@test "an ambiguous multi-manager language lists its managers, does not act" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" install baz
  assert_success
  assert_output --partial 'multiple managers'
  assert_output --partial 'uno'
  assert_output --partial 'dos'
  refute_output --partial 'ran'
}

@test "an unknown action is a usage error (exit 2)" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" frobnicate foo
  assert_failure 2
  assert_output --partial "unknown action 'frobnicate'"
}

@test "an unknown language fails (exit 1)" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" install nope
  assert_failure 1
  assert_output --partial 'unknown language'
}

@test "an action the manager does not implement fails (exit 1)" {
  # foo's barmgr defines install/update but not remove.
  VMGR_LIB_DIR="$FIX" run "$VMGR" remove foo
  assert_failure 1
  assert_output --partial 'does not support remove'
}

@test "an invalid manager is rejected before acting" {
  # named managers are validated before any dispatch, so foo must NOT have acted.
  VMGR_LIB_DIR="$FIX" run "$VMGR" install foo bogus
  assert_failure 1
  assert_output --partial 'bogus is not a manager of foo'
  refute_output --partial 'barmgr_install ran'
}

@test "names one manager of a multi-manager language" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" install baz uno
  assert_success
  assert_output --partial 'uno ran'
  refute_output --partial 'dos ran'
}

@test "names several managers of a language" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" install baz uno dos
  assert_success
  assert_output --partial 'uno ran'
  assert_output --partial 'dos ran'
}

@test "only one language per invocation (a second language is rejected)" {
  # 'baz' is a language, but here it's in the manager position for 'foo'; foo
  # has no manager 'baz', so it's rejected (no multi-language batch).
  VMGR_LIB_DIR="$FIX" run "$VMGR" install foo baz
  assert_failure 1
  assert_output --partial 'baz is not a manager of foo'
  refute_output --partial 'barmgr_install ran'
}

@test "an informational action on a multi-manager language acts on all" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" report baz
  assert_success
  assert_output --partial 'uno report'
  assert_output --partial 'dos report'
}

@test "a named manager that lacks the action fails (exit 1)" {
  # baz's uno defines install/report but not remove.
  VMGR_LIB_DIR="$FIX" run "$VMGR" remove baz uno
  assert_failure 1
  assert_output --partial 'does not support remove'
}

@test "help prints usage" {
  run "$VMGR" help
  assert_success
  assert_output --partial 'vmgr <action> [language [manager ...]]'
}

@test "help <language> prints that manager's help" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" help foo
  assert_success
  assert_output --partial 'barmgr_help ran'
}

@test "help with an unknown language fails (exit 1)" {
  VMGR_LIB_DIR="$FIX" run "$VMGR" help nope
  assert_failure 1
  assert_output --partial 'unknown language'
}

@test "help node (real lib) shows node-specific help" {
  run "$VMGR" help node
  assert_success
  assert_output --partial 'managed via nvm'
  assert_output --partial 'config/vmgr/node'
}

@test "the real lib dir ships a node module advertising nvm" {
  # Against the actual lib/version-managers (no override): node -> nvm.
  run "$VMGR" list
  assert_success
  assert_output --partial 'node: nvm'
}
