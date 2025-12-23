#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the add_section_note function from bin/perltidyrc-clean
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Test 1: Adds note to correct section
{
    my %sections = (
        'indent-columns' => '1. Indentation',
        'brace-tightness' => '2. Whitespace control',
    );
    my %section_notes;
    
    add_section_note(\%sections, \%section_notes, 'indent-columns', 'Test note 1');
    
    ok(exists $section_notes{'1. Indentation'}, 'Section exists after adding note');
    is(scalar @{$section_notes{'1. Indentation'}}, 1, 'One note added to section');
    is($section_notes{'1. Indentation'}[0], 'Test note 1', 'Note text is correct');
}

# Test 2: Handles unknown options (uses 'UNKNOWN' section)
{
    my %sections = (
        'known-option' => '1. Test Section',
    );
    my %section_notes;
    
    add_section_note(\%sections, \%section_notes, 'unknown-option', 'Unknown option note');
    
    ok(exists $section_notes{'UNKNOWN'}, 'UNKNOWN section exists for unknown option');
    is(scalar @{$section_notes{'UNKNOWN'}}, 1, 'One note added to UNKNOWN section');
    is($section_notes{'UNKNOWN'}[0], 'Unknown option note', 'Note text is correct');
}

# Test 3: Appends multiple notes to same section
{
    my %sections = (
        'option1' => '1. Test Section',
        'option2' => '1. Test Section',  # Same section
    );
    my %section_notes;
    
    add_section_note(\%sections, \%section_notes, 'option1', 'First note');
    add_section_note(\%sections, \%section_notes, 'option2', 'Second note');
    add_section_note(\%sections, \%section_notes, 'option1', 'Third note');
    
    ok(exists $section_notes{'1. Test Section'}, 'Section exists after adding multiple notes');
    is(scalar @{$section_notes{'1. Test Section'}}, 3, 'Three notes added to same section');
    is($section_notes{'1. Test Section'}[0], 'First note', 'First note is correct');
    is($section_notes{'1. Test Section'}[1], 'Second note', 'Second note is correct');
    is($section_notes{'1. Test Section'}[2], 'Third note', 'Third note is correct');
}

# Test 4: Handles empty section_notes hash (creates array ref)
{
    my %sections = (
        'test-option' => '1. Test Section',
    );
    my %section_notes;  # Empty hash
    
    add_section_note(\%sections, \%section_notes, 'test-option', 'Note for empty hash');
    
    ok(exists $section_notes{'1. Test Section'}, 'Section created in empty hash');
    is(scalar @{$section_notes{'1. Test Section'}}, 1, 'Note added successfully');
    is($section_notes{'1. Test Section'}[0], 'Note for empty hash', 'Note text is correct');
}

# Test 5: Handles undefined option (uses 'UNKNOWN' section)
{
    my %sections = (
        'known-option' => '1. Test Section',
    );
    my %section_notes;
    
    add_section_note(\%sections, \%section_notes, undef, 'Note for undefined option');
    
    ok(exists $section_notes{'UNKNOWN'}, 'UNKNOWN section exists for undefined option');
    is(scalar @{$section_notes{'UNKNOWN'}}, 1, 'One note added to UNKNOWN section');
    is($section_notes{'UNKNOWN'}[0], 'Note for undefined option', 'Note text is correct');
}

# Test 6: Handles empty string option (uses 'UNKNOWN' section)
{
    my %sections = (
        'known-option' => '1. Test Section',
    );
    my %section_notes;
    
    add_section_note(\%sections, \%section_notes, '', 'Note for empty string option');
    
    ok(exists $section_notes{'UNKNOWN'}, 'UNKNOWN section exists for empty string option');
    is(scalar @{$section_notes{'UNKNOWN'}}, 1, 'One note added to UNKNOWN section');
    is($section_notes{'UNKNOWN'}[0], 'Note for empty string option', 'Note text is correct');
}

# Test 7: Handles option that maps to undef section (uses 'UNKNOWN' section)
{
    my %sections = (
        'test-option' => undef,  # Option exists but section is undef
    );
    my %section_notes;
    
    add_section_note(\%sections, \%section_notes, 'test-option', 'Note for undef section');
    
    ok(exists $section_notes{'UNKNOWN'}, 'UNKNOWN section exists when section is undef');
    is(scalar @{$section_notes{'UNKNOWN'}}, 1, 'One note added to UNKNOWN section');
    is($section_notes{'UNKNOWN'}[0], 'Note for undef section', 'Note text is correct');
}

# Test 8: Handles undef text (still adds note)
{
    my %sections = (
        'test-option' => '1. Test Section',
    );
    my %section_notes;
    
    add_section_note(\%sections, \%section_notes, 'test-option', undef);
    
    ok(exists $section_notes{'1. Test Section'}, 'Section exists after adding undef note');
    is(scalar @{$section_notes{'1. Test Section'}}, 1, 'One note added');
    is($section_notes{'1. Test Section'}[0], undef, 'Undef note text is stored');
}

done_testing();

