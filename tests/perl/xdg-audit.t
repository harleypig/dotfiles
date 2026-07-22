#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use IPC::Open2 qw(open2);
use JSON::PP;

# Exercises bin/xdg-audit against a self-contained fixture database and a
# fixture $HOME, so nothing touches the real environment. Covers: scan +
# offender detection, already-redirected (mechanism env) status, overlay
# override winning over stale upstream, ignore suppression, clean-home exit 0,
# the enriched-index build + auto-rebuild, and the --json shape.

my $SCRIPT = 'bin/xdg-audit';
plan skip_all => "$SCRIPT not found" unless -f $SCRIPT;

# ------------------------------------------------------------------------------
# Fixtures
# ------------------------------------------------------------------------------

my $root = tempdir( CLEANUP => 1 );
my $db   = File::Spec->catdir( $root, 'db' );
my $home = File::Spec->catdir( $root, 'home' );
make_path( File::Spec->catdir( $db, 'programs' ) );
make_path( File::Spec->catdir( $db, 'programs-local' ) );
make_path($home);

sub write_json {
  my ( $path, $data ) = @_;
  open my $fh, '>:encoding(UTF-8)', $path or die "write $path: $!";
  print {$fh} JSON::PP->new->utf8(0)->canonical->encode($data);
  close $fh;
}

sub prog { File::Spec->catfile( $db, 'programs',       "$_[0].json" ) }
sub locl { File::Spec->catfile( $db, 'programs-local', "$_[0].json" ) }

sub touch {
  my ($name) = @_;
  my $p = File::Spec->catfile( $home, $name );
  open my $fh, '>', $p or die "touch $p: $!";
  close $fh;
  return $p;
}

# Upstream programs. docker's help is distinctive so we can prove the override
# backfills it. net/network share a prefix (exact-match must beat the fragment).
write_json( prog('foo'),
  { name => 'foo', files => [ { path => '$HOME/.foo', movable => JSON::PP::true, help => "move it\n" } ] } );
write_json( prog('docker'),
  { name => 'docker', files => [ { path => '$HOME/.docker', movable => JSON::PP::true, help => "UPSTREAM-DOCKER-HELP\n" } ] } );
write_json( prog('vim'),
  { name => 'vim', files => [ { path => '$HOME/.vimrc', movable => JSON::PP::true, help => "OLD-UPSTREAM-ADVICE\n" } ] } );
write_json( prog('secret'),
  { name => 'secret', files => [ { path => '$HOME/.secretdir', movable => JSON::PP::true, help => "leaks\n" } ] } );
write_json( prog('net'),
  { name => 'net', files => [ { path => '$HOME/.netrc', movable => JSON::PP::true, help => "n\n" } ] } );
write_json( prog('network'),
  { name => 'network', files => [ { path => '$HOME/.networkrc', movable => JSON::PP::true, help => "nw\n" } ] } );

# Overlay: a docker env annotation (NO help -> must backfill from upstream), a
# vim override, a secret ignore.
write_json( locl('docker'),
  { name => 'docker', files => [ { path => '$HOME/.docker', movable => JSON::PP::true, mechanism => 'env', env => 'FIXTURE_DOCKER_CONFIG' } ] } );
write_json( locl('vim'),
  { name => 'vim', 'override-of' => 'vim', files => [ { path => '$HOME/.vimrc', movable => JSON::PP::true, help => "NEW-XDG-ADVICE\n" } ] } );
write_json( locl('secret'),
  { name => 'secret', 'override-of' => 'secret', ignore => ['$HOME/.secretdir'] } );

# Fixture $HOME strays.
touch('.foo');
touch('.docker');
touch('.vimrc');
touch('.secretdir');
touch('.netrc');

# A single app owning several dotfiles (reached by a fragment, not exact name).
# Filename stem == app name, matching the real db convention (e.g. Claude Code).
write_json(
  prog('Big App'),
  {
    name  => 'Big App',
    files => [
      { path => '$HOME/.big',      movable => JSON::PP::true, help => "b1\n" },
      { path => '$HOME/.big.json', movable => JSON::PP::true, help => "b2\n" },
    ],
  }
);
touch('.big');

