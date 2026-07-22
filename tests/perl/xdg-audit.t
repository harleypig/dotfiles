#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use IPC::Open2 qw(open2);
use IPC::Open3 qw(open3);
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
  delete local $ENV{DOTFILES};

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
  delete local $ENV{DOTFILES};

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

# Like run_audit_stdin, but applies a per-case env override (%$extra) around the
# run: a defined value sets the var (to a target path), an undef leaves it
# unset. --migrate tests need a redirect var set to a specific target in some
# cases and unset in others, which the fixed FIXTURE_RM cannot express.
sub run_audit_env {
  my ( $extra, $input, @args ) = @_;
  local $ENV{HOME} = $home;
  delete local $ENV{XDG_CONFIG_HOME};
  delete local $ENV{XDG_CACHE_HOME};
  delete local $ENV{XDG_DATA_HOME};
  delete local $ENV{XDG_STATE_HOME};
  delete local $ENV{XDG_AUDIT_HOME};
  delete local $ENV{DOTFILES};

  my %saved;
  for my $k ( keys %$extra ) {
    $saved{$k} = exists $ENV{$k} ? $ENV{$k} : undef;
    if   ( defined $extra->{$k} ) { $ENV{$k} = $extra->{$k} }
    else                          { delete $ENV{$k} }
  }

  my ( $out_fh, $in_fh );
  my $pid = open2( $out_fh, $in_fh, $^X, $SCRIPT, '--db', $db, '--home', $home, @args );
  print {$in_fh} $input;
  close $in_fh;
  local $/;
  my $out = <$out_fh> // '';
  close $out_fh;
  waitpid $pid, 0;
  my $rc = $? >> 8;

  for my $k ( keys %saved ) {
    if   ( defined $saved{$k} ) { $ENV{$k} = $saved{$k} }
    else                        { delete $ENV{$k} }
  }
  return ( $out, $rc );
} ## end sub run_audit_env

# Like run_audit but captures STDOUT and STDERR merged, so usage-error messages
# (argument validation prints to STDERR) can be asserted on. No stdin needed for
# the usage-error cases that use it.
sub run_audit_merged {
  my (@args) = @_;
  local $ENV{HOME} = $home;
  delete local $ENV{XDG_CONFIG_HOME};
  delete local $ENV{XDG_CACHE_HOME};
  delete local $ENV{XDG_DATA_HOME};
  delete local $ENV{XDG_STATE_HOME};
  delete local $ENV{XDG_AUDIT_HOME};
  delete local $ENV{DOTFILES};

  my $out_fh;
  my $pid = open3( my $in_fh, $out_fh, $out_fh, $^X, $SCRIPT, '--db', $db, '--home', $home, @args );
  close $in_fh;
  local $/;
  my $out = <$out_fh> // '';
  close $out_fh;
  waitpid $pid, 0;
  my $rc = $? >> 8;
  return ( $out, $rc );
} ## end sub run_audit_merged

# Slice 3 (--migrate symlink / --fix) drives the REAL bin/check-dotfiles, which
# reads $HOME/$DOTFILES from the environment and creates actual symlinks — so
# its tests use a DEDICATED, writable fixture $HOME + $DOTFILES pair ($h, $df)
# rather than the shared fixtures other tests assert against. Runs the script
# against them with canned STDIN, capturing STDOUT and STDERR merged (refusals
# print to STDERR; check-dotfiles' own chatter is captured by xdg-audit).
sub run_symlink {
  my ( $h, $df, $input, @args ) = @_;
  local $ENV{HOME}     = $h;
  local $ENV{DOTFILES} = $df;
  delete local $ENV{XDG_CONFIG_HOME};
  delete local $ENV{XDG_CACHE_HOME};
  delete local $ENV{XDG_DATA_HOME};
  delete local $ENV{XDG_STATE_HOME};
  delete local $ENV{XDG_AUDIT_HOME};

  my $out_fh;
  my $pid = open3( my $in_fh, $out_fh, $out_fh, $^X, $SCRIPT, '--db', $db, '--home', $h, @args );
  print {$in_fh} $input;
  close $in_fh;
  local $/;
  my $out = <$out_fh> // '';
  close $out_fh;
  waitpid $pid, 0;
  my $rc = $? >> 8;
  return ( $out, $rc );
} ## end sub run_symlink

# Like run_symlink, but applies a per-case env override (%$extra) around the run
# (as run_audit_env does): the env->symlink conversion needs both $DOTFILES set
# (for real check-dotfiles) and the redirect var set to locate the source file.
sub run_symlink_env {
  my ( $extra, $h, $df, $input, @args ) = @_;
  my %saved;
  for my $k ( keys %$extra ) {
    $saved{$k} = exists $ENV{$k} ? $ENV{$k} : undef;
    if   ( defined $extra->{$k} ) { $ENV{$k} = $extra->{$k} }
    else                          { delete $ENV{$k} }
  }

  my ( $out, $rc ) = run_symlink( $h, $df, $input, @args );

  for my $k ( keys %saved ) {
    if   ( defined $saved{$k} ) { $ENV{$k} = $saved{$k} }
    else                        { delete $ENV{$k} }
  }
  return ( $out, $rc );
} ## end sub run_symlink_env

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

# ------------------------------------------------------------------------------
# --migrate : guarded move of a present dotfile to its XDG rewrite target.
# Fixtures created late (as with --remove) so they can't disturb the scan
# assertions. Targets are absolute paths under $root (one filesystem, so the
# rename inside move_path succeeds); a nested target dir exercises make_path.
# ------------------------------------------------------------------------------

my $xdgdata = File::Spec->catdir( $root, 'xdgdata' );

sub mg_entry {
  my ( $name, %f ) = @_;
  write_json( locl($name),
    { name => $name, files => [ { path => "\$HOME/.$name", movable => JSON::PP::true, help => "m\n", %f } ] } );
  return;
}

# Clean move: env set to the exact target, target absent.
my $mg_tgt = File::Spec->catfile( $xdgdata, 'mgstray' );
mg_entry( 'mgstray', mechanism => 'env', env => 'FIXTURE_MG', rewrite => $mg_tgt );
my $mgstray = touch('.mgstray');

# Decline.
my $mgk_tgt = File::Spec->catfile( $xdgdata, 'mgkeep' );
mg_entry( 'mgkeep', mechanism => 'env', env => 'FIXTURE_MGK', rewrite => $mgk_tgt );
my $mgkeep = touch('.mgkeep');

# The ordering gate: redirect var not set.
my $mgu_tgt = File::Spec->catfile( $xdgdata, 'mgunset' );
mg_entry( 'mgunset', mechanism => 'env', env => 'FIXTURE_MG_UNSET', rewrite => $mgu_tgt );
my $mgunset = touch('.mgunset');

# Redirect var points somewhere other than the declared target.
my $mgm_tgt = File::Spec->catfile( $xdgdata, 'mgmm' );
mg_entry( 'mgmm', mechanism => 'env', env => 'FIXTURE_MG_MM', rewrite => $mgm_tgt );
my $mgmm = touch('.mgmm');

