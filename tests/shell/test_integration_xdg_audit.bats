#!/usr/bin/env bats

# Integration tests for bin/xdg-audit, run in a throwaway container (the repo
# mounted read-only at /dotfiles). These exercise what the hermetic unit suite
# (tests/perl/xdg-audit.t, a single synthetic tempdir) structurally cannot:
#
#   - the read-only modes end-to-end against the REAL vendored database in a
#     clean environment (index build over the real corpus, --json/--all/lookup/
#     reverse/--search/filters/--help);
#   - the mutating modes (--remove, --migrate) with REAL filesystem side
#     effects in a throwaway $HOME, so a mistake can never touch the host;
#   - --migrate ACROSS a real filesystem boundary (a --tmpfs mount at /altfs is
#     a separate filesystem, so rename() returns EXDEV): a file move must still
#     succeed and a directory move must be refused (the regression guard for an
#     errno-clobbering bug the tempdir unit suite could not reach);
#   - --update-db against a LOCAL git "upstream" (hermetic, no network): the
#     mirror is refreshed and a stale override is flagged obsolete.
#
# Skips when docker is unavailable.

# shellcheck disable=SC2016  # the single-quoted scripts run inside the container.

load ../helpers/common

setup() {
  load_bats_libs
  IMAGE="$(xdg_audit_harness_image)"
}

# ---------------------------------------------------------------------------
# Read-only modes against the real vendored database
# ---------------------------------------------------------------------------

@test "read-only modes run end-to-end against the real vendored database" {
  xdg_audit_run "$IMAGE" '
    # A writable copy of the real database (xdg-audit builds its index there).
    cp -r /dotfiles/config/xdg-audit /tmp/db
    export HOME=/tmp/smokehome; mkdir -p "$HOME"
    # A couple of real-db-owned dotfiles so the scan actually finds something.
    mkdir -p "$HOME/.gradle"; : > "$HOME/.wget-hsts"
    X() { /dotfiles/bin/xdg-audit --db /tmp/db --home "$HOME" "$@"; }

    X --reindex > /tmp/ri.txt 2>&1; echo "REINDEX_RC=$?"
    grep -q "rebuilt index" /tmp/ri.txt && echo "REINDEX_MSG=y"

    X --json > /tmp/scan.json 2>/dev/null; echo "SCAN_RC=$?"
    # Validate structurally: the feed decodes, is an array, and carries gradle.
    perl -MJSON::PP -e "JSON::PP->new->decode(do{local(@ARGV,\$/)=shift;<>})" /tmp/scan.json \
      && echo "JSON_DECODES=y"
    head -n1 /tmp/scan.json | grep -q "^\[" && echo "JSON_ISARRAY=y"
    grep -q "\"name\" : \"gradle\"" /tmp/scan.json && echo "JSON_HAS_GRADLE=y"

    X --all > /tmp/all.txt 2>&1; echo "ALL_RC=$?"
    grep -q "^unhandled" /tmp/all.txt && echo "ALL_HAS_GROUP=y"

    X gradle > /tmp/look.txt 2>&1; echo "LOOKUP_RC=$?"
    grep -q "gradle" /tmp/look.txt && echo "LOOKUP_HAS=y"

    X .gradle > /tmp/rev.txt 2>&1; echo "REVERSE_RC=$?"
    grep -q "gradle" /tmp/rev.txt && echo "REVERSE_HAS=y"

    X --search gradle > /tmp/search.txt 2>&1; echo "SEARCH_RC=$?"
    grep -q "gradle" /tmp/search.txt && echo "SEARCH_HAS=y"

    X --mechanism env --json > /dev/null 2>&1; echo "MECH_RC=$?"
    X --movable --json   > /dev/null 2>&1; echo "MOVABLE_RC=$?"
    X --immovable --json > /dev/null 2>&1; echo "IMMOVABLE_RC=$?"

    X --help > /tmp/help.txt 2>&1; echo "HELP_RC=$?"
    grep -q "^USAGE" /tmp/help.txt && echo "HELP_HAS=y"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"REINDEX_RC=0"* ]]
  [[ "$output" == *"REINDEX_MSG=y"* ]]
  # A present, un-redirected dotfile is actionable -> scan exits 2.
  [[ "$output" == *"SCAN_RC=2"* ]]
  [[ "$output" == *"JSON_DECODES=y"* ]]
  [[ "$output" == *"JSON_ISARRAY=y"* ]]
  [[ "$output" == *"JSON_HAS_GRADLE=y"* ]]
  [[ "$output" == *"ALL_RC=0"* ]] || [[ "$output" == *"ALL_RC=2"* ]]
  [[ "$output" == *"ALL_HAS_GROUP=y"* ]]
  [[ "$output" == *"LOOKUP_RC=0"* ]]
  [[ "$output" == *"LOOKUP_HAS=y"* ]]
  [[ "$output" == *"REVERSE_RC=0"* ]]
  [[ "$output" == *"REVERSE_HAS=y"* ]]
  [[ "$output" == *"SEARCH_RC=0"* ]]
  [[ "$output" == *"SEARCH_HAS=y"* ]]
  [[ "$output" == *"MECH_RC=0"* ]] || [[ "$output" == *"MECH_RC=2"* ]]
  [[ "$output" == *"HELP_RC=0"* ]]
  [[ "$output" == *"HELP_HAS=y"* ]]
}