# One dotfile owned by two different apps.
write_json( prog('toola'), { name => 'toola', files => [ { path => '$HOME/.shared', movable => JSON::PP::true, help => "a\n" } ] } );
write_json( prog('toolb'), { name => 'toolb', files => [ { path => '$HOME/.shared', movable => JSON::PP::true, help => "b\n" } ] } );
touch('.shared');

# A symlinked dotfile (a managed link into "another repo").
my $other = File::Spec->catdir( $root, 'other-repo' );
make_path($other);
symlink( $other, File::Spec->catfile( $home, '.linkme' ) ) or die "symlink: $!";
write_json( prog('linky'), { name => 'linky', files => [ { path => '$HOME/.linkme', movable => JSON::PP::true, help => "l\n" } ] } );

# 'handled': redirect active (env set) but the $HOME file is absent (already
# migrated). .cleanme is intentionally NOT created.
write_json( locl('cleanapp'),
  { name => 'cleanapp', files => [ { path => '$HOME/.cleanme', movable => JSON::PP::true, help => "c\n", mechanism => 'env', env => 'FIXTURE_CLEAN' } ] } );

# env redirect detected via an existing target even though the variable is not
# exported (models a shell-internal var like HISTFILE). .histlike is a leftover.
my $rtarget = File::Spec->catfile( $root, 'redirect-target' );
open my $rt, '>', $rtarget or die "target: $!";
close $rt;
write_json( locl('histlike'),
  { name => 'histlike', files => [ { path => '$HOME/.histlike', movable => JSON::PP::true, help => "h\n", mechanism => 'env', env => 'FIXTURE_NEVER_SET', rewrite => $rtarget } ] } );
touch('.histlike');

# A local-only addition (no upstream) with two present, unredirected files:
# exercises --all's per-app collapse and the "overlay" tag (a mechanism-less
# path that is still from our overlay).
write_json( locl('addon'),
  { name => 'addon', files => [ { path => '$HOME/.addon1', movable => JSON::PP::true, help => "a1\n" }, { path => '$HOME/.addon2', movable => JSON::PP::true, help => "a2\n" } ] } );
touch('.addon1');
touch('.addon2');

# An ignore in object form carrying a reason (vs 'secret's bare-string form).
# .reasonedgone is ignored but NOT created -> must not appear (absent).
# .mystery is a $HOME dotfile that no db entry covers (surfaces as 'unknown').
write_json(
  locl('reasoned'),
  {
    name   => 'reasoned',
    ignore => [
      { path => '$HOME/.reasoned',     reason => 'left because tests' },
      { path => '$HOME/.reasonedgone', reason => 'not present' },
    ],
  }
);
touch('.reasoned');
touch('.mystery');

# ------------------------------------------------------------------------------
# Runner — invoke the script with a hermetic environment.
# ------------------------------------------------------------------------------

sub run_audit {
  my (@args) = @_;
  local $ENV{HOME}                  = $home;
  local $ENV{FIXTURE_DOCKER_CONFIG} = '1';
  local $ENV{FIXTURE_CLEAN}         = '1';
  delete local $ENV{XDG_CONFIG_HOME};
  delete local $ENV{XDG_CACHE_HOME};
  delete local $ENV{XDG_DATA_HOME};
  delete local $ENV{XDG_STATE_HOME};
  delete local $ENV{XDG_AUDIT_HOME};

  my $pid = open( my $fh, '-|', $^X, $SCRIPT, '--db', $db, '--home', $home, @args )
    or die "cannot run $SCRIPT: $!";
  local $/;
  my $out = <$fh> // '';
  close $fh;
  my $rc = $? >> 8;
  return ( $out, $rc );
}

sub run_json {
  my (@args) = @_;
  my ( $out, $rc ) = run_audit( '--json', @args );
  my $data = eval { JSON::PP->new->decode($out) };
  return ( $data, $rc, $out );
}

