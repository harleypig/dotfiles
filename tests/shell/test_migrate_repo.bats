#!/usr/bin/env bats

# Tests for bin/migrate-repo — copy or migrate a repo to another box.
#
# Every repo lives in a throwaway PROJECTS_DIR with a local bare origin, so
# upstream / ahead checks work offline; its origin URL is then rewritten to
# a GitHub one so OWNER/REPO derivation has something to read. ssh is a stub
# that answers the three calls the script makes and records the sync call's
# script and arguments, so the remote half is never actually reached.

load ../helpers/common

setup() {
  load_bats_libs

  MR="$(dotfiles_root)/bin/migrate-repo"

  export PROJECTS_DIR="$BATS_TEST_TMPDIR/projects"
  ORIGINS="$BATS_TEST_TMPDIR/origins"
  STUB="$BATS_TEST_TMPDIR/stub"

  mkdir -p "$PROJECTS_DIR/worktrees" "$ORIGINS" "$STUB"

  write_ssh_stub
  set_remote_outcome 0 0 0 $'REPO_ABSENT\nCLONE_OK'

  PATH="$STUB:$PATH"
}

#-----------------------------------------------------------------------------
# Stand in for ssh. Skips the -o options and the host, then dispatches on the
# remote command: `true` (BatchMode probe), `gh auth status`, or the sync
# (`bash -s -- ...`), whose stdin script and positional args are saved for
# assertions. Outcomes come from files so a test can set them after setup.

write_ssh_stub() {
  cat > "$STUB/ssh" << EOF
#!/usr/bin/env bash
while [[ \${1-} == -* ]]; do
  case \$1 in
    -o) shift 2 ;;
    *) shift ;;
  esac
done
host=\$1
shift
printf '%s\n' "\$host \$*" >> "$STUB/ssh.args"
case "\$*" in
  true) exit "\$(< "$STUB/ssh_batchmode_rc")" ;;
  'gh auth status') exit "\$(< "$STUB/ssh_ghauth_rc")" ;;
  'bash -s -- '*)
    cat > "$STUB/ssh_sync.stdin"
    shift 3
    printf '%s\n' "\$@" > "$STUB/ssh_sync.args"
    cat "$STUB/ssh_sync_output"
    exit "\$(< "$STUB/ssh_sync_rc")"
    ;;
esac
echo "ssh stub: unexpected command: \$*" >&2
exit 99
EOF

  chmod +x "$STUB/ssh"
}

set_remote_outcome() {
  printf '%s' "$1" > "$STUB/ssh_batchmode_rc"
  printf '%s' "$2" > "$STUB/ssh_ghauth_rc"
  printf '%s' "$3" > "$STUB/ssh_sync_rc"
  printf '%s\n' "$4" > "$STUB/ssh_sync_output"
}

#-----------------------------------------------------------------------------
# Fixture repos. make_repo <relpath> [<github-name>] creates the repo under
# PROJECTS_DIR with a pushed master and an origin URL naming <github-name>
# (default: the basename). add_worktree <relpath> <branch> <state> adds a
# linked worktree at the mirrored worktrees/<relpath>/<branch> path in one of
# the states the script judges. Both swap the local bare origin back in
# while pushing so tracking refs exist offline.

make_repo() {
  local relpath=$1 gh_name=${2:-${1##*/}}
  local dir="$PROJECTS_DIR/$relpath" bare="$ORIGINS/$relpath.git"

  mkdir -p "$(dirname "$bare")"
  git init --bare -q "$bare"

  make_test_repo "$dir"
  git -C "$dir" branch -q -M master
  git -C "$dir" remote add origin "$bare"
  git -C "$dir" push -q -u origin master
  git -C "$dir" remote set-url origin "git@github.com:acme/$gh_name.git"
}

add_worktree() {
  local relpath=$1 branch=$2 state=$3
  local dir="$PROJECTS_DIR/$relpath" bare="$ORIGINS/$relpath.git"
  local wt="$PROJECTS_DIR/worktrees/$relpath/$branch" url

  url=$(git -C "$dir" remote get-url origin)

  mkdir -p "$(dirname "$wt")"
  git -C "$dir" worktree add -q -b "$branch" "$wt" master
  git -C "$dir" remote set-url origin "$bare"

  case $state in
    clean)
      git -C "$wt" push -q -u origin "$branch"
      ;;
    dirty)
      git -C "$wt" push -q -u origin "$branch"
      touch "$wt/scratch"
      ;;
    unpushed)
      git -C "$wt" push -q -u origin "$branch"
      git -C "$wt" commit -q --allow-empty -m more
      ;;
    detached)
      git -C "$wt" checkout -q --detach
      ;;
    no-upstream) ;;
  esac

  git -C "$dir" remote set-url origin "$url"
}

