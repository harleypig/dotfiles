#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the build_equals_default function from bin/perltidyrc-clean
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Test 1: Identifies options that match defaults
{
    my %opts = (
        'indent-columns' => '4',
        'line-length'     => '80',
    );
    my %defaults = (
        'indent-columns' => '4',
        'line-length'     => '80',
        'other-option'    => 'value',
    );
    
    my %equals = build_equals_default(\%opts, \%defaults);
    
    ok($equals{'indent-columns'}, 'indent-columns matches default');
    ok($equals{'line-length'}, 'line-length matches default');
    is(scalar keys %equals, 2, 'Returns hash with correct number of keys');
}

# Test 2: Identifies options that do NOT match defaults
{
    my %opts = (
        'indent-columns' => '4',
        'line-length'     => '120',  # Different from default
    );
    my %defaults = (
        'indent-columns' => '4',
        'line-length'     => '80',
    );
    
    my %equals = build_equals_default(\%opts, \%defaults);
    
    ok($equals{'indent-columns'}, 'indent-columns matches default');
    ok(!$equals{'line-length'}, 'line-length does not match default');
}

# Test 3: Handles undefined values correctly
{
    my %opts = (
        'option1' => undef,
        'option2' => 'value',
    );
    my %defaults = (
        'option1' => undef,
        'option2' => 'value',
        'option3' => 'other',
    );
    
    my %equals = build_equals_default(\%opts, \%defaults);
    
    ok(!$equals{'option1'}, 'Undef option does not equal undef default');
    ok($equals{'option2'}, 'Defined option equals defined default');
}

# Test 4: Handles options not in defaults hash
{
    my %opts = (
        'known-option'   => 'value',
        'unknown-option' => 'value',
    );
    my %defaults = (
        'known-option' => 'value',
    );
    
    my %equals = build_equals_default(\%opts, \%defaults);
    
    ok($equals{'known-option'}, 'Known option matches default');
    ok(!exists $equals{'unknown-option'}, 'Unknown option not in result hash');
}

# Test 5: Compares string values correctly
{
    my %opts = (
        'numeric-str' => '42',
        'numeric-num' => 42,
    );
    my %defaults = (
        'numeric-str' => '42',
        'numeric-num' => '42',  # String default
    );
    
    my %equals = build_equals_default(\%opts, \%defaults);
    
    ok($equals{'numeric-str'}, 'String "42" equals string "42"');
    ok($equals{'numeric-num'}, 'Numeric 42 equals string "42" (string comparison)');
}

# Test 6: Handles empty opts hash
{
    my %opts = ();
    my %defaults = (
        'some-option' => 'value',
    );
    
    my %equals = build_equals_default(\%opts, \%defaults);
    
    is(scalar keys %equals, 0, 'Empty opts returns empty hash');
}

# Test 7: Handles empty defaults hash
{
    my %opts = (
        'option1' => 'value1',
        'option2' => 'value2',
    );
    my %defaults = ();
    
    my %equals = build_equals_default(\%opts, \%defaults);
    
    is(scalar keys %equals, 0, 'Empty defaults returns empty hash');
}

# Test 8: Returns hash with correct keys (only keys from opts)
{
    my %opts = (
        'option1' => 'value',
        'option2' => 'value',
    );
    my %defaults = (
        'option1' => 'value',
        'option2' => 'different',
        'option3' => 'value',  # Not in opts
    );
    
    my %equals = build_equals_default(\%opts, \%defaults);
    
    ok(exists $equals{'option1'}, 'option1 key exists');
    ok(exists $equals{'option2'}, 'option2 key exists');
    ok(!exists $equals{'option3'}, 'option3 not in result (not in opts)');
    is(scalar keys %equals, 2, 'Result hash only contains keys from opts');
}

done_testing();

