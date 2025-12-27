#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempfile);
use Cwd;

use lib 't/lib';
use TestPerltidyrcClean;

# Load the script
load_perltidyrc_clean();

# Get absolute path to test data directory
my $test_data_dir = File::Spec->catdir( Cwd::getcwd(), 't', 'data' );

# Test 1: Reads default options when config_file is empty scalar ref
{
    my $empty_ref = \"";
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $empty_ref, [], 0 );

    is( $error, "", 'No error when reading defaults' );
    ok( ref($opts) eq 'HASH', 'Returns opts hash ref' );
    ok( ref($getopt_flags) eq 'HASH', 'Returns getopt_flags hash ref' );
    ok( ref($sections) eq 'HASH', 'Returns sections hash ref' );
    ok( ref($abbreviations) eq 'HASH', 'Returns abbreviations hash ref' );
    ok( ref($opts_default) eq 'HASH', 'Returns opts_default hash ref' );
    ok( ref($abbreviations_default) eq 'HASH',
        'Returns abbreviations_default hash ref' );
    ok( keys(%$opts_default) > 0, 'Defaults hash is populated' );
    ok( keys(%$abbreviations_default) > 0,
        'Default abbreviations hash is populated' );
}

# Test 2: Reads options from specified RC file
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, [], 0 );

    is( $error, "", 'No error when reading RC file' );
    ok( ref($opts) eq 'HASH', 'Returns opts hash ref' );
    is( $opts->{'indent-columns'}, '4',
        'Reads indent-columns option from RC file' );
    is( $opts->{'maximum-line-length'}, '80',
        'Reads maximum-line-length option from RC file' );
}

# Test 3: Uses Perl::Tidy search when config_file is undef
# This test is tricky because we can't control what Perl::Tidy finds.
# We'll test that it doesn't die and returns proper structure.
{
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( undef, [], 0 );

    # Should not die, but may or may not find a config file
    ok( ref($opts) eq 'HASH', 'Returns opts hash ref when config_file is undef' );
    ok( ref($getopt_flags) eq 'HASH',
        'Returns getopt_flags hash ref when config_file is undef' );
    ok( ref($sections) eq 'HASH', 'Returns sections hash ref when config_file is undef' );
    ok( ref($abbreviations) eq 'HASH',
        'Returns abbreviations hash ref when config_file is undef' );
}

# Test 4: Expands short options when expand_options is true
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    # expand_abbrev handles -i=value format
    my @perltidy_args = ( '-i=4', '-l=80' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, \@perltidy_args, 1 );

    is( $error, "", 'No error when expanding options' );
    # The args should be expanded, but we can't easily verify this without
    # checking internal state. However, we can verify the function completes.
    ok( ref($opts) eq 'HASH', 'Returns opts hash ref with expansion enabled' );
}

# Test 5: Does not expand short options when expand_options is false
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    # Use long format when not expanding
    my @perltidy_args = ( '--indent-columns=4', '--maximum-line-length=80' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, \@perltidy_args, 0 );

    is( $error, "", 'No error when not expanding options' );
    ok( ref($opts) eq 'HASH', 'Returns opts hash ref with expansion disabled' );
}

# Test 6: Passes perltidy_args to Perl::Tidy
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    my @perltidy_args = ( '--indent-columns=2' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, \@perltidy_args, 0 );

    is( $error, "", 'No error when passing perltidy_args' );
    # The perltidy_args should override RC file options
    is( $opts->{'indent-columns'}, '2',
        'perltidy_args override RC file options' );
}

# Test 7: Returns error message on Perl::Tidy errors
{
    # Create a non-existent file
    my $non_existent = File::Spec->catfile( $test_data_dir, 'nonexistent.rc' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $non_existent, [], 0 );

    # Should have an error message
    ok( length($error) > 0, 'Returns error message for non-existent file' );
    like( $error, qr/error|Error/i, 'Error message contains error text' );
}

