#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 'tests/perl/lib';
use TestPerltidyrcClean ();            # skips the file without Perl::Tidy
use File::Spec;
use Cwd;
use File::Temp qw(tempfile);

# Integration tests for output formatting
# These tests verify the actual script output format, complementing the
# dump_options function tests

my $script = File::Spec->catfile( 'bin', 'perltidyrc-clean' );

# Test 1: Options grouped by section
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );

  # Add options from different sections
  print {$fh} "--indent-columns=8\n";  # Basic formatting section
  print {$fh} "--maximum-line-length=120\n";  # Basic formatting section
  print {$fh} "--brace-tightness=2\n"; # Brace formatting section
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Options grouped by section exits with code 0' );

  # Extract sections from output
  my %sections_found;
  my $current_section;
  foreach my $line ( split /\n/, $stdout ) {

    # Section headers can be "# Section name" or "# N. Section name"
    # Exclude header lines (perltidy, using, source)
    if ( $line =~ /^#\s+(?:\d+\.\s+)?(.+)$/
      && $line !~ /^#\s+(?:perltidy|using|source)/
      && $line !~ /^#\s+perltidy/i ) {
      $current_section = $1;
      $sections_found{$current_section} //= [];
    } elsif ( $line =~ /^--([^=]+)/ && $current_section ) {
      push @{ $sections_found{$current_section} }, $1;
    }
  }

  # Verify options are grouped
  ok( scalar keys %sections_found > 0, 'Options are grouped by section' );

  # Check that indent-columns and maximum-line-length are in the same section
  my $found_basic = 0;
  my $found_brace = 0;
  my $basic_section;
  my $brace_section;

  foreach my $section ( keys %sections_found ) {
    my @opts       = @{ $sections_found{$section} };
    my $has_indent = grep { $_ eq 'indent-columns' } @opts;
    my $has_maxlen = grep { $_ eq 'maximum-line-length' } @opts;
    my $has_brace  = grep { $_ eq 'brace-tightness' } @opts;

    if ( $has_indent || $has_maxlen ) {
      $found_basic   = 1;
      $basic_section = $section;
      if ( $has_indent && $has_maxlen ) {
        is(
          scalar( grep { $_ eq 'indent-columns' || $_ eq 'maximum-line-length' } @opts ), 2,
          'Options from same section are grouped together'
        );
      }
    }
    if ($has_brace) {
      $found_brace   = 1;
      $brace_section = $section;
    }
  } ## end foreach my $section ( keys ...)

  ok( $found_basic, 'Basic formatting options are grouped (indent-columns and maximum-line-length together)' );
  ok( $found_brace, 'Brace formatting options are grouped (brace-tightness in its section)' );

  # Verify they're in different sections
  if ( $found_basic && $found_brace && $basic_section && $brace_section ) {
    isnt( $basic_section, $brace_section, 'Different option types are in different sections' );
  }
}

# Test 2: Sections sorted numerically
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );

  # Add options from different sections (out of order)
  print {$fh} "--brace-tightness=2\n"; # Section 2
  print {$fh} "--indent-columns=8\n";  # Section 1
  print {$fh} "--maximum-line-length=120\n";  # Section 1
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Sections sorted numerically exits with code 0' );

  # Extract section order from output
  my @section_order;
  foreach my $line ( split /\n/, $stdout ) {

    # Section headers can have numeric prefix or not
    if ( $line =~ /^#\s+(?:\d+\.\s+)?(.+)$/ && $line !~ /^#\s+(?:perltidy|using|source)/ ) {
      push @section_order, $line;
    }
  }

  # Verify sections are sorted (by checking order in output)
  ok( scalar @section_order >= 2, 'Multiple sections found' );
  if ( @section_order >= 2 ) {

    # Sections should appear in a consistent order
    # The first section should be "Basic formatting" related
    like(
      $section_order[0], qr/Basic|formatting/i,
      'Sections appear in expected order'
    );
  }
}