# The whole local footprint of a repo, for the "untouched" assertions.
assert_local_intact() {
  local relpath=$1

  assert_dir_exists "$PROJECTS_DIR/$relpath/.git"
  assert_dir_exists "$PROJECTS_DIR/worktrees/$relpath"
}

#-----------------------------------------------------------------------------
# Execute the remote script the ssh stub captured, in a throwaway "remote"
# PROJECTS_DIR, with the args it was sent. gh is a stub whose `repo clone`
# clones the local bare instead, and an insteadOf rewrite (env-only, so the
# repo's configured origin still READS as the GitHub URL) lets fetch reach
# that bare too.

run_remote_script() {
  local remote_projects=$1 bare=$2 github_url=$3
  local -a args

  # shellcheck disable=SC2016  # the body expands when the stub runs, not here
  make_script_stub "$STUB" gh \
    '[[ $1 == repo && $2 == clone ]] || exit 1; git clone -q "$GH_CLONE_SRC" "$4"'

  mapfile -t args < "$STUB/ssh_sync.args"

  run env "PROJECTS_DIR=$remote_projects" "GH_CLONE_SRC=$bare" \
    GIT_CONFIG_COUNT=1 "GIT_CONFIG_KEY_0=url.$bare.insteadOf" "GIT_CONFIG_VALUE_0=$github_url" \
    bash -s -- "${args[@]}" < "$STUB/ssh_sync.stdin"
}

# A pre-existing clone on the "remote", with the given configured origin.
make_remote_clone() {
  local dest=$1 bare=$2 origin_url=$3

  mkdir -p "$(dirname "$dest")"
  git clone -q "$bare" "$dest"
  git -C "$dest" config remote.origin.url "$origin_url"
}

#-----------------------------------------------------------------------------
# Argument handling

@test "no positionals prints usage and exits 2" {
  run "$MR"
  assert_equal "$status" 2
  assert_output --partial 'Usage: migrate-repo'
}

@test "--migrate and --copy are mutually exclusive" {
  make_repo flat
  run "$MR" --migrate --copy flat box
  assert_equal "$status" 2
  assert_output --partial 'only one of'
}

@test "one positional only prints usage and exits 2" {
  make_repo flat
  run "$MR" flat
  assert_equal "$status" 2
  assert_output --partial 'Usage: migrate-repo'
}

@test "--help exits 0 with usage" {
  run "$MR" --help
  assert_success
  assert_output --partial 'Usage: migrate-repo'
}

#-----------------------------------------------------------------------------
# Repo lookup

@test "an unknown name fails with 'no repo named'" {
  make_repo flat
  run "$MR" nosuch box
  assert_failure
  assert_output --partial "no repo named 'nosuch'"
}

@test "a flat repo resolves by bare name" {
  make_repo flat
  run "$MR" flat box
  assert_success
  assert_output --partial 'Repo:        flat'
  assert_output --partial "Local path:  $PROJECTS_DIR/flat"
}

@test "a nested repo resolves by its qualified name" {
  make_repo cust/nested
  run "$MR" cust/nested box
  assert_success
  assert_output --partial 'Repo:        cust/nested'
}

@test "a nested repo resolves by an unambiguous bare name to the qualified relpath" {
  make_repo cust/nested
  run "$MR" nested box
  assert_success
  assert_output --partial 'Repo:        cust/nested'
  assert_output --partial "Local path:  $PROJECTS_DIR/cust/nested"
}

