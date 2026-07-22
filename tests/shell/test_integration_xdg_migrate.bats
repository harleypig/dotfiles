#!/usr/bin/env bats

# Integration test for `xdg-audit --migrate` across a real filesystem boundary.
# The unit suite (tests/perl/xdg-audit.t) runs in a single tempdir, so a
# rename() there always succeeds and the cross-filesystem paths are never
# exercised. Here a tmpfs mount at /altfs is a genuinely SEPARATE filesystem,
# so a rename() into it returns EXDEV — reproducing:
#   - a cross-fs FILE move must still succeed (File::Copy::move copy+unlink);
#   - a cross-fs DIRECTORY move must be REFUSED (core-only; no recursive copy),
#     the regression guard for the $!-clobbered EXDEV check that a deferred
#     `require Errno` introduced (fixed by capturing errno immediately).
# Skips when docker is unavailable.

# shellcheck disable=SC2016  # the single-quoted scripts run inside the container.

load ../helpers/common

PERL_IMAGE='perl:5.40-slim'

setup() {
  load_bats_libs
  command -v docker > /dev/null 2>&1 || skip "docker not available"
}

# Run a setup+invocation script in a perl container with the repo mounted
# read-only at /dotfiles and a tmpfs at /altfs (a separate filesystem). Sets
# $output/$status.
migrate_in_container() {
  run docker run --rm -v "$(dotfiles_root):/dotfiles:ro" --tmpfs /altfs \
    "$PERL_IMAGE" bash -c "$1"
}

@test "cross-filesystem FILE move succeeds (copy + unlink across the boundary)" {
  migrate_in_container '
    DB=/tmp/db; export HOME=/testhome
    mkdir -p "$DB/programs-local" "$HOME"
    cat > "$DB/programs-local/mgfile.json" <<J
{ "name":"mgfile","files":[{"path":"\$HOME/.mgfile","movable":true,"mechanism":"env","env":"MG_FILE","rewrite":"/altfs/mgfile"}] }
J
    printf keep-me > "$HOME/.mgfile"
    printf "y\n" | env MG_FILE=/altfs/mgfile \
      /dotfiles/bin/xdg-audit --home "$HOME" --db "$DB" --migrate mgfile 2>&1
    echo "SRC_PRESENT=$([ -e "$HOME/.mgfile" ] && echo y || echo n)"
    echo "TGT_PRESENT=$([ -e /altfs/mgfile ] && echo y || echo n)"
    echo "CONTENT=$(cat /altfs/mgfile 2>/dev/null)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"migrated"* ]]
  [[ "$output" == *"SRC_PRESENT=n"* ]]
  [[ "$output" == *"TGT_PRESENT=y"* ]]
  [[ "$output" == *"CONTENT=keep-me"* ]]
}

@test "cross-filesystem DIRECTORY move is refused, source left intact" {
  migrate_in_container '
    DB=/tmp/db; export HOME=/testhome
    mkdir -p "$DB/programs-local" "$HOME/.mgdir"
    printf inner-data > "$HOME/.mgdir/inner"
    cat > "$DB/programs-local/mgdir.json" <<J
{ "name":"mgdir","files":[{"path":"\$HOME/.mgdir","movable":true,"mechanism":"env","env":"MG_DIR","rewrite":"/altfs/mgdir"}] }
J
    printf "y\n" | env MG_DIR=/altfs/mgdir \
      /dotfiles/bin/xdg-audit --home "$HOME" --db "$DB" --migrate mgdir 2>&1
    echo "SRC_INNER=$([ -e "$HOME/.mgdir/inner" ] && echo y || echo n)"
    echo "TGT_PRESENT=$([ -e /altfs/mgdir ] && echo y || echo n)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"cross-filesystem directory move"* ]]
  [[ "$output" == *"SRC_INNER=y"* ]]
  [[ "$output" == *"TGT_PRESENT=n"* ]]
}