# ---------------------------------------------------------------------------
# --remove: real filesystem side effects, in a throwaway $HOME
# ---------------------------------------------------------------------------

@test "--remove deletes a real leftover stray in an isolated \$HOME" {
  xdg_audit_run "$IMAGE" '
    DB=/tmp/db; export HOME=/tmp/rmhome
    mkdir -p "$DB/programs-local" "$HOME"
    cat > "$DB/programs-local/rmapp.json" <<"J"
{ "name":"rmapp","files":[{"path":"$HOME/.rmapp","movable":true,"mechanism":"env","env":"RM_ACTIVE","rewrite":"/tmp/rmtgt"}] }
J
    : > /tmp/rmtgt                     # target already populated -> a redundant leftover
    echo data > "$HOME/.rmapp"
    printf "y\n" | env RM_ACTIVE=/tmp/rmtgt \
      /dotfiles/bin/xdg-audit --db "$DB" --home "$HOME" --remove rmapp 2>&1
    echo "SRC=$([ -e "$HOME/.rmapp" ] && echo present || echo gone)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"removed"* ]]
  [[ "$output" == *"SRC=gone"* ]]
}

@test "--remove refuses a symlinked dotfile" {
  xdg_audit_run "$IMAGE" '
    DB=/tmp/db; export HOME=/tmp/rmhome2
    mkdir -p "$DB/programs-local" "$HOME" /tmp/lnktgt
    cat > "$DB/programs-local/lnkapp.json" <<"J"
{ "name":"lnkapp","files":[{"path":"$HOME/.lnkapp","movable":true,"mechanism":"env","env":"LNK","rewrite":"/tmp/x"}] }
J
    ln -s /tmp/lnktgt "$HOME/.lnkapp"
    printf "y\n" | env LNK=/tmp/x \
      /dotfiles/bin/xdg-audit --db "$DB" --home "$HOME" --remove lnkapp 2>&1
    echo "LINK=$([ -L "$HOME/.lnkapp" ] && echo intact || echo gone)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"linked (managed symlink) - not removed"* ]]
  [[ "$output" == *"LINK=intact"* ]]
}

# ---------------------------------------------------------------------------
# --migrate: real moves, same filesystem and across a filesystem boundary
# ---------------------------------------------------------------------------

@test "--migrate moves a real file to its XDG target (same filesystem)" {
  xdg_audit_run "$IMAGE" '
    DB=/tmp/db; export HOME=/tmp/mghome
    mkdir -p "$DB/programs-local" "$HOME"
    cat > "$DB/programs-local/mgapp.json" <<"J"
{ "name":"mgapp","files":[{"path":"$HOME/.mgapp","movable":true,"mechanism":"env","env":"MG_ACTIVE","rewrite":"/tmp/mgdata/mgapp"}] }
J
    printf secret > "$HOME/.mgapp"
    printf "y\n" | env MG_ACTIVE=/tmp/mgdata/mgapp \
      /dotfiles/bin/xdg-audit --db "$DB" --home "$HOME" --migrate mgapp 2>&1
    echo "SRC=$([ -e "$HOME/.mgapp" ] && echo present || echo gone)"
    echo "TGT=$([ -e /tmp/mgdata/mgapp ] && echo present || echo absent)"
    echo "CONTENT=$(cat /tmp/mgdata/mgapp 2>/dev/null)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"migrated"* ]]
  [[ "$output" == *"SRC=gone"* ]]
  [[ "$output" == *"TGT=present"* ]]
  [[ "$output" == *"CONTENT=secret"* ]]
}