@test "a bare name found in two customer folders lists both and fails" {
  make_repo custa/dup
  make_repo custb/dup
  run "$MR" dup box
  assert_failure
  assert_output --partial 'ambiguous'
  assert_output --partial 'custa/dup'
  assert_output --partial 'custb/dup'
}

@test "a bare name matching both a flat and a nested repo lists both and fails" {
  make_repo dup
  make_repo cust/dup
  run "$MR" dup box
  assert_failure
  assert_output --partial 'ambiguous'
  assert_line '  dup'
  assert_line '  cust/dup'
}

@test "a remote sorting before origin does not displace it" {
  make_repo flat
  git -C "$PROJECTS_DIR/flat" remote add backup https://github.com/other/flat-backup.git
  run "$MR" flat box
  assert_success
  assert_output --partial 'clone acme/flat if absent'
  assert_output --partial 'origin must match git@github.com:acme/flat.git'
  assert_output --partial '  backup     https://github.com/other/flat-backup.git'
}

@test "a repo under worktrees/ is never a candidate" {
  git init -q "$PROJECTS_DIR/worktrees/flat"
  run "$MR" flat box
  assert_failure
  assert_output --partial "no repo named 'flat'"
}

@test "a linked worktree (.git file) is not a repo candidate, bare or qualified" {
  make_repo other
  mkdir -p "$PROJECTS_DIR/cust"
  git -C "$PROJECTS_DIR/other" worktree add -q -b linked "$PROJECTS_DIR/cust/linked" master

  run "$MR" linked box
  assert_failure
  assert_output --partial "no repo named 'linked'"

  run "$MR" cust/linked box
  assert_failure
  assert_output --partial "no repo named 'cust/linked'"
}

@test "a repo with no origin remote dies" {
  make_test_repo "$PROJECTS_DIR/flat"
  run "$MR" flat box
  assert_failure
  assert_output --partial "flat has no 'origin' remote"
}

@test "a repo whose origin is not a GitHub URL dies" {
  make_test_repo "$PROJECTS_DIR/flat"
  git -C "$PROJECTS_DIR/flat" remote add origin /srv/git/flat.git
  run "$MR" flat box
  assert_failure
  assert_output --partial 'not a GitHub URL: /srv/git/flat.git'
}

@test "a name matching no directory is found by its remote URL basename" {
  make_repo checkout-dir realname
  run "$MR" realname box
  assert_success
  assert_output --partial 'Repo:        checkout-dir'
  assert_output --partial 'git@github.com:acme/realname.git'
}

#-----------------------------------------------------------------------------
# Dry run (the default)

@test "no flag is a dry run: reports, never runs the sync" {
  make_repo flat
  add_worktree flat feat clean
  run "$MR" flat box
  assert_success
  assert_output --partial 'DRY RUN'
  assert_output --partial 'would NOT run: --migrate not given'
  assert_output --partial 'Verdict: a real run would proceed'
  assert_file_not_exists "$STUB/ssh_sync.stdin"
  assert_local_intact flat
}

@test "a dry run with ssh failing still prints the worktree table and exits 1" {
  make_repo flat
  add_worktree flat feat clean
  set_remote_outcome 255 0 0 ''
  run "$MR" flat box
  assert_failure
  assert_output --partial '[FAIL] ssh box'
  assert_output --partial "$PROJECTS_DIR/worktrees/flat/feat"
  assert_output --partial 'Verdict: BLOCKED'
  assert_file_not_exists "$STUB/ssh_sync.stdin"
}

@test "a dry run with gh unauthenticated on the remote is blocked and exits 1" {
  make_repo flat
  set_remote_outcome 0 1 0 ''
  run "$MR" flat box
  assert_failure
  assert_output --partial '[ok]   ssh box'
  assert_output --partial '[FAIL] gh auth status on box'
  assert_output --partial 'Verdict: BLOCKED'
  assert_output --partial 'gh is not authenticated on box'
}

#-----------------------------------------------------------------------------
# Copy-mode preflight and worktree gates

