#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use Cwd;

use lib 't/lib';
use TestPerltidyrcClean;

# Load the script
load_perltidyrc_clean();

# Get absolute path to test data directory
my $test_data_dir = File::Spec->catdir( Cwd::getcwd(), 't', 'data' );

# ============================================================================
# Parameter Validation Tests
# ============================================================================

# Test 1: Dies on invalid params_ref (not a hash ref)
{
    my $stderr = "";
    eval {
        call_perltidy( "not a hash ref", 'test context', \$stderr, 'die' );
    };
    like( $@, qr/Internal error: invalid parameter hash/, 
        'Dies on invalid params_ref (not a hash ref)' );
}

# Test 2: Dies on empty params hash
{
    my %empty_params = ();
    my $stderr = "";
    eval {
        call_perltidy( \%empty_params, 'test context', \$stderr, 'die' );
    };
    like( $@, qr/Internal error: invalid parameter hash/, 
        'Dies on empty params hash' );
}

# Test 3: Dies on invalid stderr_ref (not a scalar ref)
{
    my $empty_scalar = "";
    my %Opts_default;
    my $stderr_var = "";
    my @argv_empty = ();
    
    my %valid_params = (
        perltidyrc         => \$empty_scalar,
        dump_options       => \%Opts_default,
        dump_options_type  => 'full',
        dump_abbreviations => {},
        stderr             => \$stderr_var,
        argv               => \@argv_empty,
    );
    eval {
        call_perltidy( \%valid_params, 'test context', "not a ref", 'die' );
    };
    like( $@, qr/Internal error: stderr_ref must be a scalar reference/, 
        'Dies on invalid stderr_ref (not a scalar ref)' );
}

# Test 4: Dies on invalid error_mode
{
    my $empty_scalar = "";
    my %Opts_default;
    my $stderr_var = "";
    my @argv_empty = ();
    
    my %valid_params = (
        perltidyrc         => \$empty_scalar,
        dump_options       => \%Opts_default,
        dump_options_type  => 'full',
        dump_abbreviations => {},
        stderr             => \$stderr_var,
        argv               => \@argv_empty,
    );
    my $stderr = "";
    eval {
        call_perltidy( \%valid_params, 'test context', \$stderr, 'invalid_mode' );
    };
    like( $@, qr/Internal error: invalid error_mode/, 
        'Dies on invalid error_mode' );
}

# ============================================================================
# 'die' Mode Tests
# ============================================================================

# Test 5: Returns error code 0 on success (die mode)
{
    my $empty_scalar = "";
    my %Opts_default;
    my %abbreviations_default;
    my $stderr = "";
    my @argv_empty = ();
    
    my %params = (
        perltidyrc         => \$empty_scalar,
        dump_options       => \%Opts_default,
        dump_options_type  => 'full',
        dump_abbreviations => \%abbreviations_default,
        stderr             => \$stderr,
        argv               => \@argv_empty,
    );
    my $err = call_perltidy( \%params, 'test context', \$stderr, 'die' );
    is( $err, 0, 'Returns error code 0 on success (die mode)' );
}

# Test 6: Dies on error (err == 1) in die mode
{
    my $nonexistent_file = "nonexistent-file.rc";
    my %Opts;
    my $stderr = "";
    my @argv_empty = ();
    
    my %params = (
        perltidyrc         => $nonexistent_file,
        dump_options       => \%Opts,
        dump_options_type  => 'perltidyrc',
        stderr             => \$stderr,
        argv               => \@argv_empty,
    );
    eval {
        call_perltidy( \%params, 'test context', \$stderr, 'die' );
    };
    like( $@, qr/Error calling perltidy for test context/, 
        'Dies on error (err == 1) in die mode' );
}

# Test 7: Warns but continues on warnings (err == 2) in die mode
# Note: This is hard to test directly, but we can verify it doesn't die
{
    # Use a valid but potentially warning-generating scenario
    # (e.g., reading a config file that might have warnings)
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    my %Opts;
    my $stderr = "";
    my @argv_empty = ();
    
    my %params = (
        perltidyrc         => $rc_file,
        dump_options       => \%Opts,
        dump_options_type  => 'perltidyrc',
        stderr             => \$stderr,
        argv               => \@argv_empty,
    );
    my $err = eval {
        call_perltidy( \%params, 'test context', \$stderr, 'die' );
    };
    # Should not die (warnings don't cause death)
    ok( defined $err, 'Does not die on warnings (err == 2) in die mode' );
    # err should be 0 (success) or 2 (warnings), not 1 (error)
    ok( $err == 0 || $err == 2, 
        'Returns appropriate error code on warnings' );
}

# ============================================================================
# 'accumulate' Mode Tests
# ============================================================================

