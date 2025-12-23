#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the condense_options function from bin/perltidyrc-clean
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Test 1: Removes brace-specific options that equal brace-tightness
{
    my %opts = (
        'brace-tightness'              => '2',
        'block-brace-tightness'        => '2',
        'brace-vertical-tightness'     => '2',
        'brace-vertical-tightness-closing' => '2',
        'brace-follower-vertical-tightness' => '2',
        'block-brace-vertical-tightness' => '2',
    );
    my %sections = (
        'brace-tightness'              => '1. Section',
        'block-brace-tightness'        => '1. Section',
        'brace-vertical-tightness'     => '1. Section',
        'brace-vertical-tightness-closing' => '1. Section',
        'brace-follower-vertical-tightness' => '1. Section',
        'block-brace-vertical-tightness' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'brace-tightness'}, 'Keeps brace-tightness');
    ok(!exists $opts{'block-brace-tightness'}, 'Removes block-brace-tightness');
    ok(!exists $opts{'brace-vertical-tightness'}, 'Removes brace-vertical-tightness');
    ok(!exists $opts{'brace-vertical-tightness-closing'}, 'Removes brace-vertical-tightness-closing');
    ok(!exists $opts{'brace-follower-vertical-tightness'}, 'Removes brace-follower-vertical-tightness');
    ok(!exists $opts{'block-brace-vertical-tightness'}, 'Removes block-brace-vertical-tightness');
}

# Test 2: Adds section notes for removed brace options
{
    my %opts = (
        'brace-tightness'       => '2',
        'block-brace-tightness' => '2',
    );
    my %sections = (
        'brace-tightness'       => '1. Section',
        'block-brace-tightness' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 1, 'One section note added');
    like($section_notes{'1. Section'}->[0], qr/block-brace-tightness removed; equals brace-tightness/,
        'Section note contains correct message');
}

# Test 3: Doesn't remove brace-specific options that differ from brace-tightness
{
    my %opts = (
        'brace-tightness'       => '2',
        'block-brace-tightness' => '3',  # Different value
    );
    my %sections = (
        'brace-tightness'       => '1. Section',
        'block-brace-tightness' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'brace-tightness'}, 'Keeps brace-tightness');
    ok(exists $opts{'block-brace-tightness'}, 'Keeps block-brace-tightness when different');
    is($opts{'block-brace-tightness'}, '3', 'Preserves different value');
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No section note added for differing option');
}

# Test 4: Handles missing brace-tightness gracefully
{
    my %opts = (
        'block-brace-tightness' => '2',
    );
    my %sections = (
        'block-brace-tightness' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'block-brace-tightness'}, 'Keeps block-brace-tightness when brace-tightness missing');
    is($opts{'block-brace-tightness'}, '2', 'Preserves value when brace-tightness missing');
}

# Test 5: Removes continuation-indentation if equals indent-columns
{
    my %opts = (
        'indent-columns'           => '4',
        'continuation-indentation' => '4',
    );
    my %sections = (
        'indent-columns'           => '1. Section',
        'continuation-indentation' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'indent-columns'}, 'Keeps indent-columns');
    ok(!exists $opts{'continuation-indentation'}, 'Removes continuation-indentation when equal');
}

# Test 6: Adds section note for removed continuation-indentation
{
    my %opts = (
        'indent-columns'           => '4',
        'continuation-indentation' => '4',
    );
    my %sections = (
        'indent-columns'           => '1. Section',
        'continuation-indentation' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 1, 'One section note added');
    like($section_notes{'1. Section'}->[0], qr/continuation-indentation removed; equals indent-columns/,
        'Section note contains correct message');
}

# Test 7: Doesn't remove continuation-indentation if differs from indent-columns
{
    my %opts = (
        'indent-columns'           => '4',
        'continuation-indentation' => '8',  # Different value
    );
    my %sections = (
        'indent-columns'           => '1. Section',
        'continuation-indentation' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'indent-columns'}, 'Keeps indent-columns');
    ok(exists $opts{'continuation-indentation'}, 'Keeps continuation-indentation when different');
    is($opts{'continuation-indentation'}, '8', 'Preserves different value');
}

# Test 8: Handles missing indent-columns gracefully
{
    my %opts = (
        'continuation-indentation' => '4',
    );
    my %sections = (
        'continuation-indentation' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'continuation-indentation'}, 'Keeps continuation-indentation when indent-columns missing');
    is($opts{'continuation-indentation'}, '4', 'Preserves value when indent-columns missing');
}

# Test 9: Handles missing continuation-indentation gracefully
{
    my %opts = (
        'indent-columns' => '4',
    );
    my %sections = (
        'indent-columns' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'indent-columns'}, 'Keeps indent-columns when continuation-indentation missing');
    is($opts{'indent-columns'}, '4', 'Preserves value when continuation-indentation missing');
}

# Test 10: Handles undefined brace-specific option values
{
    my %opts = (
        'brace-tightness'       => '2',
        'block-brace-tightness' => undef,
    );
    my %sections = (
        'brace-tightness'       => '1. Section',
        'block-brace-tightness' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'brace-tightness'}, 'Keeps brace-tightness');
    ok(exists $opts{'block-brace-tightness'}, 'Keeps block-brace-tightness when undefined');
    ok(!defined $opts{'block-brace-tightness'}, 'Preserves undefined value');
}

# Test 11: Handles multiple brace-specific options with mixed values
{
    my %opts = (
        'brace-tightness'              => '2',
        'block-brace-tightness'        => '2',  # Equal - should be removed
        'brace-vertical-tightness'     => '3',  # Different - should be kept
        'brace-vertical-tightness-closing' => '2',  # Equal - should be removed
    );
    my %sections = (
        'brace-tightness'              => '1. Section',
        'block-brace-tightness'        => '1. Section',
        'brace-vertical-tightness'     => '1. Section',
        'brace-vertical-tightness-closing' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'brace-tightness'}, 'Keeps brace-tightness');
    ok(!exists $opts{'block-brace-tightness'}, 'Removes block-brace-tightness (equal)');
    ok(exists $opts{'brace-vertical-tightness'}, 'Keeps brace-vertical-tightness (different)');
    is($opts{'brace-vertical-tightness'}, '3', 'Preserves different value');
    ok(!exists $opts{'brace-vertical-tightness-closing'}, 'Removes brace-vertical-tightness-closing (equal)');
    is(scalar @{$section_notes{'1. Section'}}, 2, 'Two section notes added for removed options');
}

# Test 12: Handles empty opts hash
{
    my %opts = ();
    my %sections = ();
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    is(scalar keys %opts, 0, 'Empty opts hash remains empty');
}

# Test 13: Handles options not related to condensation
{
    my %opts = (
        'line-length' => '80',
        'indent-columns' => '4',
    );
    my %sections = (
        'line-length' => '1. Section',
        'indent-columns' => '1. Section',
    );
    my %section_notes = ();
    condense_options(\%opts, \%sections, \%section_notes);
    
    ok(exists $opts{'line-length'}, 'Keeps unrelated options');
    ok(exists $opts{'indent-columns'}, 'Keeps indent-columns when continuation-indentation missing');
    is($opts{'line-length'}, '80', 'Preserves unrelated option value');
}

done_testing();