# Test 3: Default comments padded to column 40
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );

  # Use a default value (if indent-columns=4 is default)
  print {$fh} "--indent-columns=4\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile --keep-defaults 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Default comments padded exits with code 0' );

  # indent-columns=4 is the Perl::Tidy default, so under --keep-defaults its
  # line carries the default marker. The marker's presence is asserted first,
  # so the padding check cannot pass by finding no marked line. Red if the
  # marker is dropped, or padded short of column 40.
  my ($marked) = grep { /#\s+default/ } split /\n/, $stdout;
  ok( defined $marked, 'A default option carries the default marker' );

  my $hash_pos = defined $marked ? index $marked, q{#} : -1;
  cmp_ok( $hash_pos, '>=', 40, 'Default comment padded to column 40' );
}

# Test 4: Section notes appear in correct sections
#
# brace-left-and-indent and non-indenting-braces conflict, and the note is
# filed under brace-left-and-indent's section. non-indenting-braces is a
# Perl::Tidy default, so --keep-defaults is needed for both to reach the
# conflict check at all; it also puts the two options in different
# sections, so a note filed under the wrong one is visible. Each section is
# a blank-line-separated block. Red if the note is dropped, or lands in a
# block other than the one holding --brace-left-and-indent.
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--brace-left-and-indent\n";
  print {$fh} "--non-indenting-braces\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile --keep-defaults 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Section notes appear exits with code 0' );

  my $note  = qr/^# NOTE: brace-left-and-indent conflicts with non-indenting-braces$/m;
  my @noted = grep { /$note/ } split /\n\n/, $stdout;

  is( scalar @noted, 1, 'The conflict note appears in exactly one section' );
  like( $noted[0] // q{}, qr/^--brace-left-and-indent$/m, 'The note is in the section of the option it is about' );
}

# Test 5: Header includes date, cmdline, and source
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=8\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Header includes info exits with code 0' );

  # Check for header components
  like(
    $stdout, qr/perltidy configuration file created/,
    'Header includes creation date'
  );
  like(
    $stdout, qr/using:.*perltidyrc-clean/,
    'Header includes cmdline'
  );
  like(
    $stdout, qr/source:.*$tmpfile/,
    'Header includes source file path'
  );
}

# Test 6: Quiet mode omits headers
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=8\n";
  close $fh;

  my $stdout_quiet  = `$script --rc $tmpfile --quiet 2>&1`;
  my $stdout_normal = `$script --rc $tmpfile 2>&1`;

  # Quiet mode should omit headers
  unlike(
    $stdout_quiet, qr/perltidy configuration file created/,
    'Quiet mode omits header date'
  );
  unlike(
    $stdout_quiet, qr/using:/,
    'Quiet mode omits cmdline'
  );
  unlike(
    $stdout_quiet, qr/source:/,
    'Quiet mode omits source'
  );

  # Quiet mode should omit section headers (they start with #)
  my $has_section_header = 0;
  foreach my $line ( split /\n/, $stdout_quiet ) {
    if ( $line =~ /^#\s+(?:\d+\.\s+)?[A-Z]/ && $line !~ /^#\s+(?:perltidy|using|source)/ ) {
      $has_section_header = 1;
      last;
    }
  }
  ok( !$has_section_header, 'Quiet mode omits section headers' );

  # Normal mode should include headers
  like(
    $stdout_normal, qr/perltidy configuration file created/,
    'Normal mode includes header date'
  );
}

