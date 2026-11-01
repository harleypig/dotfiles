#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'tests/perl/lib';
use TestPerltidyrcClean;

# Test the condense_options function from bin/perltidyrc-clean
#
# load_perltidyrc_clean() loads the script's functions without running it,
# so this tests the actual function from the working code.

# Load the script's functions
load_perltidyrc_clean();

# Test 1: Doesn't remove brace-specific options that differ from brace-tightness
{
  my %opts = (
    'brace-tightness'       => '2',
    'block-brace-tightness' => '3',    # Different value
  );
  my %sections = (
    'brace-tightness'       => '1. Section',
    'block-brace-tightness' => '1. Section',
  );
  my %section_notes         = ();
  my %abbreviations         = ();
  my %abbreviations_default = ();
  condense_options( \%opts, \%sections, \%section_notes, \%abbreviations, \%abbreviations_default );

  ok( exists $opts{'brace-tightness'},       'Keeps brace-tightness' );
  ok( exists $opts{'block-brace-tightness'}, 'Keeps block-brace-tightness when different' );
  is( $opts{'block-brace-tightness'}, '3', 'Preserves different value' );
  ok(
    !exists $section_notes{'1. Section'} || scalar @{ $section_notes{'1. Section'} } == 0,
    'No section note added for differing option'
  );
}

# Test 2: Handles missing brace-tightness gracefully
{
  my %opts = (
    'block-brace-tightness' => '2',
  );
  my %sections = (
    'block-brace-tightness' => '1. Section',
  );
  my %section_notes         = ();
  my %abbreviations         = ();
  my %abbreviations_default = ();
  condense_options( \%opts, \%sections, \%section_notes, \%abbreviations, \%abbreviations_default );

  ok( exists $opts{'block-brace-tightness'}, 'Keeps block-brace-tightness when brace-tightness missing' );
  is( $opts{'block-brace-tightness'}, '2', 'Preserves value when brace-tightness missing' );
}

# Test 3: Doesn't remove continuation-indentation if differs from indent-columns
{
  my %opts = (
    'indent-columns'           => '4',
    'continuation-indentation' => '8', # Different value
  );
  my %sections = (
    'indent-columns'           => '1. Section',
    'continuation-indentation' => '1. Section',
  );
  my %section_notes         = ();
  my %abbreviations         = ();
  my %abbreviations_default = ();
  condense_options( \%opts, \%sections, \%section_notes, \%abbreviations, \%abbreviations_default );

  ok( exists $opts{'indent-columns'},           'Keeps indent-columns' );
  ok( exists $opts{'continuation-indentation'}, 'Keeps continuation-indentation when different' );
  is( $opts{'continuation-indentation'}, '8', 'Preserves different value' );
}

# Test 4: Handles missing indent-columns gracefully
{
  my %opts = (
    'continuation-indentation' => '4',
  );
  my %sections = (
    'continuation-indentation' => '1. Section',
  );
  my %section_notes         = ();
  my %abbreviations         = ();
  my %abbreviations_default = ();
  condense_options( \%opts, \%sections, \%section_notes, \%abbreviations, \%abbreviations_default );

  ok( exists $opts{'continuation-indentation'}, 'Keeps continuation-indentation when indent-columns missing' );
  is( $opts{'continuation-indentation'}, '4', 'Preserves value when indent-columns missing' );
}

# Test 5: Handles missing continuation-indentation gracefully
{
  my %opts = (
    'indent-columns' => '4',
  );
  my %sections = (
    'indent-columns' => '1. Section',
  );
  my %section_notes         = ();
  my %abbreviations         = ();
  my %abbreviations_default = ();
  condense_options( \%opts, \%sections, \%section_notes, \%abbreviations, \%abbreviations_default );

  ok( exists $opts{'indent-columns'}, 'Keeps indent-columns when continuation-indentation missing' );
  is( $opts{'indent-columns'}, '4', 'Preserves value when continuation-indentation missing' );
}

# Test 6: Handles undefined brace-specific option values
{
  my %opts = (
    'brace-tightness'       => '2',
    'block-brace-tightness' => undef,
  );
  my %sections = (
    'brace-tightness'       => '1. Section',
    'block-brace-tightness' => '1. Section',
  );
  my %section_notes         = ();
  my %abbreviations         = ();
  my %abbreviations_default = ();
  condense_options( \%opts, \%sections, \%section_notes, \%abbreviations, \%abbreviations_default );

  ok( exists $opts{'brace-tightness'},         'Keeps brace-tightness' );
  ok( exists $opts{'block-brace-tightness'},   'Keeps block-brace-tightness when undefined' );
  ok( !defined $opts{'block-brace-tightness'}, 'Preserves undefined value' );
}

# Test 7: Handles empty opts hash
{
  my %opts                  = ();
  my %sections              = ();
  my %section_notes         = ();
  my %abbreviations         = ();
  my %abbreviations_default = ();
  condense_options( \%opts, \%sections, \%section_notes, \%abbreviations, \%abbreviations_default );

  is( scalar keys %opts, 0, 'Empty opts hash remains empty' );
}

# Test 8: Handles options not related to condensation
{
  my %opts = (
    'line-length'    => '80',
    'indent-columns' => '4',
  );
  my %sections = (
    'line-length'    => '1. Section',
    'indent-columns' => '1. Section',
  );
  my %section_notes         = ();
  my %abbreviations         = ();
  my %abbreviations_default = ();
  condense_options( \%opts, \%sections, \%section_notes, \%abbreviations, \%abbreviations_default );

  ok( exists $opts{'line-length'},    'Keeps unrelated options' );
  ok( exists $opts{'indent-columns'}, 'Keeps indent-columns when continuation-indentation missing' );
  is( $opts{'line-length'}, '80', 'Preserves unrelated option value' );
}

# Test 9: Replaces a fully matched abbreviation's options with the
# abbreviation itself (#664). The abbreviation takes the first option's
# section and an undef value, so dump_options writes the bare --pair=1; red
# if the options are dropped without it.
{
  my %opts = (
    'alpha'   => '1',
    'bravo'   => '1',
    'charlie' => '2',
  );
  my %sections = (
    'alpha'   => '1. First',
    'bravo'   => '2. Second',
    'charlie' => '1. First',
  );
  my %section_notes         = ();
  my %abbreviations_default = (
    a        => ['alpha'],
    b        => ['bravo'],
    'pair=1' => [qw(a=1 b=1)],
  );
  condense_options( \%opts, \%sections, \%section_notes, {}, \%abbreviations_default );

  is_deeply( \%opts, { 'pair=1' => undef, charlie => '2' }, 'Replaces the expansion with the abbreviation' );
  is( $sections{'pair=1'}, '1. First', 'The abbreviation takes the first option\'s section' );
  is_deeply(
    \%section_notes,
    { '1. First' => ['alpha condensed to pair=1'], '2. Second' => ['bravo condensed to pair=1'] },
    'Notes each condensed option in its own section'
  );
}

done_testing();