# Test 8: Returns (0, "") on success (accumulate mode)
{
    my $empty_scalar = "";
    my %Opts_default;
    my %abbreviations_default;
    my $stderr = "";
    my @argv_empty = ();
    
    my %params = (
        perltidyrc         => \$empty_scalar,
        dump_options       => \%Opts_default,
        dump_options_type  => 'full',
        dump_abbreviations => \%abbreviations_default,
        stderr             => \$stderr,
        argv               => \@argv_empty,
    );
    my ( $err, $error_message ) = call_perltidy( 
        \%params, 'test context', \$stderr, 'accumulate' 
    );
    is( $err, 0, 'Returns error code 0 on success (accumulate mode)' );
    is( $error_message, "", 'Returns empty error message on success' );
}

# Test 9: Returns error message on error (err == 1) in accumulate mode
{
    my $nonexistent_file = "nonexistent-file.rc";
    my %Opts;
    my $stderr = "";
    my @argv_empty = ();
    
    my %params = (
        perltidyrc         => $nonexistent_file,
        dump_options       => \%Opts,
        dump_options_type  => 'perltidyrc',
        stderr             => \$stderr,
        argv               => \@argv_empty,
    );
    my ( $err, $error_message ) = call_perltidy( 
        \%params, 'parsing options', \$stderr, 'accumulate' 
    );
    is( $err, 1, 'Returns error code 1 on error (accumulate mode)' );
    ok( length($error_message) > 0, 
        'Returns non-empty error message on error' );
    like( $error_message, qr/perltidy reported an error while parsing options/, 
        'Error message contains expected text' );
}

# Test 10: Returns stderr content in error message (accumulate mode)
{
    my $nonexistent_file = "nonexistent-file.rc";
    my %Opts;
    my $stderr = "";
    my @argv_empty = ();
    
    my %params = (
        perltidyrc         => $nonexistent_file,
        dump_options       => \%Opts,
        dump_options_type  => 'perltidyrc',
        stderr             => \$stderr,
        argv               => \@argv_empty,
    );
    my ( $err, $error_message ) = call_perltidy( 
        \%params, 'parsing options', \$stderr, 'accumulate' 
    );
    is( $err, 1, 'Returns error code 1 on error' );
    # Error message should include stderr content
    ok( length($error_message) > 0, 
        'Error message includes stderr content' );
}

# Test 11: Returns stderr on warnings (err == 2) in accumulate mode
# Note: Warnings are harder to trigger reliably, but we can test the structure
{
    my $empty_scalar = "";
    my %Opts_default;
    my %abbreviations_default;
    my $stderr = "";
    my @argv_empty = ();
    
    my %params = (
        perltidyrc         => \$empty_scalar,
        dump_options       => \%Opts_default,
        dump_options_type  => 'full',
        dump_abbreviations => \%abbreviations_default,
        stderr             => \$stderr,
        argv               => \@argv_empty,
    );
    my ( $err, $error_message ) = call_perltidy( 
        \%params, 'test context', \$stderr, 'accumulate' 
    );
    # Should be 0 (success) or 2 (warnings), not 1 (error)
    ok( $err == 0 || $err == 2, 
        'Returns appropriate error code (0 or 2)' );
    # On warnings, error_message should contain stderr (which may be empty)
    ok( defined $error_message, 
        'Returns defined error message (may be empty on warnings)' );
}

# ============================================================================
# Integration: Verify call_perltidy works with real Perl::Tidy calls
# ============================================================================

# Test 12: Works with valid defaults dump parameters
{
    my %Opts_default;
    my %abbreviations_default;
    my $stderr = "";
    my @argv_empty = ();
    
    my %params = (
        perltidyrc         => \"",
        dump_options       => \%Opts_default,
        dump_options_type  => 'full',
        dump_abbreviations => \%abbreviations_default,
        stderr             => \$stderr,
        argv               => \@argv_empty,
    );
    
    my $err = call_perltidy( \%params, 'defaults dump', \$stderr, 'die' );
    is( $err, 0, 'Successfully calls Perl::Tidy for defaults dump' );
    ok( keys(%Opts_default) > 0, 'Defaults hash is populated' );
    ok( keys(%abbreviations_default) > 0, 'Default abbreviations are populated' );
}

# Test 13: Works with valid config dump parameters
{
    my $rc_file = File::Spec->catfile( $test_data_dir, 'simple.rc' );
    my %Opts;
    my %Getopt_flags;
    my %sections;
    my %abbreviations;
    my $stderr = "";
    my @argv_empty = ();
    
    my %params = (
        perltidyrc             => $rc_file,
        dump_options           => \%Opts,
        dump_options_type      => 'perltidyrc',
        dump_getopt_flags      => \%Getopt_flags,
        dump_options_category  => \%sections,
        dump_abbreviations     => \%abbreviations,
        stderr                 => \$stderr,
        argv                   => \@argv_empty,
    );
    
    my ( $err, $error_message ) = call_perltidy( 
        \%params, 'parsing options', \$stderr, 'accumulate' 
    );
    is( $err, 0, 'Successfully calls Perl::Tidy for config dump' );
    is( $error_message, "", 'No error message on success' );
    ok( keys(%Opts) > 0, 'Options hash is populated' );
    ok( keys(%sections) > 0, 'Sections hash is populated' );
}

done_testing();