@test "--copy aborts before the sync when ssh fails" {
  make_repo flat
  set_remote_outcome 255 0 0 ''
  run "$MR" --copy flat box <<< N
  assert_failure
  assert_output --partial 'cannot ssh to box'
  refute_output --partial 'aborted'
  assert_file_not_exists "$STUB/ssh_sync.stdin"
}

@test "--copy aborts before the sync when gh is not authenticated on the remote" {
  make_repo flat
  set_remote_outcome 0 1 0 ''
  run "$MR" --copy flat box <<< N
  assert_failure
  assert_output --partial 'gh is not authenticated on box'
  assert_file_not_exists "$STUB/ssh_sync.stdin"
}

@test "--copy aborts on a dirty worktree and names it" {
  make_repo flat
  add_worktree flat feat dirty
  run "$MR" --copy flat box <<< N
  assert_failure
  assert_output --partial "worktree $PROJECTS_DIR/worktrees/flat/feat is dirty"
  assert_file_not_exists "$STUB/ssh_sync.stdin"
}

@test "--copy aborts on an unpushed worktree" {
  make_repo flat
  add_worktree flat feat unpushed
  run "$MR" --copy flat box <<< N
  assert_failure
  assert_output --partial 'unpushed(1)'
  assert_file_not_exists "$STUB/ssh_sync.stdin"
}

@test "--copy aborts on a worktree with no upstream" {
  make_repo flat
  add_worktree flat feat no-upstream
  run "$MR" --copy flat box <<< N
  assert_failure
  assert_output --partial "worktree $PROJECTS_DIR/worktrees/flat/feat is no-upstream"
  assert_file_not_exists "$STUB/ssh_sync.stdin"
}

@test "--migrate aborts before the sync on a locked worktree" {
  make_repo flat
  add_worktree flat feat clean
  git -C "$PROJECTS_DIR/flat" worktree lock "$PROJECTS_DIR/worktrees/flat/feat"
  run "$MR" --migrate flat box <<< Y
  assert_failure
  assert_output --partial "worktree $PROJECTS_DIR/worktrees/flat/feat is locked"
  assert_file_not_exists "$STUB/ssh_sync.stdin"
  assert_local_intact flat
  assert_dir_exists "$PROJECTS_DIR/worktrees/flat/feat"
}

@test "--migrate blocked by worktree state leaves everything on disk" {
  make_repo flat
  add_worktree flat feat dirty
  add_worktree flat other detached
  run "$MR" --migrate flat box <<< Y
  assert_failure
  assert_output --partial 'dirty'
  assert_output --partial 'detached'
  assert_file_not_exists "$STUB/ssh_sync.stdin"
  assert_local_intact flat
  assert_dir_exists "$PROJECTS_DIR/worktrees/flat/feat"
  assert_dir_exists "$PROJECTS_DIR/worktrees/flat/other"
  assert_file_exists "$PROJECTS_DIR/worktrees/flat/feat/scratch"
}

#-----------------------------------------------------------------------------
# Confirmation

@test "answering N at the prompt exits 0 without syncing" {
  make_repo flat
  run "$MR" --copy flat box <<< N
  assert_success
  assert_output --partial 'aborted'
  assert_file_not_exists "$STUB/ssh_sync.stdin"
}

#-----------------------------------------------------------------------------
# Copy mode

@test "--copy with a fresh clone on the remote succeeds and leaves local intact" {
  make_repo flat
  add_worktree flat feat clean
  run "$MR" --copy flat box <<< Y
  assert_success
  assert_output --partial 'remote: clone ok'
  assert_output --partial 'copied flat to box'
  assert_file_exists "$STUB/ssh_sync.stdin"
  assert_local_intact flat
  assert_dir_exists "$PROJECTS_DIR/worktrees/flat/feat"
}

@test "--copy with an existing remote repo fast-forwards it" {
  make_repo flat
  set_remote_outcome 0 0 0 $'REPO_EXISTS\nUPDATE_OK'
  run "$MR" --copy flat box <<< Y
  assert_success
  assert_output --partial 'remote: fetch + fast-forward ok'
  assert_output --partial 'copied flat to box'
}