# Like run_audit, but feeds $input on STDIN (for --remove's confirmation
# prompt). Output is small, so writing all input up front then draining stdout
# cannot deadlock.
sub run_audit_stdin {
  my ( $input, @args ) = @_;
  local $ENV{HOME}                  = $home;
  local $ENV{FIXTURE_DOCKER_CONFIG} = '1';
  local $ENV{FIXTURE_CLEAN}         = '1';
  local $ENV{FIXTURE_RM}            = '1';    # active redirect for the rm stray
  delete local $ENV{XDG_CONFIG_HOME};
  delete local $ENV{XDG_CACHE_HOME};
  delete local $ENV{XDG_DATA_HOME};
  delete local $ENV{XDG_STATE_HOME};
  delete local $ENV{XDG_AUDIT_HOME};

  my ( $out_fh, $in_fh );
  my $pid = open2( $out_fh, $in_fh, $^X, $SCRIPT, '--db', $db, '--home', $home, @args );
  print {$in_fh} $input;
  close $in_fh;
  local $/;
  my $out = <$out_fh> // '';
  close $out_fh;
  waitpid $pid, 0;
  my $rc = $? >> 8;
  return ( $out, $rc );
}

# ------------------------------------------------------------------------------
# Scan
# ------------------------------------------------------------------------------