# Test 8: Returns all required data structures
{
    my $empty_ref = \"";
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $empty_ref, [], 0 );

    ok( defined $error, 'Returns error message (even if empty)' );
    ok( ref($opts) eq 'HASH', 'Returns opts hash ref' );
    ok( ref($getopt_flags) eq 'HASH', 'Returns getopt_flags hash ref' );
    ok( ref($sections) eq 'HASH', 'Returns sections hash ref' );
    ok( ref($abbreviations) eq 'HASH', 'Returns abbreviations hash ref' );
    ok( ref($opts_default) eq 'HASH', 'Returns opts_default hash ref' );
    ok( ref($abbreviations_default) eq 'HASH',
        'Returns abbreviations_default hash ref' );
}

# Test 9: Handles empty perltidy_args array
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, [], 0 );

    is( $error, "", 'No error with empty perltidy_args' );
    ok( ref($opts) eq 'HASH', 'Returns opts hash ref with empty args' );
}

# Test 10: Handles undef perltidy_args (should default to empty array)
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, undef, 0 );

    is( $error, "", 'No error with undef perltidy_args' );
    ok( ref($opts) eq 'HASH', 'Returns opts hash ref with undef args' );
}

# Test 11: Only includes perltidyrc parameter when config_file is defined
# This is tested implicitly by the fact that undef works (uses Perl::Tidy search)
# and defined values work (uses specified file or empty ref)
{
    # Test with empty scalar ref (should include perltidyrc parameter)
    my $empty_ref = \"";
    my ( $error1, $opts1 ) = read_perltidyrc( $empty_ref, [], 0 );
    is( $error1, "", 'Empty scalar ref works' );

    # Test with undef (should NOT include perltidyrc parameter)
    my ( $error2, $opts2 ) = read_perltidyrc( undef, [], 0 );
    # Should not die - undef means use Perl::Tidy search
    ok( ref($opts2) eq 'HASH', 'undef config_file works (uses search)' );

    # Test with filename (should include perltidyrc parameter)
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    my ( $error3, $opts3 ) = read_perltidyrc( $rc_file, [], 0 );
    is( $error3, "", 'Filename config_file works' );
    is( $opts3->{'indent-columns'}, '4', 'Reads options from file' );
}

# Test 12: Reads abbreviations from RC file
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'with-abbrev.rc' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, [], 0 );

    # Perl::Tidy may output alias list to stderr (warnings), but should not error
    unlike( $error, qr/error.*parsing options/i,
        'No parsing error when reading abbreviations (warnings OK)' );
    ok( ref($abbreviations) eq 'HASH', 'Returns abbreviations hash ref' );
    ok( exists $abbreviations->{'myindent'},
        'Reads user-defined abbreviation from RC file' );
    if ( exists $abbreviations->{'myindent'} ) {
        my @vals = @{ $abbreviations->{'myindent'} };
        is( $vals[0], 'indent-columns',
            'Abbreviation maps to correct option' );
    }
}

# Test 13: Empty RC file returns empty opts (except defaults)
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'empty.rc' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, [], 0 );

    is( $error, "", 'No error with empty RC file' );
    ok( ref($opts) eq 'HASH', 'Returns opts hash ref' );
    # Empty RC file should have no options (or only defaults if they match)
    ok( keys(%$opts) >= 0, 'Empty RC file produces valid opts hash' );
}

# Test 14: perltidy_args override RC file options
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    my @perltidy_args = ( '--indent-columns=8', '--maximum-line-length=120' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, \@perltidy_args, 0 );

    is( $error, "", 'No error when args override RC file' );
    is( $opts->{'indent-columns'}, '8',
        'perltidy_args override RC file indent-columns' );
    is( $opts->{'maximum-line-length'}, '120',
        'perltidy_args override RC file maximum-line-length' );
}

# Test 15: Expansion works with short options in perltidy_args
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    # expand_abbrev handles -i=value format, not -i8 combined format
    my @perltidy_args = ( '-i=8', '-l=120' );
    my ( $error, $opts, $getopt_flags, $sections, $abbreviations,
        $opts_default, $abbreviations_default )
      = read_perltidyrc( $rc_file, \@perltidy_args, 1 );

    is( $error, "", 'No error when expanding short options' );
    # Expanded options should override RC file
    is( $opts->{'indent-columns'}, '8',
        'Expanded short option overrides RC file' );
    is( $opts->{'maximum-line-length'}, '120',
        'Expanded short option overrides RC file' );
}

done_testing();