@test "a failed remote update is surfaced and local is left intact" {
  make_repo flat
  add_worktree flat feat clean
  set_remote_outcome 0 0 1 $'REPO_EXISTS\nUPDATE_FAILED'
  run "$MR" --copy flat box <<< Y
  assert_failure
  assert_output --partial 'fast-forward FAILED'
  assert_output --partial 'remote sync failed'
  assert_local_intact flat
}

#-----------------------------------------------------------------------------
# Migrate mode

@test "--migrate removes worktrees, the mirrored worktrees dir, its symlink, and the repo" {
  make_repo cust/nested
  add_worktree cust/nested feat clean
  ln -s cust/nested "$PROJECTS_DIR/worktrees/nested"

  run "$MR" --migrate nested box <<< Y
  assert_success
  assert_output --partial 'migrated cust/nested to box'
  assert_file_exists "$STUB/ssh_sync.stdin"

  assert_not_exists "$PROJECTS_DIR/cust/nested"
  assert_not_exists "$PROJECTS_DIR/worktrees/cust/nested"
  assert_not_exists "$PROJECTS_DIR/worktrees/nested"
  assert_dir_exists "$PROJECTS_DIR/cust"
  assert_output --partial "$PROJECTS_DIR/cust is now empty"
}

@test "--migrate of a flat repo removes it and its mirrored worktrees dir" {
  make_repo flat
  add_worktree flat feat clean

  run "$MR" --migrate flat box <<< Y
  assert_success
  assert_output --partial 'migrated flat to box'
  assert_not_exists "$PROJECTS_DIR/flat"
  assert_not_exists "$PROJECTS_DIR/worktrees/flat"
  refute_output --partial 'is now empty'
}

@test "--migrate leaves a worktrees/<basename> symlink alone when it points elsewhere" {
  make_repo cust/nested
  mkdir -p "$PROJECTS_DIR/worktrees/unrelated"
  ln -s unrelated "$PROJECTS_DIR/worktrees/nested"

  run "$MR" --migrate nested box <<< Y
  assert_success
  assert_not_exists "$PROJECTS_DIR/cust/nested"
  assert_link_exists "$PROJECTS_DIR/worktrees/nested"
  assert_dir_exists "$PROJECTS_DIR/worktrees/unrelated"
}

@test "--migrate with a failed sync removes nothing" {
  make_repo cust/nested
  add_worktree cust/nested feat clean
  ln -s cust/nested "$PROJECTS_DIR/worktrees/nested"
  set_remote_outcome 0 0 1 $'REPO_ABSENT\nCLONE_FAILED'

  run "$MR" --migrate nested box <<< Y
  assert_failure
  assert_output --partial 'remote: clone FAILED'
  assert_output --partial 'left intact'

  assert_local_intact cust/nested
  assert_dir_exists "$PROJECTS_DIR/worktrees/cust/nested/feat"
  assert_link_exists "$PROJECTS_DIR/worktrees/nested"
}

#-----------------------------------------------------------------------------
# Extra remotes

@test "an extra remote is passed to the sync as a name/url pair" {
  make_repo flat
  git -C "$PROJECTS_DIR/flat" remote add upstream https://github.com/other/flat.git
  set_remote_outcome 0 0 0 $'REPO_ABSENT\nCLONE_OK\nREMOTE_ADDED:upstream'

  run "$MR" --copy flat box <<< Y
  assert_success
  assert_output --partial "remote: remote 'upstream' added"

  run cat "$STUB/ssh_sync.args"
  assert_line --index 0 'flat'
  assert_line --index 1 'acme/flat'
  assert_line --index 2 'git@github.com:acme/flat.git'
  assert_line --index 3 'upstream'
  assert_line --index 4 'https://github.com/other/flat.git'
}

@test "a remote URL mismatch on the remote aborts and leaves local intact" {
  make_repo flat
  add_worktree flat feat clean
  git -C "$PROJECTS_DIR/flat" remote add upstream https://github.com/other/flat.git
  set_remote_outcome 0 0 1 $'REPO_EXISTS\nUPDATE_OK\nREMOTE_MISMATCH:upstream:https://github.com/x/y.git:https://github.com/other/flat.git'

  run "$MR" --migrate flat box <<< Y
  assert_failure
  assert_output --partial "remote URL mismatch (name:theirs:ours) upstream:"
  assert_local_intact flat
}