{
  my ( $out, $rc ) = run_audit();
  like( $out, qr/^unhandled$/m, 'scan prints a group header' );
  like( $out, qr/\bfoo \(\.foo\)/, 'scan shows "appname (.dotfile)" under its group' );
  unlike( $out, qr{\Q$home\E}, 'scan omits the assumed $HOME path prefix' );
  unlike( $out, qr/UNHANDLED|run 'xdg-audit/, 'no per-line status text (header names the type)' );
  is( $rc, 2, 'scan exits 2 when actionable findings are present' );
}

{
  my ( $data, $rc ) = run_json();
  is( ref $data, 'ARRAY', 'scan --json is a JSON array' );
  my %by = map { $_->{name} => $_ } @$data;
  ok( $by{foo},    'foo present in json scan' );
  ok( $by{docker}, 'docker present in json scan' );
  is( $by{docker}{group}, 'stray', 'docker groups as stray (present + redirect active)' );
  is( $by{foo}{group}, 'unhandled', 'foo groups as unhandled (present, no mechanism)' );
  is( $by{cleanapp}{group}, 'handled', 'cleanapp groups as handled (absent + redirect active)' );
  is( $by{histlike}{group}, 'stray', 'env redirect detected via existing target (unexported var)' );
  is( $by{secret}{group}, 'ignored', 'ignored entry carries group "ignored" in json' );
  is( $by{reasoned}{reason}, 'left because tests', 'ignore reason carried in json' );

  my ($mystery) = grep { ( $_->{group} // '' ) eq 'unknown' } @$data;
  is( $mystery->{display}, '.mystery', 'a $HOME dotfile with no db entry is json group "unknown"' );
}

# The non-actionable groups (handled, ignored, linked) are hidden by default
# and revealed only by --all.
{
  my ($out) = run_audit();
  unlike( $out, qr/^handled$/m,    'handled group hidden by default' );
  unlike( $out, qr/^ignored$/m,    'ignored group hidden by default' );
  unlike( $out, qr/^linked$/m,     'linked group hidden by default' );
  unlike( $out, qr/\bcleanapp\b/,  'already-migrated app not shown by default' );
  unlike( $out, qr/\.secretdir\b/, 'ignored path not shown by default' );
  unlike( $out, qr/\.linkme\b/,    'symlink not shown by default' );
  unlike( $out, qr/^unknown$/m,    'unknown group hidden by default' );
  unlike( $out, qr/\.mystery\b/,   'unknown dotfile not shown by default' );
}

# --all reveals every group and tags each entry with its mechanism.
{
  my ($out) = run_audit('--all');
  like( $out, qr/^handled$/m, '--all reveals the handled group' );
  like( $out, qr/^ignored$/m, '--all reveals the ignored group' );
  like( $out, qr/^linked$/m,  '--all reveals the linked group' );
  like( $out, qr/^unknown$/m, '--all reveals the unknown group' );

  like( $out, qr/cleanapp \(\.cleanme\) \(env\)/,    'handled entry tagged with its mechanism (env)' );
  like( $out, qr/secret \(\.secretdir\) \(ignore\)/, 'ignored entry tagged (ignore)' );
  like( $out, qr/linky \(\.linkme\) +-> \Q$other\E \(external\)/, 'linked entry shows "-> target (external)"' );
  like( $out, qr/addon \(\.addon1,\.addon2\) \(overlay\)/, '--all collapses an app and tags a mechanism-less overlay entry' );

  # Reason: object-form ignore shows its why; bare-string ignore shows none.
  like( $out, qr/reasoned \(\.reasoned\) \(ignore\) - left because tests/, 'ignore reason is shown in --all' );
  like( $out, qr/^  secret \(\.secretdir\) \(ignore\)$/m, 'bare-string ignore shows no reason' );

  # An ignored path that is absent from $HOME is not reported.
  unlike( $out, qr/\.reasonedgone/, 'absent ignored path is skipped, not shown' );

  # Unknown: a $HOME dotfile with no db entry is listed by name.
  like( $out, qr/^  \.mystery$/m, 'unknown dotfile listed by name' );
}

# The default (non-all) scan keeps the terse, per-path, untagged format.
{
  my ($out) = run_audit();
  like( $out, qr/^\s+addon \(\.addon1\)$/m, 'default scan lists dotfiles per line (no collapse)' );
  unlike( $out, qr/\((?:env|overlay|external|ignore)\)/, 'default scan carries no mechanism tags' );
}

# ------------------------------------------------------------------------------
# Lookup + override precedence
# ------------------------------------------------------------------------------

{
  my ( $out, $rc ) = run_audit('foo');
  like( $out, qr/foo/, 'app lookup shows the app' );
  like( $out, qr/\.foo\s+unhandled/, 'detail shows the path with its group' );
  is( $rc, 0, 'successful lookup exits 0' );
}

{
  my ( $out, $rc ) = run_audit('vim');
  like( $out, qr/NEW-XDG-ADVICE/, 'overlay override wins over stale upstream' );
  unlike( $out, qr/OLD-UPSTREAM-ADVICE/, 'stale upstream help is not shown when overridden' );
}

# A detail view shows ignored paths too (marked), and does not crash.
{
  my ( $out, $rc ) = run_audit('secret');
  like( $out, qr/\.secretdir\s+ignored/, 'ignored paths appear in the detail, marked' );
  unlike( $out, qr/uninitialized/, 'no uninitialized-value warnings for an all-ignored app' );
  is( $rc, 0, 'all-ignored app lookup exits 0' );
}

# A detail view appends the ignore reason when one is recorded.
{
  my ($out) = run_audit('reasoned');
  like( $out, qr/\.reasoned\s+ignored \(left in place\) - left because tests/, 'detail shows the ignore reason' );
}

# An exact app name shows that app, even when it is a prefix of others.
{
  my ( $out, $rc ) = run_audit('net');
  like( $out, qr/^net\s+\(/m, 'exact app name jumps to its detail' );
  unlike( $out, qr/Multiple apps/, 'exact match is not diluted by fragment matches (network)' );
  is( $rc, 0, 'exact-name lookup exits 0' );
}

# An override that omits help backfills it from the upstream entry.
{
  my ( $out, $rc ) = run_audit('docker');
  like( $out, qr/UPSTREAM-DOCKER-HELP/, 'override backfills upstream help in the detail' );
}

# ------------------------------------------------------------------------------
# Reverse-path lookup + search
# ------------------------------------------------------------------------------

{
  my ( $out, $rc ) = run_audit('.docker');
  like( $out, qr/docker/, 'reverse path lookup maps $HOME/.docker to docker' );
  is( $rc, 0, 'reverse lookup with a match exits 0' );
}

{
  my ( $out, $rc ) = run_audit( '--search', 'UPSTREAM-DOCKER' );
  like( $out, qr/docker/, 'search reaches (backfilled) help text' );
}

# ------------------------------------------------------------------------------
# Clean home → no findings, exit 0
# ------------------------------------------------------------------------------

{
  my $clean = File::Spec->catdir( $root, 'clean-home' );
  make_path($clean);
  my $pid = open( my $fh, '-|', $^X, $SCRIPT, '--db', $db, '--home', $clean );
  local $/;
  my $out = <$fh> // '';
  close $fh;
  my $rc = $? >> 8;
  like( $out, qr/Nothing to report/, 'clean home reports nothing to do' );
  is( $rc, 0, 'clean home exits 0' );
}

# ------------------------------------------------------------------------------
# Index build + auto-rebuild on stale sources
# ------------------------------------------------------------------------------

{
  my $idx = File::Spec->catfile( $db, '.index.json' );
  run_audit();                                   # builds the index
  ok( -f $idx, 'scan builds the enriched index cache' );

  # Add a new program AFTER the index exists, mark it newer than the index, and
  # confirm the next run rebuilds and picks it up (content check — robust to
  # 1-second mtime resolution).
  write_json( prog('bar'),
    { name => 'bar', files => [ { path => '$HOME/.bar', movable => JSON::PP::true, help => "b\n" } ] } );
  my $future = time + 5;
  utime( $future, $future, prog('bar') ) or die "utime: $!";
  utime( $future, $future, File::Spec->catdir( $db, 'programs' ) ) or die "utime: $!";

  run_audit();
  my $doc  = JSON::PP->new->decode( do { open my $fh, '<', $idx or die; local $/; <$fh> } );
  my %seen = map { $_->{name} => 1 } @{ $doc->{entries} };
  ok( $seen{bar}, 'index auto-rebuilds and picks up a newly-added program' );
}

# ------------------------------------------------------------------------------
# --reindex
# ------------------------------------------------------------------------------

{
  my ( $data, $rc, $out ) = run_json('--reindex');
  ok( defined $data->{reindexed} && $data->{reindexed} >= 4, '--reindex reports entries indexed' );
  is( $rc, 0, '--reindex exits 0' );
}

# ------------------------------------------------------------------------------
# Ambiguity-driven lookup: one app -> detail, several apps -> list
# ------------------------------------------------------------------------------

# A fragment matching a single app (with several files) shows that app's detail.
{
  my ( $out, $rc ) = run_audit('big');
  like( $out, qr/Big App/, 'fragment matching one app shows its detail' );
  like( $out, qr/\.big\b/, 'detail lists .big' );
  like( $out, qr/\.big\.json/, 'detail lists .big.json' );
  unlike( $out, qr/Multiple apps/, 'a single app is not rendered as a list' );
  unlike( $out, qr{\Q$home\E}, 'detail omits the $HOME prefix' );
  is( $rc, 0, 'single-app fragment lookup exits 0' );
}

# A dotfile owned by two apps yields a per-app list, not a merged detail.
{
  my ( $out, $rc ) = run_audit('.shared');
  like( $out, qr/Multiple apps match/, 'a shared dotfile yields a multi-app list' );
  like( $out, qr/\btoola\b/, 'list includes toola' );
  like( $out, qr/\btoolb\b/, 'list includes toolb' );
  is( $rc, 0, 'multi-app lookup exits 0' );
}

# ------------------------------------------------------------------------------
# Symlinked dotfiles are reported as linked (with target), not as strays
# ------------------------------------------------------------------------------

{
  my ( $data, $rc ) = run_json();
  my %by = map { $_->{name} => $_ } @$data;
  is( $by{linky}{group}, 'linked', 'a symlinked dotfile groups as "linked"' );
  like( $by{linky}{link_target}, qr/other-repo/, 'the link target is reported' );
}

{
  my ($out) = run_audit('--all');
  like( $out, qr/^linked$/m, '--all scan has a linked group' );
  like( $out, qr/linky \(\.linkme\)\s+-> \S.* \(external\)/, 'the symlink row shows its target and "external" tag' );
}

# ------------------------------------------------------------------------------
# --remove : guarded deletion of a leftover (fixtures created late so they can
# not disturb the scan assertions above).
# ------------------------------------------------------------------------------

# A stray (present + env redirect active via FIXTURE_RM) to accept-delete.
write_json( locl('rmstray'),
  { name => 'rmstray', files => [ { path => '$HOME/.rmstray', movable => JSON::PP::true, help => "r\n", mechanism => 'env', env => 'FIXTURE_RM' } ] } );
my $rmstray = touch('.rmstray');

# A second stray, to decline (must be kept).
write_json( locl('rmkeep'),
  { name => 'rmkeep', files => [ { path => '$HOME/.rmkeep', movable => JSON::PP::true, help => "k\n", mechanism => 'env', env => 'FIXTURE_RM' } ] } );
my $rmkeep = touch('.rmkeep');

# An unhandled file (present, no redirect) -> refused, never deleted.
write_json( prog('rmunh'),
  { name => 'rmunh', files => [ { path => '$HOME/.rmunh', movable => JSON::PP::true, help => "u\n" } ] } );
my $rmunh = touch('.rmunh');

# A symlinked dotfile -> refused (managed link), symlink + target intact.
my $rmlink_target = File::Spec->catdir( $root, 'rmlink-target' );
make_path($rmlink_target);
my $rmlink = File::Spec->catfile( $home, '.rmlink' );
symlink( $rmlink_target, $rmlink ) or die "symlink: $!";
write_json( prog('rmlinky'),
  { name => 'rmlinky', files => [ { path => '$HOME/.rmlink', movable => JSON::PP::true, help => "l\n" } ] } );

# An eligible ('remove') entry that resolves OUTSIDE $HOME -> refused by the
# $HOME guard, the file untouched.
my $outside = File::Spec->catfile( $root, 'outside-home-file' );
open my $of, '>', $outside or die "outside: $!";
close $of;
write_json( locl('rmoutside'),
  { name => 'rmoutside', files => [ { path => $outside, movable => JSON::PP::false, help => "o\n", mechanism => 'remove' } ] } );

# A 'remove'-marked directory (with content) to accept-delete recursively.
my $rmdir = File::Spec->catdir( $home, '.rmdir' );
make_path($rmdir);
{ open my $fh, '>', File::Spec->catfile( $rmdir, 'inner' ) or die "inner: $!"; close $fh; }
write_json( locl('rmdirapp'),
  { name => 'rmdirapp', files => [ { path => '$HOME/.rmdir', movable => JSON::PP::false, help => "d\n", mechanism => 'remove' } ] } );

# Accept: delete the stray.
{
  my ( $out, $rc ) = run_audit_stdin( "y\n", '--remove', 'rmstray' );
  like( $out, qr/stray - a leftover file/, '--remove shows the leftover status before asking' );
  like( $out, qr/removed \Q$rmstray\E/,    '--remove reports the deletion' );
  ok( !-e $rmstray, 'accepted stray is deleted from $HOME' );
  is( $rc, 0, '--remove exits 0 on success' );
}

# Decline: keep the stray.
{
  my ( $out, $rc ) = run_audit_stdin( "n\n", '--remove', 'rmkeep' );
  ok( -e $rmkeep, 'declined stray is kept' );
  unlike( $out, qr/removed \Q$rmkeep\E/, 'nothing reported removed on decline' );
  is( $rc, 0, 'declining still exits 0' );
}

# Refuse an unhandled (un-redirected) file: it needs migration, not deletion.
{
  my ( $out, $rc ) = run_audit_stdin( "y\n", '--remove', 'rmunh' );
  like( $out, qr/unhandled - migrate it first/, 'unhandled file is refused with a pointer to migrate' );
  ok( -e $rmunh, 'refused unhandled file is kept even when confirmed' );
}

# Refuse a symlink: a managed link is never deleted or followed.
{
  my ( $out, $rc ) = run_audit_stdin( "y\n", '--remove', 'rmlinky' );
  like( $out, qr/linked \(managed symlink\) - not removed/, 'symlink is refused' );
  ok( -l $rmlink,        'the symlink itself is intact' );
  ok( -d $rmlink_target, 'the symlink target is intact' );
}

# Refuse a deletion that resolves outside $HOME (defense-in-depth guard).
{
  my ( $out, $rc ) = run_audit_stdin( "y\n", '--remove', 'rmoutside' );
  like( $out, qr/resolves outside \$HOME .* - refused/, 'an out-of-$HOME target is refused' );
  ok( -e $outside, 'the out-of-$HOME file is untouched' );
}

# Accept: delete a 'remove'-marked directory recursively.
{
  my ( $out, $rc ) = run_audit_stdin( "y\n", '--remove', 'rmdirapp' );
  like( $out, qr/remove - a leftover directory/, 'a directory leftover is identified as such' );
  ok( !-e $rmdir, 'accepted directory is removed recursively' );
}

# A --remove with no target names nothing to do.
{
  my ( $out, $rc ) = run_audit_stdin( q{}, '--remove' );
  is( $rc, 1, '--remove with no target exits 1' );
}

done_testing();