# Target already exists -> use --remove, don't clobber.
make_path($xdgdata);
my $mge_tgt = File::Spec->catfile( $xdgdata, 'mgexists' );
{ open my $fh, '>', $mge_tgt or die "mge: $!"; close $fh; }
mg_entry( 'mgexists', mechanism => 'env', env => 'FIXTURE_MG_EX', rewrite => $mge_tgt );
my $mgexists = touch('.mgexists');

# env mechanism but no rewrite declared.
mg_entry( 'mgnorw', mechanism => 'env', env => 'FIXTURE_MG_NR' );
my $mgnorw = touch('.mgnorw');

# Non-env mechanism (alias) -> out of scope for this cut.
mg_entry( 'mgalias', mechanism => 'alias', rewrite => File::Spec->catfile( $xdgdata, 'mgalias' ) );
touch('.mgalias');

# A symlinked dotfile -> refused (managed link).
my $mgl_tgt = File::Spec->catdir( $root, 'mglink-target' );
make_path($mgl_tgt);
my $mglink = File::Spec->catfile( $home, '.mglink' );
symlink( $mgl_tgt, $mglink ) or die "symlink: $!";
mg_entry( 'mglink', mechanism => 'env', env => 'FIXTURE_MG_LN', rewrite => File::Spec->catfile( $xdgdata, 'mglink' ) );

# A directory leftover, moved recursively (same filesystem).
my $mgd = File::Spec->catdir( $home, '.mgdir' );
make_path($mgd);
{ open my $fh, '>', File::Spec->catfile( $mgd, 'inner' ) or die "inner: $!"; close $fh; }
my $mgd_tgt = File::Spec->catfile( $xdgdata, 'mgdir' );
mg_entry( 'mgdir', mechanism => 'env', env => 'FIXTURE_MG_D', rewrite => $mgd_tgt );

# Source resolves outside $HOME (env set + value matches target) -> guarded.
my $mgo_src = File::Spec->catfile( $root, 'outside-mg' );
{ open my $fh, '>', $mgo_src or die "mgo: $!"; close $fh; }
my $mgo_tgt = File::Spec->catfile( $xdgdata, 'mgout' );
write_json( locl('mgoutside'),
  { name => 'mgoutside', files => [ { path => $mgo_src, movable => JSON::PP::true, help => "o\n", mechanism => 'env', env => 'FIXTURE_MG_OUT', rewrite => $mgo_tgt } ] } );

# Clean move accepted (redirect active) -> no export suggestion.
{
  my ( $out, $rc ) = run_audit_env( { FIXTURE_MG => $mg_tgt }, "y\n", '--migrate', 'env', 'mgstray' );
  like( $out, qr/move to \Q$mg_tgt\E/,             '--migrate shows the planned move' );
  like( $out, qr/migrated \Q$mgstray\E -> \Q$mg_tgt\E/, '--migrate reports the move' );
  ok( !-e $mgstray, 'source is gone from $HOME after migrate' );
  ok( -e $mg_tgt,   'file now exists at the XDG target' );
  unlike( $out, qr/\bexport /, 'an active redirect prints no export suggestion' );
  is( $rc, 0, '--migrate exits 0 on success' );
}

# Decline keeps the file.
{
  my ( $out, $rc ) = run_audit_env( { FIXTURE_MGK => $mgk_tgt }, "n\n", '--migrate', 'env', 'mgkeep' );
  ok( -e $mgkeep,   'declined file is kept' );
  ok( !-e $mgk_tgt, 'nothing written to the target on decline' );
  unlike( $out, qr/migrated \S+ ->/, 'no move reported on decline' );
}

