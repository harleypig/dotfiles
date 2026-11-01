#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use lib 'tests/perl/lib';
use TestPerltidyrcClean;

# load_perltidyrc_clean() must load the functions without running the script
# (#666), so nothing it prints or reads depends on the host. The child's HOME
# holds a .perltidyrc, as a host's might.

my $home = tempdir( CLEANUP => 1 );
{
  my $rc = File::Spec->catfile( $home, '.perltidyrc' );
  open my $fh, '>', $rc or die "cannot write $rc: $!\n";
  print {$fh} "--indent-columns=7\n";
  close $fh or die "cannot close $rc: $!\n";
}

# Loads the script in a child with that HOME and no PERLTIDY, and returns its
# exit status and its stdout and stderr together.
sub run_loaded {
  local $ENV{HOME} = $home;
  delete local $ENV{PERLTIDY};
  my $program =
    'BEGIN { open STDERR, ">&", \*STDOUT or die } ' . "use lib 'tests/perl/lib'; use TestPerltidyrcClean; load_perltidyrc_clean();";
  open my $fh, '-|', $^X, '-e', $program or die "cannot run child: $!\n";
  my $output = do { local $/ = undef; <$fh> };
  close $fh;
  return ( $? >> 8, $output );
}

# Red if loading prints the usage text, or main() runs and prints a config
# dump or the no-parameters message.
{
  my ( $exit, $output ) = run_loaded();
  is( $exit,   0,   'loading exits 0' );
  is( $output, q{}, 'loading prints nothing' );
}

done_testing();