# Test 7: Options within sections are sorted alphabetically
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );

  # Add options in non-alphabetical order
  print {$fh} "--maximum-line-length=120\n";
  print {$fh} "--indent-columns=8\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Options sorted alphabetically exits with code 0' );

  # Extract options from first section
  my @options;
  my $in_section = 0;
  foreach my $line ( split /\n/, $stdout ) {

    # Section headers can have numeric prefix or not
    if ( $line =~ /^#\s+(?:\d+\.\s+)?(.+)$/ && $line !~ /^#\s+(?:perltidy|using|source)/ ) {
      if ( $in_section && @options > 0 ) {

        # Already collected options from a section, stop
        last;
      }
      $in_section = 1;
      @options    = ();                # Reset for new section
    } elsif ( $line =~ /^--([^=]+)/ && $in_section ) {
      push @options, $1;
    }
  }

  # Both options are in Basic formatting options, so the first section holds
  # two; asserting that first keeps the sort check from passing on one.
  # Red if dump_section stops sorting: the input order is reverse-sorted.
  # (Unsorted output would follow hash order, so a regression shows red on
  # only some runs.)
  cmp_ok( scalar @options, '>=', 2, 'First section holds at least two options' );
  is_deeply( \@options, [ sort @options ], 'Options within sections are sorted alphabetically' );
}

# Test 8: Output format consistency (no duplicate sections)
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=8\n";
  print {$fh} "--maximum-line-length=120\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Output format consistency exits with code 0' );

  # Count section headers
  my %section_counts;
  foreach my $line ( split /\n/, $stdout ) {

    # Section headers can have numeric prefix or not
    if ( $line =~ /^#\s+(?:\d+\.\s+)?(.+)$/ && $line !~ /^#\s+(?:perltidy|using|source)/ ) {
      $section_counts{$1}++;
    }
  }

  # Each section should appear only once
  foreach my $section ( keys %section_counts ) {
    is( $section_counts{$section}, 1, "Section '$section' appears only once" );
  }
}

# Test 9: Empty lines between sections
#
# dump_section writes "\n" before every section heading, so each heading
# line must be preceded by an empty line. Goes red if that separator is
# dropped for any section. Two options from two different sections are
# used, and the heading count is asserted first, so the per-heading check
# cannot pass by finding no headings. The preamble lines and "# NOTE:"
# lines are comments too but not headings, so they are excluded.
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=8\n";
  print {$fh} "--brace-tightness=2\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Empty lines between sections exits with code 0' );

  my @lines = split /\n/, $stdout;
  my @heading_at =
    grep { $lines[$_] =~ /^#\s/ && $lines[$_] !~ /^#\s+(?:perltidy|using:|source:|NOTE:)/ } 0 .. $#lines;

  cmp_ok( scalar @heading_at, '>=', 2, 'Output has at least two section headings' );

  my @unseparated = map { $lines[$_] } grep { $_ == 0 || $lines[ $_ - 1 ] ne q{} } @heading_at;

  is_deeply( \@unseparated, [], 'Every section heading is preceded by an empty line' );
}

# Test 10: Abbreviations section appears after options
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=8\n";
  print {$fh} "myindent {indent-columns}\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Abbreviations section appears exits with code 0' );

  # The abbreviation heading must exist, and every option line must come
  # before it. (The old check matched "# Abbreviations" as an ordinary
  # section heading first, so it never found the abbreviations and always
  # took its unconditional-ok branch.) Red if the heading is dropped, or the
  # abbreviations are emitted ahead of an option.
  my @lines       = split /\n/, $stdout;
  my ($abbrev_at) = grep { $lines[$_] eq '# Abbreviations' } 0 .. $#lines;
  my @option_at   = grep { $lines[$_] =~ /^--/ } 0 .. $#lines;

  ok( defined $abbrev_at, 'Abbreviations heading is present' );
  cmp_ok( scalar @option_at,    '>=', 1,                'At least one option line is present' );
  cmp_ok( $option_at[-1] // -1, '<',  $abbrev_at // -1, 'Abbreviations section appears after options sections' );
  my $after_heading = defined $abbrev_at ? $lines[ $abbrev_at + 1 ] : undef;
  like( $after_heading // q{}, qr/^myindent \{indent-columns\}$/, 'The abbreviation follows its heading' );
}

done_testing();