# Redirect not active -> the file is still moved AND the exact export line is
# printed as a dual-audience suggestion (Phase 2 Slice 1's instruct-the-export).
{
  my ( $out, $rc ) = run_audit_env( {}, "y\n", '--migrate', 'env', 'mgunset' );
  like( $out, qr/move to \Q$mgu_tgt\E\s+\(redirect \$FIXTURE_MG_UNSET inactive/, 'an inactive redirect still plans the move, flagged' );
  like( $out, qr/export FIXTURE_MG_UNSET="\Q$mgu_tgt\E"/, 'the exact export line is printed' );
  like( $out, qr/BEFORE running mgunset again/, 'the ordering caveat is printed' );
  ok( !-e $mgunset, 'the file is moved even though the redirect was inactive' );
  ok( -e $mgu_tgt,  'the file now exists at the XDG target' );
  is( $rc, 0, 'inactive-redirect migrate exits 0' );
}

# Redirect points elsewhere than the declared target -> refused.
{
  my ( $out, $rc ) = run_audit_env( { FIXTURE_MG_MM => File::Spec->catfile( $root, 'elsewhere' ) }, "y\n", '--migrate', 'env', 'mgmm' );
  like( $out, qr/points at .* not the declared/, 'a mismatched redirect value is refused' );
  ok( -e $mgmm,     'file kept on a redirect mismatch' );
  ok( !-e $mgm_tgt, 'nothing moved on a redirect mismatch' );
}

# Target already exists -> refused, source untouched.
{
  my ( $out, $rc ) = run_audit_env( { FIXTURE_MG_EX => $mge_tgt }, "y\n", '--migrate', 'env', 'mgexists' );
  like( $out, qr/already exists.*use --remove/, 'an existing target is refused, pointing at --remove' );
  ok( -e $mgexists, 'source kept when the target already exists' );
}

# No rewrite declared -> refused.
{
  my ( $out, $rc ) = run_audit_env( { FIXTURE_MG_NR => 'x' }, "y\n", '--migrate', 'env', 'mgnorw' );
  like( $out, qr/no XDG target declared/, 'an entry with no rewrite is refused' );
  ok( -e $mgnorw, 'file kept when no target is declared' );
}

# Non-env mechanism -> out of scope.
{
  my ( $out, $rc ) = run_audit_env( {}, "y\n", '--migrate', 'env', 'mgalias' );
  like( $out, qr/recommended mechanism is alias, not env - not migrated/, 'a non-env recommended mechanism is refused' );
}

# A managed symlink (here, to a directory) with a mechanism:env entry now
# CONVERTS to an env redirect (Slice 2) rather than being refused: the link is
# dropped and its canonical target moved to the XDG target.
{
  my $mgl_xdg = File::Spec->catdir( $xdgdata, 'mglink' );
  my ( $out, $rc ) = run_audit_env( {}, "y\n", '--migrate', 'env', 'mglink' );
  like( $out, qr/convert symlink ->/,      'a managed symlink converts to env' );
  like( $out, qr/export FIXTURE_MG_LN=/,   'the export is instructed (redirect inactive)' );
  ok( !-e $mglink, 'the symlink is dropped after conversion' );
  ok( -d $mgl_xdg, 'the canonical directory moved to the XDG target' );
}

# Directory leftover moved recursively.
{
  my ( $out, $rc ) = run_audit_env( { FIXTURE_MG_D => $mgd_tgt }, "y\n", '--migrate', 'env', 'mgdir' );
  ok( !-e $mgd, 'source directory is gone after migrate' );
  ok( -e File::Spec->catfile( $mgd_tgt, 'inner' ), 'directory contents moved to the target' );
}

# Source outside $HOME -> guarded even with an active, matching redirect.
{
  my ( $out, $rc ) = run_audit_env( { FIXTURE_MG_OUT => $mgo_tgt }, "y\n", '--migrate', 'env', 'mgoutside' );
  like( $out, qr/resolves outside \$HOME .* refused/, 'an out-of-$HOME source is refused' );
  ok( -e $mgo_src, 'the out-of-$HOME file is untouched' );
}

# The reframed signature (Slice 2): --migrate now takes a REQUIRED mechanism
# positional (only 'env' implemented). Bare --migrate, an unknown mechanism (or
# the old bare 'app' syntax landing where the mechanism is now read), and a
# mechanism with no app are each a usage error.

# Bare --migrate: no mechanism -> usage error.
{
  my ( $out, $rc ) = run_audit_merged('--migrate');
  like( $out, qr/--migrate needs a target mechanism/, 'bare --migrate reports the missing mechanism' );
  is( $rc, 1, 'bare --migrate exits 1' );
}

# The old bare 'app' syntax: the app name is read as the mechanism, rejected
# with a message teaching the new signature.
{
  my ( $out, $rc ) = run_audit_merged( '--migrate', 'mgstray' );
  like( $out, qr/--migrate takes a target mechanism first/, 'the old bare-app syntax is taught the new signature' );
  like( $out, qr/'mgstray' is not one/,                     'the misread app name is named back' );
  is( $rc, 1, 'the old syntax exits 1' );
}

# A mechanism the CLI does not accept (alias) is refused; the message names the
# implemented set (env/symlink/recommended).
{
  my ( $out, $rc ) = run_audit_merged( '--migrate', 'alias', 'mgstray' );
  like( $out, qr/'alias' is not one/,                    'an unaccepted mechanism is refused' );
  like( $out, qr/'env', 'symlink', and 'recommended'/,   'the message names the implemented mechanisms' );
  is( $rc, 1, 'an unaccepted mechanism exits 1' );
}

# A mechanism with no app -> usage error.
{
  my ( $out, $rc ) = run_audit_merged( '--migrate', 'env' );
  like( $out, qr/--migrate env needs an app name/, 'env with no app reports the missing target' );
  is( $rc, 1, '--migrate env with no app exits 1' );
}

# ------------------------------------------------------------------------------
# Mechanism state (Slice 1 — reporting): the CURRENT (detected) mechanism vs the
# RECOMMENDED (declared) one, completeness sub-states, divergence, and owner.
# Fixtures added late (as with --remove/--migrate) so they can't disturb the
# scan assertions above.
# ------------------------------------------------------------------------------

# A symlink whose link-name is registered in the dotlinks file check-dotfiles
# reads -> complete; one that is not -> partial. $HOME/.dotlinks wins over
# $DOTFILES/dotlinks-default, so this is hermetic (the helpers unset $DOTFILES).
my $slink_reg_tgt = File::Spec->catdir( $root, 'slink-reg-target' );
make_path($slink_reg_tgt);
symlink( $slink_reg_tgt, File::Spec->catfile( $home, '.slinkreg' ) ) or die "symlink: $!";
write_json( locl('slinkreg'),
  { name => 'slinkreg', files => [ { path => '$HOME/.slinkreg', movable => JSON::PP::true, help => "s\n", mechanism => 'symlink', rewrite => '$DOTFILES/slinkreg' } ] } );

my $slink_loose_tgt = File::Spec->catdir( $root, 'slink-loose-target' );
make_path($slink_loose_tgt);
symlink( $slink_loose_tgt, File::Spec->catfile( $home, '.slinkloose' ) ) or die "symlink: $!";
write_json( locl('slinkloose'),
  { name => 'slinkloose', files => [ { path => '$HOME/.slinkloose', movable => JSON::PP::true, help => "s\n", mechanism => 'symlink', rewrite => '$DOTFILES/slinkloose' } ] } );

# The dotlinks file registers .slinkreg (explicit link-name form) but not
# .slinkloose; a comment line must be skipped.
{
  open my $fh, '>', File::Spec->catfile( $home, '.dotlinks' ) or die "dotlinks: $!";
  print {$fh} "# a comment\n\$DOTFILES/slinkreg .slinkreg\n";
  close $fh;
}

# A present real file whose RECOMMENDED mechanism is symlink but which is not a
# symlink -> current 'hardcoded', diverges from recommended; the detail line
# appends "(recommended: symlink)" and the implied "[owner: check-dotfiles]".
write_json( locl('divapp'),
  { name => 'divapp', files => [ { path => '$HOME/.divapp', movable => JSON::PP::true, help => "d\n", mechanism => 'symlink', rewrite => '$DOTFILES/divapp' } ] } );
touch('.divapp');

# An explicit `owner` annotation on a non-symlink entry -> round-trips
# independently of the symlink implication.
write_json( locl('ownedapp'),
  { name => 'ownedapp', files => [ { path => '$HOME/.ownedapp', movable => JSON::PP::true, help => "o\n", owner => 'some-manager' } ] } );
touch('.ownedapp');

# Detection + completeness + owner + divergence in the --json feed.
{
  my ( $data, $rc ) = run_json();
  my %by = map { $_->{name} => $_ } @$data;

  is( $by{slinkreg}{current_mechanism},    'symlink',           'a symlink reports current_mechanism symlink' );
  is( $by{slinkreg}{current_completeness}, 'complete',          'a registered symlink is complete' );
  is( $by{slinkreg}{owner},                'check-dotfiles',    'mechanism symlink implies owner check-dotfiles' );
  is( $by{slinkreg}{divergence},           'using recommended', 'a symlink on its recommended mechanism reads "using recommended"' );

  is( $by{slinkloose}{current_completeness}, 'partial', 'an unregistered symlink is partial' );

  is( $by{docker}{current_mechanism},      'env',      'an active env redirect reports current_mechanism env' );
  is( $by{docker}{current_completeness},   'leftover', 'a present env redirect is a leftover' );
  is( $by{cleanapp}{current_mechanism},    'env',      'an absent-but-redirected entry is current env' );
  is( $by{cleanapp}{current_completeness}, 'clean',    'a migrated env redirect is clean' );

  is( $by{foo}{current_mechanism}, 'hardcoded', 'a present unredirected file is hardcoded' );
  is( $by{foo}{divergence},        'using hardcoded', 'a hardcoded file with no recommendation reads "using hardcoded"' );

  is( $by{divapp}{current_mechanism},     'hardcoded', 'a symlink-recommended plain file is current hardcoded' );
  is( $by{divapp}{recommended_mechanism}, 'symlink',   'its recommended mechanism is symlink' );
  is( $by{divapp}{divergence}, 'using hardcoded, recommended symlink', 'divergence names both current and recommended' );

  is( $by{ownedapp}{owner},             'some-manager', 'an explicit owner annotation round-trips' );
  is( $by{ownedapp}{current_mechanism}, 'hardcoded',    'the owned present file is hardcoded' );

  my ($mystery) = grep { ( $_->{display} // '' ) eq '.mystery' } @$data;
  is( $mystery->{current_mechanism}, 'unknown', 'a db-less $HOME dotfile is current unknown' );

  # Regression: the existing group/status vocabulary is unchanged.
  is( $by{docker}{group}, 'stray',     'group vocabulary unchanged (docker stray)' );
  is( $by{foo}{group},    'unhandled', 'group vocabulary unchanged (foo unhandled)' );
}

# The detail view surfaces the divergence and the owner on the path line, while
# the group word still leads it (existing detail assertions rely on that).
{
  my ($out) = run_audit('divapp');
  like( $out, qr/\.divapp\s+unhandled \(recommended: symlink\) \[owner: check-dotfiles\]/,
    'detail appends "(recommended: X)" and "[owner: ...]" after the group word' );
}

# An aligned entry (env on its recommended env) appends nothing extra.
{
  my ($out) = run_audit('docker');
  unlike( $out, qr/recommended:/, 'an aligned entry shows no "(recommended: ...)" note' );
}

# ------------------------------------------------------------------------------
# Slice 3 — --migrate symlink + --fix: move a hardcoded dotfile into the repo,
# register it in a dotlinks file, and let the REAL bin/check-dotfiles create the
# $HOME symlink; register a loose symlink with --fix. A dedicated fixture
# $HOME + $DOTFILES pair keeps the real filesystem side effects isolated.
# ------------------------------------------------------------------------------

my $s3home = File::Spec->catdir( $root, 's3home' );
my $s3df   = File::Spec->catdir( $root, 's3df' );
make_path( $s3home, $s3df );
my $s3_dl = File::Spec->catfile( $s3home, '.dotlinks' );

# The literal token written into a dotlinks line (check-dotfiles envsubst-expands
# it); kept as a variable so it is never interpolated inside a match.
my $DOLLAR_DOTFILES = '$DOTFILES';

my $wr = sub { my ( $p, $c ) = @_; open my $fh, '>', $p or die "wr $p: $!"; print {$fh} $c; close $fh; return $p; };
my $rd = sub { my ($p) = @_; open my $fh, '<', $p or return ''; local $/; my $c = <$fh>; close $fh; return $c // ''; };

# Happy path: a hardcoded ~/.grok is moved into the repo, registered, and linked
# back by check-dotfiles. ~/.dotlinks pre-exists (the active file), so there is
# no bootstrap prompt — one 'y' confirms the move.
mg_entry( 'grok', mechanism => 'symlink', rewrite => '$DOTFILES/grok' );
{
  $wr->( $s3_dl, '' );
  $wr->( File::Spec->catfile( $s3home, '.grok' ), "grokcfg\n" );

  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--migrate', 'symlink', 'grok' );
  my $link = File::Spec->catfile( $s3home, '.grok' );
  my $repo = File::Spec->catfile( $s3df,   'grok' );
  is( $rc, 0, '--migrate symlink exits 0' );
  ok( -l $link, '~/.grok is now a symlink' );
  is( readlink($link), $repo, '~/.grok points at the repo copy' );
  is( $rd->($repo), "grokcfg\n", 'the file content moved into the repo' );
  like( $rd->($s3_dl), qr/\Q$DOLLAR_DOTFILES\E\/grok \.grok/, 'a dotlinks line was written (with the .grok link-name)' );
}

# The post-migrate state reports symlink / complete via --json.
{
  my ($out) = run_symlink( $s3home, $s3df, "", '--json', 'grok' );
  my $rec = JSON::PP->new->decode($out)->{files}[0];
  is( $rec->{current_mechanism},   'symlink',  'current mechanism is now symlink' );
  is( $rec->{current_completeness}, 'complete', 'registered symlink reports complete' );
}

# Bootstrap: no ~/.dotlinks -> offer to create it, seed from dotlinks-default.
# Input: create? y / seed? y / move? y.
mg_entry( 'boots', mechanism => 'symlink', rewrite => '$DOTFILES/boots' );
{
  unlink $s3_dl;
  $wr->( File::Spec->catfile( $s3df,   'dotlinks-default' ), "# seed\n\$DOTFILES/pre existing\n" );
  $wr->( File::Spec->catfile( $s3home, '.boots' ),           "b\n" );

  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\ny\ny\n", '--migrate', 'symlink', 'boots' );
  is( $rc, 0, 'bootstrap-seed migrate exits 0' );
  ok( -e $s3_dl, '~/.dotlinks was created' );
  like( $rd->($s3_dl), qr/# seed/,          'the created ~/.dotlinks was seeded from dotlinks-default' );
  like( $rd->($s3_dl), qr/\Q$DOLLAR_DOTFILES\E\/boots \.boots/, 'the new entry was appended to the seeded file' );
  ok( -l File::Spec->catfile( $s3home, '.boots' ), '~/.boots was linked' );
}

# Bootstrap empty: create? y / seed? n / move? y -> ~/.dotlinks holds only the
# new line, no seed content.
mg_entry( 'boote', mechanism => 'symlink', rewrite => '$DOTFILES/boote' );
{
  unlink $s3_dl;
  $wr->( File::Spec->catfile( $s3home, '.boote' ), "e\n" );

  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\nn\ny\n", '--migrate', 'symlink', 'boote' );
  is( $rc, 0, 'bootstrap-empty migrate exits 0' );
  unlike( $rd->($s3_dl), qr/# seed/, 'the empty-bootstrap ~/.dotlinks has no seed content' );
  like( $rd->($s3_dl), qr/\Q$DOLLAR_DOTFILES\E\/boote \.boote/, 'the new entry is the only line' );
}

# Decline bootstrap -> append to the shared, tracked dotlinks-default instead.
# Input: create ~/.dotlinks? n / append to default? y / move? y.
mg_entry( 'bootd', mechanism => 'symlink', rewrite => '$DOTFILES/bootd' );
{
  unlink $s3_dl;
  my $def = File::Spec->catfile( $s3df, 'dotlinks-default' );
  $wr->( $def, "# seed\n" );
  $wr->( File::Spec->catfile( $s3home, '.bootd' ), "d\n" );

  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "n\ny\ny\n", '--migrate', 'symlink', 'bootd' );
  is( $rc, 0, 'append-to-default migrate exits 0' );
  ok( !-e $s3_dl, '~/.dotlinks was NOT created when declined' );
  like( $rd->($def), qr/\Q$DOLLAR_DOTFILES\E\/bootd \.bootd/, 'the entry was appended to dotlinks-default' );
  ok( -l File::Spec->catfile( $s3home, '.bootd' ), '~/.bootd was linked from the default file' );
}

# Decline everything -> nothing happens, no ~/.dotlinks left behind.
mg_entry( 'bootn', mechanism => 'symlink', rewrite => '$DOTFILES/bootn' );
{
  unlink $s3_dl;
  unlink File::Spec->catfile( $s3df, 'dotlinks-default' );
  my $src = $wr->( File::Spec->catfile( $s3home, '.bootn' ), "n\n" );

  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "n\nn\n", '--migrate', 'symlink', 'bootn' );
  is( $rc, 0, 'declined migrate still exits 0' );
  ok( -f $src && !-l $src, 'the source is left as the original hardcoded file' );
  ok( !-e $s3_dl, 'no ~/.dotlinks was created on a full decline' );
}

# Refusals (no move, message shown). ~/.dotlinks present so no bootstrap prompt.
$wr->( $s3_dl, '' );

# No repo target declared.
mg_entry( 'norw', mechanism => 'symlink' );
{
  $wr->( File::Spec->catfile( $s3home, '.norw' ), "x\n" );
  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--migrate', 'symlink', 'norw' );
  like( $out, qr/no repo target declared/, 'an entry with no rewrite is refused' );
  ok( -f File::Spec->catfile( $s3home, '.norw' ), 'the file is untouched' );
}

# rewrite is not under $DOTFILES.
{
  my $outside = File::Spec->catfile( $root, 'not-in-df' );
  write_json( locl('offdf'),
    { name => 'offdf', files => [ { path => '$HOME/.offdf', movable => JSON::PP::true, help => "o\n", mechanism => 'symlink', rewrite => $outside } ] } );
  $wr->( File::Spec->catfile( $s3home, '.offdf' ), "o\n" );
  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--migrate', 'symlink', 'offdf' );
  like( $out, qr/is not under \$DOTFILES/, 'a rewrite outside $DOTFILES is refused' );
}

# Target already exists in the repo.
mg_entry( 'texists', mechanism => 'symlink', rewrite => '$DOTFILES/texists' );
{
  $wr->( File::Spec->catfile( $s3df,   'texists' ), "already\n" );
  $wr->( File::Spec->catfile( $s3home, '.texists' ), "x\n" );
  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--migrate', 'symlink', 'texists' );
  like( $out, qr/already exists - resolve by hand/, 'an existing repo target is refused' );
}

# Absent source -> nothing to migrate.
mg_entry( 'gone', mechanism => 'symlink', rewrite => '$DOTFILES/gone' );
{
  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--migrate', 'symlink', 'gone' );
  like( $out, qr/absent - nothing to migrate/, 'an absent source is refused' );
}

# env-current but the entry RECOMMENDS env (not symlink) -> --migrate symlink has
# nothing to convert. The rewrite target exists, so the redirect reads as active.
mg_entry( 'envc', mechanism => 'env', env => 'S3_ENVC', rewrite => '$DOTFILES/envc' );
{
  $wr->( File::Spec->catfile( $s3df,   'envc' ), "t\n" );
  $wr->( File::Spec->catfile( $s3home, '.envc' ), "e\n" );
  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--migrate', 'symlink', 'envc' );
  like( $out, qr/recommended mechanism is env, not symlink - nothing to convert/,
    'an env-recommended, env-current path is refused under --migrate symlink' );
}

# --fix on a loose (partial) symlink: register its current target, link unchanged.
mg_entry( 'loose', mechanism => 'symlink', rewrite => '$DOTFILES/loosetgt' );
{
  my $ltgt = $wr->( File::Spec->catfile( $s3df, 'loosetgt' ), "loose\n" );
  my $llnk = File::Spec->catfile( $s3home, '.loose' );
  unlink $llnk;
  symlink( $ltgt, $llnk ) or die "symlink: $!";
  $wr->( $s3_dl, '' );

  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--fix', 'loose' );
  is( $rc, 0, '--fix exits 0' );
  is( readlink($llnk), $ltgt, 'the loose symlink is unchanged' );
  like( $rd->($s3_dl), qr/\Q$DOLLAR_DOTFILES\E\/loosetgt \.loose/, '--fix registered the loose symlink' );

  my ($j) = run_symlink( $s3home, $s3df, "", '--json', 'loose' );
  is( JSON::PP->new->decode($j)->{files}[0]{current_completeness}, 'complete', 'the fixed symlink now reports complete' );
}

# --fix refuses a hardcoded path (use --migrate).
mg_entry( 'fixh', mechanism => 'symlink', rewrite => '$DOTFILES/fixh' );
{
  $wr->( File::Spec->catfile( $s3home, '.fixh' ), "h\n" );
  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--fix', 'fixh' );
  like( $out, qr/nothing to fix for a hardcoded setup - use --migrate/, '--fix refuses a hardcoded path' );
}

# --fix refuses an env leftover (use --remove). Rewrite target exists so the env
# redirect reads as active (current = env, with a $HOME leftover).
mg_entry( 'fixe', mechanism => 'env', env => 'S3_FIXE', rewrite => '$DOTFILES/fixe' );
{
  $wr->( File::Spec->catfile( $s3df,   'fixe' ), "t\n" );
  $wr->( File::Spec->catfile( $s3home, '.fixe' ), "e\n" );
  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--fix', 'fixe' );
  like( $out, qr/overlaps --remove - use --remove/, '--fix routes an env leftover to --remove' );
}

# Cleanup on failure: check-dotfiles cannot link (~/.nochecklinks) -> the move
# and the dotlinks line are both rolled back, leaving $HOME and the repo as they
# were.
mg_entry( 'rbk', mechanism => 'symlink', rewrite => '$DOTFILES/rbk' );
{
  $wr->( $s3_dl, '' );
  my $src = $wr->( File::Spec->catfile( $s3home, '.rbk' ), "keepme\n" );
  $wr->( File::Spec->catfile( $s3home, '.nochecklinks' ), '' );

  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--migrate', 'symlink', 'rbk' );
  like( $out, qr/did not create the link.*reverted/, 'a link failure is reported as reverted' );
  ok( -f $src && !-l $src, 'the source is restored as the original file' );
  is( $rd->($src), "keepme\n", 'the restored file keeps its content' );
  ok( !-e File::Spec->catfile( $s3df, 'rbk' ), 'the repo copy was removed on rollback' );
  is( $rd->($s3_dl), '', 'the dotlinks line was stripped on rollback' );
  unlink File::Spec->catfile( $s3home, '.nochecklinks' );
}

# --fix with no target -> usage error.
{
  my ( $out, $rc ) = run_audit_merged('--fix');
  like( $out, qr/--fix needs an app name/, '--fix with no target reports the missing target' );
  is( $rc, 1, '--fix with no target exits 1' );
}

# ------------------------------------------------------------------------------
# Phase 2 Slice 1 — --migrate recommended (resolve declared mechanism, dispatch)
# and the hardcoded->env "instruct-the-export" JSON surface. Fixtures added late.
# ------------------------------------------------------------------------------

# --migrate recommended routes to env: an env-recommended app with the redirect
# active migrates as --migrate env would (moves, no export suggestion).
my $rec_tgt = File::Spec->catfile( $xdgdata, 'recenv' );
mg_entry( 'recenv', mechanism => 'env', env => 'FIXTURE_REC', rewrite => $rec_tgt );
my $recenv_src = touch('.recenv');
{
  my ( $out, $rc ) = run_audit_env( { FIXTURE_REC => $rec_tgt }, "y\n", '--migrate', 'recommended', 'recenv' );
  like( $out, qr/migrated \Q$recenv_src\E -> \Q$rec_tgt\E/, '--migrate recommended routes to the env transition' );
  ok( !-e $recenv_src, 'the file moved via recommended->env' );
  is( $rc, 0, 'recommended->env exits 0' );
}

# --migrate recommended refuses a heterogeneous app (paths with differing
# recommended mechanisms) with a per-path breakdown.
{
  write_json( locl('rechet'),
    { name  => 'rechet',
      files => [
        { path => '$HOME/.rechet_e', movable => JSON::PP::true, help => "h\n", mechanism => 'env', env => 'FIXTURE_RH', rewrite => File::Spec->catfile( $xdgdata, 'rh' ) },
        { path => '$HOME/.rechet_s', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', rewrite => '$DOTFILES/rechet_s' },
      ],
    } );
  my ( $out, $rc ) = run_audit_merged( '--migrate', 'recommended', 'rechet' );
  like( $out, qr/owns paths with different recommended mechanisms/, 'a heterogeneous app is refused' );
  like( $out, qr/\.rechet_e\s+env/, 'the breakdown names the env path' );
  like( $out, qr/\.rechet_s\s+symlink/, 'the breakdown names the symlink path' );
  is( $rc, 1, 'a heterogeneous recommended exits 1' );
}

# --migrate recommended refuses an unimplementable recommendation (alias).
{
  write_json( locl('recalias'),
    { name => 'recalias', files => [ { path => '$HOME/.recalias', movable => JSON::PP::true, help => "h\n", mechanism => 'alias' } ] } );
  my ( $out, $rc ) = run_audit_merged( '--migrate', 'recommended', 'recalias' );
  like( $out, qr/recommended mechanism for recalias is 'alias', which --migrate cannot yet perform/, 'an alias recommendation is refused' );
  is( $rc, 1, 'an unimplementable recommended exits 1' );
}

# --migrate recommended refuses an entry with no declared mechanism.
{
  write_json( locl('recnone'),
    { name => 'recnone', files => [ { path => '$HOME/.recnone', movable => JSON::PP::true, help => "h\n" } ] } );
  my ( $out, $rc ) = run_audit_merged( '--migrate', 'recommended', 'recnone' );
  like( $out, qr/no recommended mechanism is declared for recnone/, 'a mechanism-less entry is refused' );
  is( $rc, 1, 'a mechanism-less recommended exits 1' );
}

# --migrate recommended with no app -> usage error.
{
  my ( $out, $rc ) = run_audit_merged( '--migrate', 'recommended' );
  like( $out, qr/--migrate recommended needs an app name/, 'recommended with no app reports the missing target' );
  is( $rc, 1, 'recommended with no app exits 1' );
}

# --migrate recommended routes to symlink: reuse the real-check-dotfiles harness
# so a symlink-recommended hardcoded file is migrated as --migrate symlink would.
{
  write_json( locl('recsym'),
    { name => 'recsym', files => [ { path => '$HOME/.recsym', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', rewrite => '$DOTFILES/recsym' } ] } );
  open my $fh, '>', File::Spec->catfile( $s3home, '.recsym' ) or die "recsym: $!";
  print {$fh} "rs\n";
  close $fh;
  open my $dl, '>', $s3_dl or die "dl: $!";
  close $dl;    # empty active dotlinks file

  my ( $out, $rc ) = run_symlink( $s3home, $s3df, "y\n", '--migrate', 'recommended', 'recsym' );
  is( $rc, 0, 'recommended->symlink exits 0' );
  ok( -l File::Spec->catfile( $s3home, '.recsym' ), '--migrate recommended routed to the symlink transition' );
}

# The hardcoded->env instruct-the-export step surfaces in --json as
# suggested_steps; an active (handled) env redirect has none.
mg_entry( 'recjson', mechanism => 'env', env => 'FIXTURE_RJ', rewrite => File::Spec->catfile( $xdgdata, 'recjson' ) );
touch('.recjson');
{
  my ($data) = run_json('recjson');    # redirect inactive -> hardcoded
  my $step = $data->{files}[0]{suggested_steps}[0];
  is( $step->{action},   'export',     'suggested_steps action is export' );
  is( $step->{variable}, 'FIXTURE_RJ', 'suggested_steps names the variable' );
  is( $step->{command}, 'export FIXTURE_RJ="' . File::Spec->catfile( $xdgdata, 'recjson' ) . '"', 'suggested_steps command is the exact export line' );
}
{
  my ($data) = run_json('docker');    # an active env redirect (FIXTURE_DOCKER_CONFIG set)
  is_deeply( $data->{files}[0]{suggested_steps}, [], 'an active env redirect has no suggested_steps' );
}

# An env-recommended entry with NO variable declared + inactive -> refused (we
# cannot name an export to instruct).
mg_entry( 'recnovar', mechanism => 'env', rewrite => File::Spec->catfile( $xdgdata, 'recnovar' ) );
my $recnovar_src = touch('.recnovar');
{
  my ( $out, $rc ) = run_audit_env( {}, "y\n", '--migrate', 'env', 'recnovar' );
  like( $out, qr/declares no variable - cannot instruct an export/, 'an env entry with no variable is refused' );
  ok( -e $recnovar_src, 'the file is kept when no export can be named' );
}

# ------------------------------------------------------------------------------
# Phase 2 Slice 2 — env<->symlink conversions. A dedicated fixture $HOME+$DOTFILES
# pair; the entry's DECLARED mechanism is the conversion target, the current
# ($HOME) state is the divergence being converged.
# ------------------------------------------------------------------------------

my $s2home = File::Spec->catdir( $root, 's2home' );
my $s2df   = File::Spec->catdir( $root, 's2df' );
my $s2xdg  = File::Spec->catdir( $root, 's2xdg' );
make_path( $s2home, $s2df, $s2xdg );
my $s2_dl = File::Spec->catfile( $s2home, '.dotlinks' );

# --- reporting: current_mechanism + suggested_steps for both divergences ---

# A mechanism:env entry whose $HOME path is a symlink -> current symlink,
# recommended env, an 'export' suggested step.
{
  my $c = $wr->( File::Spec->catfile( $s2df, 'rsym' ), "c\n" );
  symlink( $c, File::Spec->catfile( $s2home, '.rsym' ) ) or die "symlink: $!";
  write_json( locl('rsym'),
    { name => 'rsym', files => [ { path => '$HOME/.rsym', movable => JSON::PP::true, help => "h\n", mechanism => 'env', env => 'S2_RSYM', rewrite => File::Spec->catfile( $s2xdg, 'rsym' ) } ] } );

  my ($out) = run_symlink_env( { S2_RSYM => undef }, $s2home, $s2df, '', '--json', 'rsym' );
  my $r = JSON::PP->new->decode($out)->{files}[0];
  is( $r->{current_mechanism}, 'symlink',                 'a symlinked env-recommended path reports current symlink' );
  is( $r->{divergence},        'using symlink, recommended env', 'divergence names the symlink->env gap' );
  is( $r->{suggested_steps}[0]{action}, 'export',         'it suggests the export it will need' );
}

# A mechanism:symlink entry with an ACTIVE declared env var -> current env,
# recommended symlink, a 'remove-export' suggested step.
{
  my $src = $wr->( File::Spec->catfile( $s2xdg, 'renv-src' ), "c\n" );
  write_json( locl('renv'),
    { name => 'renv', files => [ { path => '$HOME/.renv', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', env => 'S2_RENV', rewrite => '$DOTFILES/renv' } ] } );

  my ($out) = run_symlink_env( { S2_RENV => $src }, $s2home, $s2df, '', '--json', 'renv' );
  my $r = JSON::PP->new->decode($out)->{files}[0];
  is( $r->{current_mechanism}, 'env',                      'a symlink-recommended path with an active env var reports current env' );
  is( $r->{divergence},        'using env, recommended symlink', 'divergence names the env->symlink gap' );
  is( $r->{suggested_steps}[0]{action},   'remove-export', 'it suggests removing the export' );
  is( $r->{suggested_steps}[0]{variable}, 'S2_RENV',       'the remove-export step names the variable' );

  # Same entry, var UNSET -> not detectable as env (documented limitation).
  my ($out2) = run_symlink_env( { S2_RENV => undef }, $s2home, $s2df, '', '--json', 'renv' );
  my $r2 = JSON::PP->new->decode($out2)->{files}[0];
  isnt( $r2->{current_mechanism}, 'env', 'an unexported redirect is not detected as env' );
  is_deeply( $r2->{suggested_steps}, [], 'no remove-export step without a live redirect' );
}

# --- symlink -> env conversion (--migrate env on a managed symlink) ---

# Happy path, redirect inactive: canonical moved to the XDG target, symlink and
# its dotlinks entry dropped, export instructed.
{
  my $canon = $wr->( File::Spec->catfile( $s2df, 'sev' ), "sevdata\n" );
  my $link  = File::Spec->catfile( $s2home, '.sev' );
  symlink( $canon, $link ) or die "symlink: $!";
  $wr->( $s2_dl, "$DOLLAR_DOTFILES/sev .sev\n" );
  my $tgt = File::Spec->catfile( $s2xdg, 'sev' );
  write_json( locl('sev'),
    { name => 'sev', files => [ { path => '$HOME/.sev', movable => JSON::PP::true, help => "h\n", mechanism => 'env', env => 'S2_SEV', rewrite => $tgt } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_SEV => undef }, $s2home, $s2df, "y\n", '--migrate', 'env', 'sev' );
  is( $rc, 0, 'symlink->env exits 0' );
  ok( !-e $link,  'the symlink is dropped' );
  ok( -e $tgt,    'the canonical file is at the XDG target' );
  is( $rd->($tgt), "sevdata\n", 'the content moved' );
  ok( !-e $canon, 'the repo copy is vacated (moved out)' );
  is( $rd->($s2_dl), '', 'the dotlinks entry was removed' );
  like( $out, qr/export S2_SEV="\Q$tgt\E"/, 'the export line is printed' );
}

# Redirect active & matching -> converts, but no export suggestion.
{
  my $canon = $wr->( File::Spec->catfile( $s2df, 'seva' ), "a\n" );
  symlink( $canon, File::Spec->catfile( $s2home, '.seva' ) ) or die "symlink: $!";
  $wr->( $s2_dl, '' );
  my $tgt = File::Spec->catfile( $s2xdg, 'seva' );
  write_json( locl('seva'),
    { name => 'seva', files => [ { path => '$HOME/.seva', movable => JSON::PP::true, help => "h\n", mechanism => 'env', env => 'S2_SEVA', rewrite => $tgt } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_SEVA => $tgt }, $s2home, $s2df, "y\n", '--migrate', 'env', 'seva' );
  ok( -e $tgt, 'an active-redirect symlink still converts (moves)' );
  unlike( $out, qr/\bexport /, 'an active matching redirect prints no export suggestion' );
}

# Redirect active & MISMATCHED -> refused, symlink + repo file intact.
{
  my $canon = $wr->( File::Spec->catfile( $s2df, 'sevm' ), "m\n" );
  my $link  = File::Spec->catfile( $s2home, '.sevm' );
  symlink( $canon, $link ) or die "symlink: $!";
  $wr->( $s2_dl, '' );
  write_json( locl('sevm'),
    { name => 'sevm', files => [ { path => '$HOME/.sevm', movable => JSON::PP::true, help => "h\n", mechanism => 'env', env => 'S2_SEVM', rewrite => File::Spec->catfile( $s2xdg, 'sevm' ) } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_SEVM => File::Spec->catfile( $root, 'elsewhere2' ) }, $s2home, $s2df, "y\n", '--migrate', 'env', 'sevm' );
  like( $out, qr/points at .* not the declared/, 'a mismatched active redirect is refused' );
  ok( -l $link,  'the symlink is intact' );
  ok( -e $canon, 'the repo file is intact' );
}

# Broken symlink (canonical missing) -> refused.
{
  my $link = File::Spec->catfile( $s2home, '.sevb' );
  symlink( File::Spec->catfile( $s2df, 'no-such-file' ), $link ) or die "symlink: $!";
  write_json( locl('sevb'),
    { name => 'sevb', files => [ { path => '$HOME/.sevb', movable => JSON::PP::true, help => "h\n", mechanism => 'env', env => 'S2_SEVB', rewrite => File::Spec->catfile( $s2xdg, 'sevb' ) } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_SEVB => undef }, $s2home, $s2df, "y\n", '--migrate', 'env', 'sevb' );
  like( $out, qr/broken symlink \(target missing\)/, 'a broken symlink is refused' );
}

# A symlink whose entry recommends something other than env -> refined refusal.
{
  my $canon = $wr->( File::Spec->catfile( $s2df, 'sevn' ), "n\n" );
  symlink( $canon, File::Spec->catfile( $s2home, '.sevn' ) ) or die "symlink: $!";
  write_json( locl('sevn'),
    { name => 'sevn', files => [ { path => '$HOME/.sevn', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', rewrite => '$DOTFILES/sevn' } ] } );

  my ( $out, $rc ) = run_symlink_env( {}, $s2home, $s2df, "y\n", '--migrate', 'env', 'sevn' );
  like( $out, qr/linked \(managed symlink\), recommended symlink not env/, 'a non-env symlink is refused under --migrate env' );
}

# Cleanup on failure: the dotlinks removal fails (read-only file) -> the symlink
# is recreated and the file moved back. Skipped as root (perms ignored).
SKIP: {
  skip 'runs as root (file perms ignored)', 3 if $> == 0;
  my $canon = $wr->( File::Spec->catfile( $s2df, 'sevr' ), "r\n" );
  my $link  = File::Spec->catfile( $s2home, '.sevr' );
  symlink( $canon, $link ) or die "symlink: $!";
  $wr->( $s2_dl, "$DOLLAR_DOTFILES/sevr .sevr\n" );
  chmod 0444, $s2_dl;
  my $tgt = File::Spec->catfile( $s2xdg, 'sevr' );
  write_json( locl('sevr'),
    { name => 'sevr', files => [ { path => '$HOME/.sevr', movable => JSON::PP::true, help => "h\n", mechanism => 'env', env => 'S2_SEVR', rewrite => $tgt } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_SEVR => undef }, $s2home, $s2df, "y\n", '--migrate', 'env', 'sevr' );
  like( $out, qr/could not update .* reverted/, 'a dotlinks-removal failure reports revert' );
  ok( -l $link,  'the symlink is recreated on rollback' );
  ok( -e $canon, 'the repo file is moved back on rollback' );
  chmod 0644, $s2_dl;
}

# --- env -> symlink conversion (--migrate symlink on an env-redirected path) ---

# Happy path (real check-dotfiles): source moved into the repo, linked, export
# instructed for removal.
{
  my $src = $wr->( File::Spec->catfile( $s2xdg, 'esrc' ), "esdata\n" );
  $wr->( $s2_dl, '' );
  write_json( locl('esym'),
    { name => 'esym', files => [ { path => '$HOME/.esym', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', env => 'S2_ESYM', rewrite => '$DOTFILES/esym' } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_ESYM => $src }, $s2home, $s2df, "y\n", '--migrate', 'symlink', 'esym' );
  my $link = File::Spec->catfile( $s2home, '.esym' );
  my $repo = File::Spec->catfile( $s2df,   'esym' );
  is( $rc, 0, 'env->symlink exits 0' );
  ok( -l $link, '~/.esym is now a symlink' );
  is( readlink($link), $repo, 'it points at the repo copy' );
  is( $rd->($repo), "esdata\n", 'the file moved into the repo' );
  ok( !-e $src, 'the env-redirect source was moved out' );
  like( $rd->($s2_dl), qr/\Q$DOLLAR_DOTFILES\E\/esym \.esym/, 'a dotlinks entry was written' );
  like( $out, qr/unset S2_ESYM/, 'the remove-export instruction is printed' );
}

# A $HOME leftover blocks the link -> refused.
{
  my $src = $wr->( File::Spec->catfile( $s2xdg, 'elsrc' ), "x\n" );
  $wr->( File::Spec->catfile( $s2home, '.eleft' ), "leftover\n" );    # blocks the link
  $wr->( $s2_dl, '' );
  write_json( locl('eleft'),
    { name => 'eleft', files => [ { path => '$HOME/.eleft', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', env => 'S2_ELEFT', rewrite => '$DOTFILES/eleft' } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_ELEFT => $src }, $s2home, $s2df, "y\n", '--migrate', 'symlink', 'eleft' );
  like( $out, qr/leftover.*blocks the link - --remove it first/, 'a $HOME leftover is refused' );
  ok( -e $src, 'nothing moved when the link is blocked' );
}

# The redirect target no longer exists -> refused.
{
  $wr->( $s2_dl, '' );
  write_json( locl('egone'),
    { name => 'egone', files => [ { path => '$HOME/.egone', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', env => 'S2_EGONE', rewrite => '$DOTFILES/egone' } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_EGONE => File::Spec->catfile( $s2xdg, 'missing' ) }, $s2home, $s2df, "y\n", '--migrate', 'symlink', 'egone' );
  like( $out, qr/which does not exist - nothing to move/, 'a missing redirect target is refused' );
}

# Cleanup on failure: check-dotfiles cannot link (~/.nochecklinks) -> full
# rollback (source restored, repo copy removed, dotlinks line stripped).
{
  my $src = $wr->( File::Spec->catfile( $s2xdg, 'ercsrc' ), "keep\n" );
  $wr->( $s2_dl, '' );
  $wr->( File::Spec->catfile( $s2home, '.nochecklinks' ), '' );
  write_json( locl('erc'),
    { name => 'erc', files => [ { path => '$HOME/.erc', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', env => 'S2_ERC', rewrite => '$DOTFILES/erc' } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_ERC => $src }, $s2home, $s2df, "y\n", '--migrate', 'symlink', 'erc' );
  like( $out, qr/did not create the link.*reverted/, 'a link failure reports revert' );
  ok( -e $src, 'the source is restored on rollback' );
  is( $rd->($src), "keep\n", 'the restored source keeps its content' );
  ok( !-e File::Spec->catfile( $s2df, 'erc' ), 'the repo copy was removed on rollback' );
  is( $rd->($s2_dl), '', 'the dotlinks line was stripped on rollback' );
  unlink File::Spec->catfile( $s2home, '.nochecklinks' );
}

# --- --migrate recommended routes the conversions; --fix refuses them ---

# recommended on a symlink-current mechanism:env entry converts (symlink->env).
{
  my $canon = $wr->( File::Spec->catfile( $s2df, 'recs' ), "rc\n" );
  symlink( $canon, File::Spec->catfile( $s2home, '.recs' ) ) or die "symlink: $!";
  $wr->( $s2_dl, '' );
  my $tgt = File::Spec->catfile( $s2xdg, 'recs' );
  write_json( locl('recs'),
    { name => 'recs', files => [ { path => '$HOME/.recs', movable => JSON::PP::true, help => "h\n", mechanism => 'env', env => 'S2_RECS', rewrite => $tgt } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_RECS => undef }, $s2home, $s2df, "y\n", '--migrate', 'recommended', 'recs' );
  ok( !-e File::Spec->catfile( $s2home, '.recs' ), '--migrate recommended converted symlink->env' );
  ok( -e $tgt, 'the file reached the XDG target via recommended' );
}

# recommended on an env-current mechanism:symlink+env entry converts (env->symlink).
{
  my $src = $wr->( File::Spec->catfile( $s2xdg, 'recesrc' ), "re\n" );
  $wr->( $s2_dl, '' );
  write_json( locl('rece'),
    { name => 'rece', files => [ { path => '$HOME/.rece', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', env => 'S2_RECE', rewrite => '$DOTFILES/rece' } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_RECE => $src }, $s2home, $s2df, "y\n", '--migrate', 'recommended', 'rece' );
  ok( -l File::Spec->catfile( $s2home, '.rece' ), '--migrate recommended converted env->symlink' );
}

# --fix must NOT convert: a symlink-recommended, env-current path points at
# --migrate, it does not convert under --fix.
{
  my $src = $wr->( File::Spec->catfile( $s2xdg, 'fxsrc' ), "fx\n" );
  write_json( locl('fxc'),
    { name => 'fxc', files => [ { path => '$HOME/.fxc', movable => JSON::PP::true, help => "h\n", mechanism => 'symlink', env => 'S2_FXC', rewrite => '$DOTFILES/fxc' } ] } );

  my ( $out, $rc ) = run_symlink_env( { S2_FXC => $src }, $s2home, $s2df, "y\n", '--fix', 'fxc' );
  like( $out, qr/using env, recommended symlink - run --migrate symlink/, '--fix points an env->symlink divergence at --migrate' );
  ok( -e $src && !-l File::Spec->catfile( $s2home, '.fxc' ), '--fix did not convert' );
}

done_testing();
