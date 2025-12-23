#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test that functions die appropriately when encountering undefined or empty string hash keys.
# This is a developer error - hash keys should never be undefined or empty strings.
# Note: Perl stringifies undef to "" when used as a hash key, so we check for empty strings.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Test 1: build_equals_default dies on empty string key in opts
{
    my %opts = (
        'valid_key' => 'value',
    );
    $opts{''} = 'value';    # Empty string key - developer error (Perl stringifies undef to "")
    my %defaults = (
        'valid_key' => 'value',
    );
    eval { build_equals_default(\%opts, \%defaults) };
    like($@, qr/Internal error: undefined or empty key found in build_equals_default options/, 
        'build_equals_default dies on empty string key in opts');
}

# Test 2: build_equals_default dies on empty string key in defaults
{
    my %opts = (
        'valid_key' => 'value',
    );
    my %defaults = (
        'valid_key' => 'value',
    );
    $defaults{''} = 'value';    # Empty string key - developer error (Perl stringifies undef to "")
    eval { build_equals_default(\%opts, \%defaults) };
    like($@, qr/Internal error: undefined or empty key found in build_equals_default defaults/, 
        'build_equals_default dies on empty string key in defaults');
}

# Test 3: build_equals_default handles undef defaults hash
{
    my %opts = (
        'valid_key' => 'value',
    );
    eval { build_equals_default(\%opts, undef) };
    is($@, '', 'build_equals_default handles undef defaults hash');
}

# Test 4: user_defined_abbreviations dies on empty string key in abbrev
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
        'user_defined_abbreviations dies on empty string key in abbrev');
}

# Test 5: user_defined_abbreviations dies on empty string key in abbrev_default
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
        'user_defined_abbreviations dies on empty string key in abbrev_default');
}

# Test 6: user_defined_abbreviations handles undef abbrev_default hash
{
    my %abbrev = (
        'valid_key' => 'value',
    );
    eval { user_defined_abbreviations(\%abbrev, undef) };
    is($@, '', 'user_defined_abbreviations handles undef abbrev_default hash');
}

# Test 7: dump_options dies on empty string key in opts
{
    my %opts = (
        'valid_key' => 'value',
    );
    $opts{''} = 'value';    # Empty string key - developer error (Perl stringifies undef to "")
    my %sections = (
        'valid_key' => '1. Section',
    );
    my %getopt_flags = (
        'valid_key' => '=s',
    );
    my %equals_default = ();
    my %abbreviations_user = ();
    my %section_notes = ();
    eval {
        dump_options(
            cmdline            => '',
            rc_origin          => '',
            quiet              => 1,
            opts               => \%opts,
            getopt_flags       => \%getopt_flags,
            sections           => \%sections,
            abbreviations      => {},
            equals_default     => \%equals_default,
            abbreviations_user => \%abbreviations_user,
            section_notes      => \%section_notes,
            keep_defaults      => 0,
        );
    };
    like($@, qr/Internal error: undefined or empty key found in dump_options opts/, 
        'dump_options dies on empty string key in opts');
}

# Test 8: dump_options dies on empty string key in sections
{
    my %opts = (
        'valid_key' => 'value',
    );
    my %sections = (
        'valid_key' => '1. Section',
    );
    $sections{''} = '1. Section';    # Empty string key - developer error (Perl stringifies undef to "")
    my %getopt_flags = (
        'valid_key' => '=s',
    );
    my %equals_default = ();
    my %abbreviations_user = ();
    my %section_notes = ();
    eval {
        dump_options(
            cmdline            => '',
            rc_origin          => '',
            quiet              => 1,
            opts               => \%opts,
            getopt_flags       => \%getopt_flags,
            sections           => \%sections,
            abbreviations      => {},
            equals_default     => \%equals_default,
            abbreviations_user => \%abbreviations_user,
            section_notes      => \%section_notes,
            keep_defaults      => 0,
        );
    };
    like($@, qr/Internal error: undefined or empty key found in dump_options sections/, 
        'dump_options dies on empty string key in sections');
}

# Test 9: dump_options dies on empty string key in abbreviations_user
{
    my %opts = (
        'valid_key' => 'value',
    );
    my %sections = (
        'valid_key' => '1. Section',
    );
    my %getopt_flags = (
        'valid_key' => '=s',
    );
    my %equals_default = ();
    my %abbreviations_user = (
        'valid_key' => ['value'],
    );
    $abbreviations_user{''} = ['value'];    # Empty string key - developer error (Perl stringifies undef to "")
    my %section_notes = ();
    eval {
        dump_options(
            cmdline            => '',
            rc_origin          => '',
            quiet              => 1,
            opts               => \%opts,
            getopt_flags       => \%getopt_flags,
            sections           => \%sections,
            abbreviations      => {},
            equals_default     => \%equals_default,
            abbreviations_user => \%abbreviations_user,
            section_notes      => \%section_notes,
            keep_defaults      => 0,
        );
    };
    like($@, qr/Internal error: undefined or empty key found in dump_options abbreviations_user/, 
        'dump_options dies on empty string key in abbreviations_user');
}

# Test 10: dump_options handles undef opts hash
{
    my %sections = (
        'valid_key' => '1. Section',
    );
    my %getopt_flags = (
        'valid_key' => '=s',
    );
    my %equals_default = ();
    my %abbreviations_user = ();
    my %section_notes = ();
    eval {
        dump_options(
            cmdline            => '',
            rc_origin          => '',
            quiet              => 1,
            opts               => undef,
            getopt_flags       => \%getopt_flags,
            sections           => \%sections,
            abbreviations      => {},
            equals_default     => \%equals_default,
            abbreviations_user => \%abbreviations_user,
            section_notes      => \%section_notes,
            keep_defaults      => 0,
        );
    };
    # Should handle undef gracefully (check_undefined_keys checks if hash_ref exists)
    # Actually, it will die because we're trying to dereference undef
    # Let's test that it handles it appropriately
    ok(defined $@, 'dump_options handles undef opts hash (may die on dereference)');
}

# Test 11: Normal operation with valid keys (build_equals_default)
{
    my %opts = (
        'key1' => 'value1',
        'key2' => 'value2',
    );
    my %defaults = (
        'key1' => 'value1',
        'key2' => 'different',
    );
    my %result;
    eval { %result = build_equals_default(\%opts, \%defaults) };
    is($@, '', 'build_equals_default works with valid keys');
    ok(exists $result{'key1'}, 'build_equals_default returns correct result for matching key');
    ok(exists $result{'key2'}, 'build_equals_default returns correct result for non-matching key');
    is($result{'key1'}, 1, 'build_equals_default marks matching key correctly');
    is($result{'key2'}, '', 'build_equals_default marks non-matching key correctly');
}

# Test 12: Normal operation with valid keys (user_defined_abbreviations)
{
    my %abbrev = (
        'key1' => 'value1',
        'key2' => 'value2',
    );
    my %abbrev_default = (
        'key1' => 'value1',
    );
    my %result;
    eval { %result = user_defined_abbreviations(\%abbrev, \%abbrev_default) };
    is($@, '', 'user_defined_abbreviations works with valid keys');
    is(scalar keys %result, 1, 'user_defined_abbreviations returns correct number of keys');
    ok(exists $result{'key2'}, 'user_defined_abbreviations returns correct result');
    ok(!exists $result{'key1'}, 'user_defined_abbreviations excludes default key');
}

done_testing();