@test "--migrate across filesystems: a FILE move succeeds (copy + unlink)" {
  xdg_audit_run "$IMAGE" '
    DB=/tmp/db; export HOME=/tmp/xfhome
    mkdir -p "$DB/programs-local" "$HOME"
    cat > "$DB/programs-local/xfile.json" <<"J"
{ "name":"xfile","files":[{"path":"$HOME/.xfile","movable":true,"mechanism":"env","env":"XF","rewrite":"/altfs/xfile"}] }
J
    printf across > "$HOME/.xfile"
    printf "y\n" | env XF=/altfs/xfile \
      /dotfiles/bin/xdg-audit --db "$DB" --home "$HOME" --migrate xfile 2>&1
    echo "SRC=$([ -e "$HOME/.xfile" ] && echo present || echo gone)"
    echo "TGT=$([ -e /altfs/xfile ] && echo present || echo absent)"
    echo "CONTENT=$(cat /altfs/xfile 2>/dev/null)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"migrated"* ]]
  [[ "$output" == *"SRC=gone"* ]]
  [[ "$output" == *"TGT=present"* ]]
  [[ "$output" == *"CONTENT=across"* ]]
}

@test "--migrate across filesystems: a DIRECTORY move is refused, source intact" {
  xdg_audit_run "$IMAGE" '
    DB=/tmp/db; export HOME=/tmp/xdhome
    mkdir -p "$DB/programs-local" "$HOME/.xdir"
    printf inside > "$HOME/.xdir/inner"
    cat > "$DB/programs-local/xdir.json" <<"J"
{ "name":"xdir","files":[{"path":"$HOME/.xdir","movable":true,"mechanism":"env","env":"XD","rewrite":"/altfs/xdir"}] }
J
    printf "y\n" | env XD=/altfs/xdir \
      /dotfiles/bin/xdg-audit --db "$DB" --home "$HOME" --migrate xdir 2>&1
    echo "SRC=$([ -e "$HOME/.xdir/inner" ] && echo intact || echo gone)"
    echo "TGT=$([ -e /altfs/xdir ] && echo present || echo absent)"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"cross-filesystem directory move"* ]]
  [[ "$output" == *"SRC=intact"* ]]
  [[ "$output" == *"TGT=absent"* ]]
}

# ---------------------------------------------------------------------------
# --update-db against a local git upstream (hermetic; no network)
# ---------------------------------------------------------------------------

@test "--update-db refreshes the mirror from a local git upstream and flags an obsolete override" {
  xdg_audit_run "$IMAGE" '
    set -e
    # A fake upstream as a local git repo (git clone works on file:// paths).
    UP=/tmp/upstream
    mkdir -p "$UP/programs" "$UP/json-schema"
    cp /dotfiles/config/xdg-audit/json-schema/program.json "$UP/json-schema/"
    printf "%s" "{ \"name\":\"widget\",\"files\":[{\"path\":\"\$HOME/.widget\",\"help\":\"NEW-UPSTREAM\"}] }" \
      > "$UP/programs/widget.json"
    git -C "$UP" init -q
    git -C "$UP" config user.email t@example.com
    git -C "$UP" config user.name tester
    git -C "$UP" add -A
    git -C "$UP" commit -q -m init

    # A writable db pinned to an OLDER widget, plus an override whose recorded
    # upstream-digest is stale (so the update must flag it obsolete).
    DB=/tmp/db
    mkdir -p "$DB/programs" "$DB/programs-local" "$DB/json-schema"
    cp /dotfiles/config/xdg-audit/json-schema/program.json "$DB/json-schema/"
    printf "%s" "{ \"name\":\"widget\",\"files\":[{\"path\":\"\$HOME/.widget\",\"help\":\"OLD-MIRROR\"}] }" \
      > "$DB/programs/widget.json"
    cat > "$DB/upstream.json" <<J
{ "repo": "file://$UP", "ref": "HEAD" }
J
    cat > "$DB/programs-local/widget.json" <<"J"
{ "name":"widget","override-of":"widget","upstream-digest":"deadbeefstale","files":[{"path":"$HOME/.widget","help":"LOCAL"}] }
J
    export HOME=/tmp/uhome; mkdir -p "$HOME"

    set +e
    /dotfiles/bin/xdg-audit --db "$DB" --home "$HOME" --update-db > /tmp/upd.txt 2>&1
    echo "UPDATE_RC=$?"
    cat /tmp/upd.txt
    grep -q "NEW-UPSTREAM" "$DB/programs/widget.json" && echo "MIRROR_UPDATED=y"
  '
  [ "$status" -eq 0 ]
  [[ "$output" == *"UPDATE_RC=0"* ]]
  [[ "$output" == *"changed programs: widget"* ]]
  [[ "$output" == *"MIRROR_UPDATED=y"* ]]
  # the stale override is surfaced as possibly obsolete
  [[ "$output" == *"obsolete"* ]]
  [[ "$output" == *"widget"* ]]
}
