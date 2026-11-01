#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Spec;
use Cwd;

use lib 'tests/perl/lib';
use TestPerltidyrcClean;

# Load the script
load_perltidyrc_clean();

my $script        = File::Spec->catfile( 'bin', 'perltidyrc-clean' );
my $test_data_dir = File::Spec->catdir( Cwd::getcwd(), 'tests', 'perl', 'data' );

# %cli is lexical to bin/perltidyrc-clean, so a test cannot read what the
# setters write. Tests 1-6 call them in-process for errors only; Tests 7 and
# 8 run the script with --keep-defaults / --add-missing-defaults and assert
# the effect of each flag the setter sets, one falsifier per flag.

# Test 1: Verify set_keep_defaults function exists and is callable
{
  ok( defined &set_keep_defaults, 'set_keep_defaults function is defined' );

  eval { set_keep_defaults(); };
  is( $@, "", 'set_keep_defaults can be called without error' );
}

# Test 2: Verify set_add_missing_defaults function exists and is callable
{
  ok( defined &set_add_missing_defaults, 'set_add_missing_defaults function is defined' );

  eval { set_add_missing_defaults(); };
  is( $@, "", 'set_add_missing_defaults can be called without error' );
}

# Test 3: set_keep_defaults can be called multiple times
{
  eval {
    set_keep_defaults();
    set_keep_defaults();
  };
  is( $@, "", 'set_keep_defaults can be called multiple times' );
}

# Test 4: set_add_missing_defaults can be called multiple times
{
  eval {
    set_add_missing_defaults();
    set_add_missing_defaults();
  };
  is( $@, "", 'set_add_missing_defaults can be called multiple times' );
}

# Test 5: Both functions can be called together
{
  eval {
    set_keep_defaults();
    set_add_missing_defaults();
  };
  is( $@, "", 'Both functions can be called together' );
}

# Test 6: Functions can be called in any order
{
  eval {
    set_add_missing_defaults();
    set_keep_defaults();
  };
  is( $@, "", 'Functions can be called in reverse order' );
}

# Test 7: --keep-defaults (set_keep_defaults) end to end
#
# set_keep_defaults sets drop_defaults=0 and keep_defaults=1, and leaves
# add_missing_defaults and condense alone (the POD: "Does not add missing
# defaults"; only --add-missing-defaults implies --no-condense).
# defaults-only.rc sets exactly two options, both Perl::Tidy defaults.
#
#   drop_defaults=0 left at 1   -> the default lines are dropped     -> red
#   keep_defaults=1 left at 0   -> lines lose the "#  default" mark  -> red
#   add_missing_defaults set    -> every other default is emitted    -> red
#   condense set to 0           -> the condensing note disappears    -> red
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'defaults-only.rc' );

  my $stdout    = `$script --rc $rc_file --keep-defaults 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--keep-defaults exits with code 0' );
  like( $stdout, qr/^--indent-columns=4\b/m,             '--keep-defaults does not drop a default option' );
  like( $stdout, qr/^--indent-columns=4\s+#  default$/m, '--keep-defaults marks a default option as default' );

  my @option_lines = $stdout =~ /^(--\S+)/mg;
  is_deeply(
    [ sort @option_lines ],
    [ '--indent-columns=4', '--maximum-line-length=80' ],
    '--keep-defaults emits only the options the file set (adds no missing defaults)'
  );

  # The three closing-*-indentation options are cti's whole expansion, so
  # with condensing on they are replaced by the abbreviation and noted. This
  # asserts that condensing ran; what it emits is
  # perltidyrc-clean-condense_equivalence.t's.
  my ( $fh, $condense_rc ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--closing-paren-indentation=1\n";
  print {$fh} "--closing-brace-indentation=1\n";
  print {$fh} "--closing-square-bracket-indentation=1\n";
  print {$fh} "--continuation-indentation=3\n";
  close $fh;

  my $condensed = `$script --rc $condense_rc --keep-defaults 2>&1`;
  like(
    $condensed, qr/^# NOTE: closing-paren-indentation condensed to /m,
    '--keep-defaults leaves condensing on'
  );
}

# Test 8: --add-missing-defaults (set_add_missing_defaults) end to end
#
# set_add_missing_defaults sets add_missing_defaults=1, drop_defaults=0,
# keep_defaults=1 and condense=0. custom.rc sets indent-columns=8,
# maximum-line-length=120 and brace-tightness=2, none of them defaults.
# continuation-indentation=2 and closing-paren-indentation=0 are Perl::Tidy
# defaults it does not set.
#
#   add_missing_defaults left at 0 -> continuation-indentation absent -> red
#   keep_defaults left at 0        -> added lines lose the mark       -> red
#   condense left at 1             -> closing-paren-indentation is
#                                     condensed into an abbreviation   -> red
#   drop_defaults left at 1        -> not observable here:
#                                     build_clean_opts returns before
#                                     reading it when add_missing is set
#
# The file's own value must win over the default it overlays, so a reversed
# merge in build_clean_opts (defaults over file) is red as well.
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my $stdout    = `$script --rc $rc_file --add-missing-defaults 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--add-missing-defaults exits with code 0' );
  like( $stdout, qr/^--continuation-indentation=2\b/m, '--add-missing-defaults adds a default the file did not set' );
  like(
    $stdout, qr/^--continuation-indentation=2\s+#  default$/m,
    '--add-missing-defaults marks an added default as default'
  );
  like( $stdout, qr/^--closing-paren-indentation=0\s/m, '--add-missing-defaults implies --no-condense' );
  unlike( $stdout, qr/condensed to/, '--add-missing-defaults writes no condensing notes' );
  like( $stdout, qr/^--indent-columns=8$/m, "--add-missing-defaults keeps the file's value, unmarked" );
  unlike( $stdout, qr/^--indent-columns=4/m, '--add-missing-defaults does not overlay a default on a set option' );
}

done_testing();
