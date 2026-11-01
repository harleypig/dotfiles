package TestPerltidyrcClean;

use strict;
use warnings;
use Exporter 'import';
use Test::More ();

our @EXPORT = qw(load_perltidyrc_clean);

# bin/perltidyrc-clean dies at load without Perl::Tidy, so every test of it
# would error rather than say why. Skip the whole file instead, at `use` time
# so a test file skips before its first assertion even when it calls
# load_perltidyrc_clean() later, or never (the files that only run the script
# use this module for this check alone). Inert where Perl::Tidy is installed,
# which CI's perl job guarantees, so there the tests still run.
if ( !eval { require Perl::Tidy; 1 } ) {
  Test::More::plan( skip_all => 'Perl::Tidy not installed (run `vmgr install perl`,'
      . ' or install the distro perltidy package); bin/perltidyrc-clean needs it' );
}

# Load bin/perltidyrc-clean's functions into main for testing. The script
# runs main() only when run as a program, so loading it prints nothing and
# reads no perltidyrc. Call it once at the top of each test file that tests
# the script's functions.
sub load_perltidyrc_clean {

  # do runs the file in the current package, and the tests call its
  # functions unqualified.
  package main; ## no critic (Modules::ProhibitMultiplePackages)
  do './bin/perltidyrc-clean';
  if ($@) {
    die "Failed to load script: $@";
  }

  # do returns undef for a file that loads but ends on a false value, so check
  # a function arrived instead.
  if ( !defined &is_true ) {
    die "Script loaded but functions not found\n";
  }

  return 1;
} ## end sub load_perltidyrc_clean

1;
