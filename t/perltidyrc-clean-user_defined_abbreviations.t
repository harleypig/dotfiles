#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the user_defined_abbreviations function from bin/perltidyrc-clean
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Test 1: Returns only abbreviations not in defaults
{
    my %abbrev = (
        'foo' => 'bar',
        'baz' => 'qux',
        'test' => 'value',
    );
    my %abbrev_default = (
        'baz' => 'qux',
        'other' => 'default',
    );
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    is(scalar keys %result, 2, 'Returns correct number of user-defined abbreviations');
    ok(exists $result{'foo'}, 'Includes abbreviation not in defaults');
    ok(exists $result{'test'}, 'Includes another abbreviation not in defaults');
    ok(!exists $result{'baz'}, 'Excludes abbreviation that is in defaults');
    is($result{'foo'}, 'bar', 'Preserves correct value for user-defined abbreviation');
    is($result{'test'}, 'value', 'Preserves correct value for another user-defined abbreviation');
}

# Test 2: Handles empty abbreviation hash
{
    my %abbrev = ();
    my %abbrev_default = (
        'foo' => 'bar',
        'baz' => 'qux',
    );
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    is(scalar keys %result, 0, 'Returns empty hash when input is empty');
}

# Test 3: Handles all abbreviations being defaults (returns empty)
{
    my %abbrev = (
        'foo' => 'bar',
        'baz' => 'qux',
    );
    my %abbrev_default = (
        'foo' => 'bar',
        'baz' => 'qux',
    );
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    is(scalar keys %result, 0, 'Returns empty hash when all abbreviations are defaults');
}

# Test 4: Handles empty defaults hash
{
    my %abbrev = (
        'foo' => 'bar',
        'baz' => 'qux',
    );
    my %abbrev_default = ();
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    is(scalar keys %result, 2, 'Returns all abbreviations when defaults are empty');
    ok(exists $result{'foo'}, 'Includes all user abbreviations when defaults empty');
    ok(exists $result{'baz'}, 'Includes all user abbreviations when defaults empty');
    is($result{'foo'}, 'bar', 'Preserves values when defaults empty');
    is($result{'baz'}, 'qux', 'Preserves values when defaults empty');
}

# Test 5: Handles both hashes empty
{
    my %abbrev = ();
    my %abbrev_default = ();
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    is(scalar keys %result, 0, 'Returns empty hash when both inputs are empty');
}

# Test 6: Handles key in defaults but with different value (excluded by key existence)
{
    my %abbrev = (
        'foo' => 'bar',
        'baz' => 'different_value',
    );
    my %abbrev_default = (
        'baz' => 'qux',
    );
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    is(scalar keys %result, 1, 'Excludes abbreviation if key exists in defaults, regardless of value');
    ok(exists $result{'foo'}, 'Includes abbreviation not in defaults');
    ok(!exists $result{'baz'}, 'Excludes abbreviation with different value if key exists in defaults');
}

# Test 7: Handles key in defaults but with same value
{
    my %abbrev = (
        'foo' => 'bar',
        'baz' => 'qux',
    );
    my %abbrev_default = (
        'baz' => 'qux',
    );
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    is(scalar keys %result, 1, 'Excludes abbreviation that matches default exactly');
    ok(exists $result{'foo'}, 'Includes abbreviation not in defaults');
    ok(!exists $result{'baz'}, 'Excludes abbreviation that matches default');
}

# Test 8: Handles undefined values in abbreviations
{
    my %abbrev = (
        'foo' => 'bar',
        'baz' => undef,
    );
    my %abbrev_default = (
        'test' => 'value',
    );
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    is(scalar keys %result, 2, 'Handles undefined values in abbreviations');
    ok(exists $result{'foo'}, 'Includes abbreviation with defined value');
    ok(exists $result{'baz'}, 'Includes abbreviation with undefined value');
    is($result{'foo'}, 'bar', 'Preserves defined value');
    ok(!defined $result{'baz'}, 'Preserves undefined value');
}

# Test 9: Handles undefined values in defaults (falsy check includes them)
{
    my %abbrev = (
        'foo' => 'bar',
        'baz' => undef,
    );
    my %abbrev_default = (
        'baz' => undef,
    );
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    # Note: The function checks truthiness, not key existence, so undef values
    # are not excluded even if they exist in defaults
    is(scalar keys %result, 2, 'Includes abbreviation with undefined value even if in defaults (falsy check)');
    ok(exists $result{'foo'}, 'Includes abbreviation not in defaults');
    ok(exists $result{'baz'}, 'Includes abbreviation with undefined value even if matches default (falsy check)');
}

# Test 10: Handles large number of abbreviations
{
    my %abbrev;
    my %abbrev_default;
    for my $i (1..100) {
        $abbrev{"key$i"} = "value$i";
    }
    for my $i (51..100) {
        $abbrev_default{"key$i"} = "value$i";
    }
    my %result = user_defined_abbreviations(\%abbrev, \%abbrev_default);
    is(scalar keys %result, 50, 'Handles large number of abbreviations correctly');
    ok(exists $result{'key1'}, 'Includes first user-defined abbreviation');
    ok(exists $result{'key50'}, 'Includes last user-defined abbreviation');
    ok(!exists $result{'key51'}, 'Excludes first default abbreviation');
    ok(!exists $result{'key100'}, 'Excludes last default abbreviation');
}

# Test 11: Dies on empty string key in abbrev (developer error)
{
    my %abbrev = (
        'valid_key' => 'value',
    );
    $abbrev{''} = 'value';    # Empty string key - developer error (Perl stringifies undef to "")
    my %abbrev_default = (
        'valid_key' => 'value',
    );
    eval { user_defined_abbreviations(\%abbrev, \%abbrev_default) };
    like($@, qr/Internal error: undefined or empty key found in user_defined_abbreviations abbreviations/, 
        'Dies on empty string key in abbrev');
}

# Test 12: Dies on empty string key in abbrev_default (developer error)
{
    my %abbrev = (
        'valid_key' => 'value',
    );
    my %abbrev_default = (
        'valid_key' => 'value',
    );
    $abbrev_default{''} = 'value';    # Empty string key - developer error (Perl stringifies undef to "")
    eval { user_defined_abbreviations(\%abbrev, \%abbrev_default) };
    like($@, qr/Internal error: undefined or empty key found in user_defined_abbreviations defaults/, 
        'Dies on empty string key in abbrev_default');
}

# Test 13: Handles undef abbrev_default hash reference
{
    my %abbrev = (
        'valid_key' => 'value',
    );
    eval { user_defined_abbreviations(\%abbrev, undef) };
    is($@, '', 'Handles undef abbrev_default hash reference');
}

done_testing();

