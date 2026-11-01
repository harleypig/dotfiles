#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'tests/perl/lib';
use TestPerltidyrcClean;

# Test the detect_conflicts function from bin/perltidyrc-clean
#
# load_perltidyrc_clean() loads the script's functions without running it,
# so this tests the actual function from the working code.

# Load the script's functions
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
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok( exists $section_notes{'1. Section'}, 'Section notes hash created' );
  is( scalar @{ $section_notes{'1. Section'} }, 1, 'One conflict note added' );
  like(
    $section_notes{'1. Section'}->[0], qr/brace-left-and-indent conflicts with non-indenting-braces/,
    'Conflict message is correct'
  );
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
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok(
    !exists $section_notes{'1. Section'} || scalar @{ $section_notes{'1. Section'} } == 0,
    'No conflict detected when brace-left-and-indent is false'
  );
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
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok(
    !exists $section_notes{'1. Section'} || scalar @{ $section_notes{'1. Section'} } == 0,
    'No conflict detected when non-indenting-braces is false'
  );
}

# Test 4: Detects conflict between tabs and entab-leading-whitespace
{
  my %opts = (
    'tabs'                     => '1',
    'entab-leading-whitespace' => '1',
  );
  my %sections = (
    'tabs'                     => '1. Section',
    'entab-leading-whitespace' => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok( exists $section_notes{'1. Section'}, 'Section notes hash created' );
  is( scalar @{ $section_notes{'1. Section'} }, 1, 'One conflict note added' );
  like(
    $section_notes{'1. Section'}->[0], qr/tabs together with entab-leading-whitespace may conflict/,
    'Conflict message is correct'
  );
}

# Test 5: Doesn't detect conflict when tabs is false
{
  my %opts = (
    'tabs'                     => '0',
    'entab-leading-whitespace' => '1',
  );
  my %sections = (
    'tabs'                     => '1. Section',
    'entab-leading-whitespace' => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok(
    !exists $section_notes{'1. Section'} || scalar @{ $section_notes{'1. Section'} } == 0,
    'No conflict detected when tabs is false'
  );
}

# Test 6: brace-tightness has nothing to conflict with (#672). Per
# perltidy(1), it sets the spaces inside non-block braces;
# block-brace-tightness sets them inside code-block braces, a different set,
# and the *-vertical-tightness options set line breaks, not spaces. Here the
# rc sets only brace-tightness and the others are at Perl::Tidy's defaults.
# Red if any of them is noted against brace-tightness.
{
  my %opts = (
    'brace-tightness'                   => '2',
    'block-brace-tightness'             => '0',
    'brace-vertical-tightness'          => '0',
    'brace-vertical-tightness-closing'  => '0',
    'brace-follower-vertical-tightness' => '1',
    'block-brace-vertical-tightness'    => '0',
  );
  my %sections      = map { $_ => '1. Section' } keys %opts;
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes, { 'brace-tightness' => '2' } );

  is_deeply( \%section_notes, {}, 'An rc setting only brace-tightness gets no note' );
}

# Test 7: The same holds when the rc sets every one of them to a different
# value. Red if a difference between them is noted.
{
  my %opts = (
    'brace-tightness'                   => '2',
    'block-brace-tightness'             => '1',
    'brace-vertical-tightness'          => '1',
    'brace-vertical-tightness-closing'  => '1',
    'brace-follower-vertical-tightness' => '0',
    'block-brace-vertical-tightness'    => '1',
  );
  my %sections      = map { $_ => '1. Section' } keys %opts;
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  is_deeply( \%section_notes, {}, 'brace options that differ from brace-tightness get no note' );
}

# Test 8: Detects when fuzzy-line-length exceeds maximum-line-length
{
  my %opts = (
    'maximum-line-length' => '80',
    'fuzzy-line-length'   => '100',    # Exceeds maximum
  );
  my %sections = (
    'maximum-line-length' => '1. Section',
    'fuzzy-line-length'   => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok( exists $section_notes{'1. Section'}, 'Section notes hash created' );
  is( scalar @{ $section_notes{'1. Section'} }, 1, 'One conflict note added' );
  like(
    $section_notes{'1. Section'}->[0], qr/fuzzy-line-length \(100\) exceeds maximum-line-length \(80\)/,
    'Conflict message is correct'
  );
}

# Test 9: Doesn't detect conflict when fuzzy-line-length equals maximum-line-length
{
  my %opts = (
    'maximum-line-length' => '80',
    'fuzzy-line-length'   => '80',     # Equal
  );
  my %sections = (
    'maximum-line-length' => '1. Section',
    'fuzzy-line-length'   => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok(
    !exists $section_notes{'1. Section'} || scalar @{ $section_notes{'1. Section'} } == 0,
    'No conflict detected when fuzzy-line-length equals maximum-line-length'
  );
}

# Test 10: Doesn't detect conflict when fuzzy-line-length is less than maximum-line-length
{
  my %opts = (
    'maximum-line-length' => '80',
    'fuzzy-line-length'   => '70',     # Less than maximum
  );
  my %sections = (
    'maximum-line-length' => '1. Section',
    'fuzzy-line-length'   => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok(
    !exists $section_notes{'1. Section'} || scalar @{ $section_notes{'1. Section'} } == 0,
    'No conflict detected when fuzzy-line-length is less than maximum-line-length'
  );
}

# Test 11: Handles non-integer values for line length options
{
  my %opts = (
    'maximum-line-length' => '80.5',   # Not an integer
    'fuzzy-line-length'   => '100',
  );
  my %sections = (
    'maximum-line-length' => '1. Section',
    'fuzzy-line-length'   => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok(
    !exists $section_notes{'1. Section'} || scalar @{ $section_notes{'1. Section'} } == 0,
    'No conflict detected when values are not integers'
  );
}

# Test 12: Handles missing maximum-line-length gracefully
{
  my %opts = (
    'fuzzy-line-length' => '100',
  );
  my %sections = (
    'fuzzy-line-length' => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok(
    !exists $section_notes{'1. Section'} || scalar @{ $section_notes{'1. Section'} } == 0,
    'No conflict detected when maximum-line-length is missing'
  );
}

# Test 13: Detects format disabled but format-skipping enabled
{
  my %opts = (
    'format'          => '0',
    'format-skipping' => '1',
  );
  my %sections = (
    'format'          => '1. Section',
    'format-skipping' => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok( exists $section_notes{'1. Section'}, 'Section notes hash created' );
  is( scalar @{ $section_notes{'1. Section'} }, 1, 'One conflict note added' );
  like(
    $section_notes{'1. Section'}->[0], qr/format is disabled but format-skipping detection is enabled/,
    'Conflict message is correct'
  );
}

# Test 14: Detects format disabled but detect-format-skipping-from-start enabled
{
  my %opts = (
    'format'                            => '0',
    'detect-format-skipping-from-start' => '1',
  );
  my %sections = (
    'format'                            => '1. Section',
    'detect-format-skipping-from-start' => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok( exists $section_notes{'1. Section'}, 'Section notes hash created' );
  is( scalar @{ $section_notes{'1. Section'} }, 1, 'One conflict note added' );
  like(
    $section_notes{'1. Section'}->[0], qr/format is disabled but format-skipping detection is enabled/,
    'Conflict message is correct'
  );
}

# Test 15: Doesn't detect conflict when format is enabled
{
  my %opts = (
    'format'          => '1',
    'format-skipping' => '1',
  );
  my %sections = (
    'format'          => '1. Section',
    'format-skipping' => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok(
    !exists $section_notes{'1. Section'} || scalar @{ $section_notes{'1. Section'} } == 0,
    'No conflict detected when format is enabled'
  );
}

# Test 16: Handles missing section_notes hash (creates empty)
{
  my %opts = (
    'brace-left-and-indent' => '1',
    'non-indenting-braces'  => '1',
  );
  my %sections = (
    'brace-left-and-indent' => '1. Section',
    'non-indenting-braces'  => '1. Section',
  );
  detect_conflicts( \%opts, \%sections, undef );

  # The function should handle undef section_notes by creating an empty hash
  # But since we pass undef, we can't check it directly. Let's test with an empty hash instead.
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok( exists $section_notes{'1. Section'}, 'Section notes hash created when passed empty hash' );
  is( scalar @{ $section_notes{'1. Section'} }, 1, 'Conflict note added to empty hash' );
}

# Test 17: Handles multiple conflicts simultaneously
{
  my %opts = (
    'brace-left-and-indent'    => '1',
    'non-indenting-braces'     => '1',
    'tabs'                     => '1',
    'entab-leading-whitespace' => '1',
    'brace-tightness'          => '2',
    'block-brace-tightness'    => '3',
    'maximum-line-length'      => '80',
    'fuzzy-line-length'        => '100',
    'format'                   => '0',
    'format-skipping'          => '1',
  );
  my %sections = (
    'brace-left-and-indent'    => '1. Section',
    'non-indenting-braces'     => '1. Section',
    'tabs'                     => '1. Section',
    'entab-leading-whitespace' => '1. Section',
    'brace-tightness'          => '1. Section',
    'block-brace-tightness'    => '1. Section',
    'maximum-line-length'      => '1. Section',
    'fuzzy-line-length'        => '1. Section',
    'format'                   => '1. Section',
    'format-skipping'          => '1. Section',
  );
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  ok( exists $section_notes{'1. Section'}, 'Section notes hash created' );
  is( scalar @{ $section_notes{'1. Section'} }, 4, 'Four conflict notes added for multiple conflicts' );
}

# Test 18: Handles empty opts hash
{
  my %opts          = ();
  my %sections      = ();
  my %section_notes = ();
  detect_conflicts( \%opts, \%sections, \%section_notes );

  is( scalar keys %section_notes, 0, 'No conflicts detected for empty opts hash' );
}

# Test 19: Conflicts are checked against the effective settings and noted
# only where the cleaned file sets one side (#665). Here non-indenting-braces
# is a default the file does not carry.
{
  my %opts = (
    'brace-left-and-indent' => '1',
    'non-indenting-braces'  => '1',
  );
  my %sections = (
    'brace-left-and-indent' => '1. Section',
    'non-indenting-braces'  => '1. Section',
  );

  # Red if a conflict with a default is dropped because the file does not
  # carry the default.
  my %one_side = ();
  detect_conflicts( \%opts, \%sections, \%one_side, { 'brace-left-and-indent' => '1' } );
  is_deeply(
    \%one_side,
    { '1. Section' => ['brace-left-and-indent conflicts with non-indenting-braces'] },
    'Notes a conflict when the file carries one side'
  );

  # Red if a conflict between two settings the file leaves at their defaults
  # is noted.
  my %neither = ();
  detect_conflicts( \%opts, \%sections, \%neither, { 'indent-columns' => '4' } );
  is_deeply( \%neither, {}, 'Notes nothing when the file carries neither side' );
}

done_testing();