@test "an origin mismatch on the remote aborts and leaves local intact" {
  make_repo flat
  add_worktree flat feat clean
  set_remote_outcome 0 0 1 $'REPO_EXISTS\nORIGIN_MISMATCH:git@github.com:x/y.git:git@github.com:acme/flat.git'

  run "$MR" --migrate flat box <<< Y
  assert_failure
  assert_output --partial 'origin URL mismatch'
  assert_local_intact flat
}

#-----------------------------------------------------------------------------
# The remote script, executed for real
#
# Runs the captured script against a throwaway "remote" PROJECTS_DIR, so the
# marker contract is proven by the code that emits it, not by the stub.

@test "remote script: absent repo is cloned and the extra remote added" {
  make_repo flat
  git -C "$PROJECTS_DIR/flat" remote add upstream https://github.com/other/flat.git
  run "$MR" --copy flat box <<< Y
  assert_success

  REMOTE="$BATS_TEST_TMPDIR/remote"
  run_remote_script "$REMOTE" "$ORIGINS/flat.git" git@github.com:acme/flat.git
  assert_success
  assert_line REPO_ABSENT
  assert_line CLONE_OK
  assert_line REMOTE_ADDED:upstream

  assert_dir_exists "$REMOTE/flat/.git"
  assert_equal "$(git -C "$REMOTE/flat" config remote.upstream.url)" https://github.com/other/flat.git
}

@test "remote script: present repo with the same origin is fast-forwarded" {
  make_repo flat
  run "$MR" --copy flat box <<< Y
  assert_success

  REMOTE="$BATS_TEST_TMPDIR/remote"
  make_remote_clone "$REMOTE/flat" "$ORIGINS/flat.git" git@github.com:acme/flat.git
  run_remote_script "$REMOTE" "$ORIGINS/flat.git" git@github.com:acme/flat.git
  assert_success
  assert_line REPO_EXISTS
  assert_line UPDATE_OK
}

@test "remote script: present repo with a different origin fails without touching it" {
  make_repo flat
  run "$MR" --copy flat box <<< Y
  assert_success

  REMOTE="$BATS_TEST_TMPDIR/remote"
  make_remote_clone "$REMOTE/flat" "$ORIGINS/flat.git" git@github.com:x/y.git
  run_remote_script "$REMOTE" "$ORIGINS/flat.git" git@github.com:acme/flat.git
  assert_failure
  assert_line REPO_EXISTS
  assert_line 'ORIGIN_MISMATCH:git@github.com:x/y.git:git@github.com:acme/flat.git'
  refute_line UPDATE_OK
  assert_equal "$(git -C "$REMOTE/flat" config remote.origin.url)" git@github.com:x/y.git
}

@test "remote script: an extra remote with a different URL fails after the rest are processed" {
  make_repo flat
  git -C "$PROJECTS_DIR/flat" remote add upstream https://github.com/other/flat.git
  git -C "$PROJECTS_DIR/flat" remote add mirror https://github.com/mirror/flat.git
  run "$MR" --copy flat box <<< Y
  assert_success

  REMOTE="$BATS_TEST_TMPDIR/remote"
  # The pre-existing upstream points somewhere fetchable (fetch --all reaches
  # every remote) but different from what the local repo has.
  make_remote_clone "$REMOTE/flat" "$ORIGINS/flat.git" git@github.com:acme/flat.git
  git -C "$REMOTE/flat" remote add upstream "$ORIGINS/flat.git"
  run_remote_script "$REMOTE" "$ORIGINS/flat.git" git@github.com:acme/flat.git
  assert_failure
  assert_line UPDATE_OK
  assert_line "REMOTE_MISMATCH:upstream:$ORIGINS/flat.git:https://github.com/other/flat.git"
  assert_line REMOTE_ADDED:mirror
  assert_equal "$(git -C "$REMOTE/flat" config remote.upstream.url)" "$ORIGINS/flat.git"
}
