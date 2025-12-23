#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the detect_conflicts function from bin/perltidyrc-clean
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Test 1: Detects conflict between brace-left-and-indent and non-indenting-braces
{
    my %opts = (
        'brace-left-and-indent' => '1',
        'non-indenting-braces'  => '1',
    );
    my %sections = (
        'brace-left-and-indent' => '1. Section',
        'non-indenting-braces'  => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 1, 'One conflict note added');
    like($section_notes{'1. Section'}->[0], qr/brace-left-and-indent conflicts with non-indenting-braces/,
        'Conflict message is correct');
}

# Test 2: Doesn't detect conflict when brace-left-and-indent is false
{
    my %opts = (
        'brace-left-and-indent' => '0',
        'non-indenting-braces'  => '1',
    );
    my %sections = (
        'brace-left-and-indent' => '1. Section',
        'non-indenting-braces'  => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when brace-left-and-indent is false');
}

# Test 3: Doesn't detect conflict when non-indenting-braces is false
{
    my %opts = (
        'brace-left-and-indent' => '1',
        'non-indenting-braces'  => '0',
    );
    my %sections = (
        'brace-left-and-indent' => '1. Section',
        'non-indenting-braces'  => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when non-indenting-braces is false');
}

# Test 4: Detects conflict between tabs and entab-leading-whitespace
{
    my %opts = (
        'tabs'                    => '1',
        'entab-leading-whitespace' => '1',
    );
    my %sections = (
        'tabs'                    => '1. Section',
        'entab-leading-whitespace' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 1, 'One conflict note added');
    like($section_notes{'1. Section'}->[0], qr/tabs together with entab-leading-whitespace may conflict/,
        'Conflict message is correct');
}

# Test 5: Doesn't detect conflict when tabs is false
{
    my %opts = (
        'tabs'                    => '0',
        'entab-leading-whitespace' => '1',
    );
    my %sections = (
        'tabs'                    => '1. Section',
        'entab-leading-whitespace' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when tabs is false');
}

# Test 6: Detects when specific brace options differ from brace-tightness
{
    my %opts = (
        'brace-tightness'       => '2',
        'block-brace-tightness' => '3',  # Different
    );
    my %sections = (
        'brace-tightness'       => '1. Section',
        'block-brace-tightness' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 1, 'One conflict note added');
    like($section_notes{'1. Section'}->[0], qr/block-brace-tightness differs from brace-tightness; specific wins/,
        'Conflict message is correct');
}

# Test 7: Doesn't detect conflict when specific brace option equals brace-tightness
{
    my %opts = (
        'brace-tightness'       => '2',
        'block-brace-tightness' => '2',  # Same
    );
    my %sections = (
        'brace-tightness'       => '1. Section',
        'block-brace-tightness' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when specific brace option equals brace-tightness');
}

# Test 8: Handles multiple specific brace options that differ
{
    my %opts = (
        'brace-tightness'              => '2',
        'block-brace-tightness'        => '3',  # Different
        'brace-vertical-tightness'      => '4',  # Different
        'brace-vertical-tightness-closing' => '2',  # Same - no conflict
    );
    my %sections = (
        'brace-tightness'              => '1. Section',
        'block-brace-tightness'        => '1. Section',
        'brace-vertical-tightness'     => '1. Section',
        'brace-vertical-tightness-closing' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 2, 'Two conflict notes added for differing options');
    my @notes = @{$section_notes{'1. Section'}};
    my $found_block = grep { /block-brace-tightness differs/ } @notes;
    my $found_vertical = grep { /brace-vertical-tightness differs/ } @notes;
    ok($found_block, 'Found conflict note for block-brace-tightness');
    ok($found_vertical, 'Found conflict note for brace-vertical-tightness');
}

# Test 9: Handles undefined specific brace option (skips it)
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
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when specific brace option is undefined');
}

# Test 10: Handles missing brace-tightness gracefully
{
    my %opts = (
        'block-brace-tightness' => '3',
    );
    my %sections = (
        'block-brace-tightness' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when brace-tightness is missing');
}

# Test 11: Detects when fuzzy-line-length exceeds maximum-line-length
{
    my %opts = (
        'maximum-line-length' => '80',
        'fuzzy-line-length'  => '100',  # Exceeds maximum
    );
    my %sections = (
        'maximum-line-length' => '1. Section',
        'fuzzy-line-length'  => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 1, 'One conflict note added');
    like($section_notes{'1. Section'}->[0], qr/fuzzy-line-length \(100\) exceeds maximum-line-length \(80\)/,
        'Conflict message is correct');
}

# Test 12: Doesn't detect conflict when fuzzy-line-length equals maximum-line-length
{
    my %opts = (
        'maximum-line-length' => '80',
        'fuzzy-line-length'  => '80',  # Equal
    );
    my %sections = (
        'maximum-line-length' => '1. Section',
        'fuzzy-line-length'  => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when fuzzy-line-length equals maximum-line-length');
}

# Test 13: Doesn't detect conflict when fuzzy-line-length is less than maximum-line-length
{
    my %opts = (
        'maximum-line-length' => '80',
        'fuzzy-line-length'  => '70',  # Less than maximum
    );
    my %sections = (
        'maximum-line-length' => '1. Section',
        'fuzzy-line-length'  => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when fuzzy-line-length is less than maximum-line-length');
}

# Test 14: Handles non-integer values for line length options
{
    my %opts = (
        'maximum-line-length' => '80.5',  # Not an integer
        'fuzzy-line-length'  => '100',
    );
    my %sections = (
        'maximum-line-length' => '1. Section',
        'fuzzy-line-length'  => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when values are not integers');
}

# Test 15: Handles missing maximum-line-length gracefully
{
    my %opts = (
        'fuzzy-line-length' => '100',
    );
    my %sections = (
        'fuzzy-line-length' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when maximum-line-length is missing');
}

# Test 16: Detects format disabled but format-skipping enabled
{
    my %opts = (
        'format' => '0',
        'format-skipping' => '1',
    );
    my %sections = (
        'format' => '1. Section',
        'format-skipping' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 1, 'One conflict note added');
    like($section_notes{'1. Section'}->[0], qr/format is disabled but format-skipping detection is enabled/,
        'Conflict message is correct');
}

# Test 17: Detects format disabled but detect-format-skipping-from-start enabled
{
    my %opts = (
        'format' => '0',
        'detect-format-skipping-from-start' => '1',
    );
    my %sections = (
        'format' => '1. Section',
        'detect-format-skipping-from-start' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 1, 'One conflict note added');
    like($section_notes{'1. Section'}->[0], qr/format is disabled but format-skipping detection is enabled/,
        'Conflict message is correct');
}

# Test 18: Doesn't detect conflict when format is enabled
{
    my %opts = (
        'format' => '1',
        'format-skipping' => '1',
    );
    my %sections = (
        'format' => '1. Section',
        'format-skipping' => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(!exists $section_notes{'1. Section'} || scalar @{$section_notes{'1. Section'}} == 0,
        'No conflict detected when format is enabled');
}

# Test 19: Handles missing section_notes hash (creates empty)
{
    my %opts = (
        'brace-left-and-indent' => '1',
        'non-indenting-braces'  => '1',
    );
    my %sections = (
        'brace-left-and-indent' => '1. Section',
        'non-indenting-braces'  => '1. Section',
    );
    detect_conflicts(\%opts, \%sections, undef);
    
    # The function should handle undef section_notes by creating an empty hash
    # But since we pass undef, we can't check it directly. Let's test with an empty hash instead.
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created when passed empty hash');
    is(scalar @{$section_notes{'1. Section'}}, 1, 'Conflict note added to empty hash');
}

# Test 20: Handles multiple conflicts simultaneously
{
    my %opts = (
        'brace-left-and-indent' => '1',
        'non-indenting-braces'  => '1',
        'tabs'                  => '1',
        'entab-leading-whitespace' => '1',
        'brace-tightness'       => '2',
        'block-brace-tightness' => '3',
        'maximum-line-length'   => '80',
        'fuzzy-line-length'     => '100',
        'format'               => '0',
        'format-skipping'       => '1',
    );
    my %sections = (
        'brace-left-and-indent' => '1. Section',
        'non-indenting-braces'  => '1. Section',
        'tabs'                  => '1. Section',
        'entab-leading-whitespace' => '1. Section',
        'brace-tightness'       => '1. Section',
        'block-brace-tightness' => '1. Section',
        'maximum-line-length'   => '1. Section',
        'fuzzy-line-length'     => '1. Section',
        'format'               => '1. Section',
        'format-skipping'       => '1. Section',
    );
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    ok(exists $section_notes{'1. Section'}, 'Section notes hash created');
    is(scalar @{$section_notes{'1. Section'}}, 5, 'Five conflict notes added for multiple conflicts');
}

# Test 21: Handles empty opts hash
{
    my %opts = ();
    my %sections = ();
    my %section_notes = ();
    detect_conflicts(\%opts, \%sections, \%section_notes);
    
    is(scalar keys %section_notes, 0, 'No conflicts detected for empty opts hash');
}

done_testing();

