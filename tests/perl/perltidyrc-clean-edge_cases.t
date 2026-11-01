#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 'tests/perl/lib';
use TestPerltidyrcClean ();            # skips the file without Perl::Tidy
use File::Spec;
use Cwd;
use File::Temp qw(tempfile tempdir);
use File::Path qw(make_path remove_tree);

# Edge cases and error handling tests

my $script        = File::Spec->catfile( 'bin', 'perltidyrc-clean' );
my $test_data_dir = File::Spec->catdir( Cwd::getcwd(), 'tests', 'perl', 'data' );

# ============================================================================
# Edge Cases
# ============================================================================

# Test 1: Empty RC file
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'empty.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Empty RC file exits with code 0' );

  # Nothing to emit, so the script says so instead of writing a header over
  # no options. Red if it emits any option line, or drops the message.
  like( $stdout, qr/No configuration parameters remain/, 'Empty RC file reports no parameters remain' );
  unlike( $stdout, qr/^--/m, 'Empty RC file emits no options' );
}

# Test 2: RC file with only defaults (all removed)
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'defaults-only.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'RC file with only defaults exits with code 0' );

  # defaults-only.rc sets indent-columns=4 and maximum-line-length=80, both
  # Perl::Tidy defaults, so without --keep-defaults both are dropped and
  # nothing remains. Red if either default survives the filter.
  unlike( $stdout, qr/^--indent-columns=/m,      'RC file with only defaults drops indent-columns' );
  unlike( $stdout, qr/^--maximum-line-length=/m, 'RC file with only defaults drops maximum-line-length' );
  like( $stdout, qr/No configuration parameters remain/, 'RC file with only defaults reports no parameters remain' );
}

# Test 3: RC file with no valid options
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );

  # Add comments and blank lines (no valid options)
  print {$fh} "# This is a comment\n";
  print {$fh} "\n";
  print {$fh} "# Another comment\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'RC file with no valid options exits with code 0' );

  # Comments and blank lines set nothing. Red if a comment line is read as
  # an option, or the no-parameters message is dropped.
  like( $stdout, qr/No configuration parameters remain/, 'RC file with no valid options reports no parameters remain' );
  unlike( $stdout, qr/^--/m, 'RC file with no valid options emits no options' );
}

# Test 4: RC file with conflicts
#
# tabs and entab-leading-whitespace are both non-default, so both appear in
# the output. (A pair with a default side, conflicts.rc's, is integration.t
# Test 24.) Red if the tabs/entab check stops noting the pair.
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--tabs\n";
  print {$fh} "--entab-leading-whitespace=4\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'RC file with conflicts exits with code 0' );
  like(
    $stdout, qr/^# NOTE: tabs together with entab-leading-whitespace may conflict$/m,
    'RC file with conflicts adds a section note'
  );
}

# Test 5: RC file with user abbreviations
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'abbreviations.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'RC file with user abbreviations exits with code 0' );

  # Abbreviations should be preserved
  like(
    $stdout, qr/myindent.*indent-columns/,
    'RC file with user abbreviations preserves abbreviations'
  );
}

# Test 6: No RC file found (uses defaults)
#
# Perl::Tidy searches ./.perltidyrc, then $PERLTIDY, then $HOME/.perltidyrc,
# then /usr/local/etc/perltidyrc and /etc/perltidyrc. The first three are
# pointed at an empty tempdir; the system two cannot be, so the test skips
# where one exists rather than asserting against a host's own config. With
# nothing found, every option is a default and is dropped. Red if a search
# miss emits options, or the no-parameters message is dropped.
SKIP: {
  my @system_rc = grep { -e } qw(/usr/local/etc/perltidyrc /etc/perltidyrc);
  skip "system perltidyrc present (@system_rc); cannot test a search miss", 3 if @system_rc;

  my $tmpdir  = tempdir( CLEANUP => 1 );
  my $old_cwd = Cwd::getcwd();
  chdir $tmpdir or die "Cannot chdir to $tmpdir: $!";

  my ( $stdout, $exit_code );
  {
    local $ENV{HOME} = $tmpdir;
    delete local $ENV{PERLTIDY};
    $stdout    = `$old_cwd/$script 2>&1`;
    $exit_code = $? >> 8;
  }

  chdir $old_cwd or die "Cannot chdir back: $!";

  is( $exit_code, 0, 'No RC file found exits with code 0' );
  like( $stdout, qr/No configuration parameters remain/, 'No RC file found reports no parameters remain' );
  unlike( $stdout, qr/^--/m, 'No RC file found emits no options' );
} ## end SKIP:

# Test 7: RC file with invalid syntax (Perl::Tidy error)
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'invalid.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  # invalid.rc has an unclosed quote on line 2, which Perl::Tidy refuses to
  # parse; the script dies with Perl::Tidy's message. The wording and exit
  # code vary by Perl::Tidy version, so only "an error, naming the line" is
  # asserted. Red if the script swallows the parse error and exits 0.
  isnt( $exit_code, 0, 'RC file with invalid syntax exits non-zero' );
  like( $stdout, qr/error/i,         'RC file with invalid syntax reports an error' );
  like( $stdout, qr/unclosed-quote/, 'RC file with invalid syntax names the offending line' );
}

# Test 8: Very long option names (padding still works)
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'long-names.rc' );

  my $stdout    = `$script --rc $rc_file --keep-defaults 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Long option names exit with code 0' );

  # Should still format correctly
  like(
    $stdout, qr/--maximum-line-length=120/,
    'Long option names are preserved and formatted correctly'
  );
}

# Test 9: Options with special characters in values
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'special-chars.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Options with special characters exit with code 0' );

  # Special characters should be handled correctly
  like(
    $stdout, qr/--maximum-line-length=120/,
    'Options with special characters are preserved'
  );
}

# Test 10: RC file with mixed valid and invalid options
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=8\n";  # Valid
  print {$fh} "--invalid-option=value\n";     # Invalid
  print {$fh} "--maximum-line-length=120\n";  # Valid
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  # One unknown option makes Perl::Tidy reject the whole file, so the valid
  # options are not emitted either. Red if the unknown option is silently
  # dropped and the rest processed, or the error does not name it.
  isnt( $exit_code, 0, 'Mixed RC file exits non-zero' );
  like( $stdout, qr/invalid-option/, 'Mixed RC file names the invalid option' );
  unlike( $stdout, qr/^--indent-columns=8/m, 'Mixed RC file emits no options' );
}

# ============================================================================
# Error Handling
# ============================================================================

# Test 11: Dies if --rc and --no-rc both specified
# (Already tested in usage.t, but verify here too)
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=8\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile --no-rc 2>&1`;
  my $exit_code = $? >> 8;

  isnt( $exit_code, 0, 'Dies if --rc and --no-rc both specified' );
  like(
    $stdout, qr/mutually exclusive/i,
    'Error message mentions mutually exclusive'
  );
}

# Test 12: Dies if -o without filename
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=8\n";
  close $fh;

  # Try -o without filename (followed by another option)
  my $stdout    = `$script --rc $tmpfile -o --quiet 2>&1`;
  my $exit_code = $? >> 8;

  # extract_outfile refuses an option-looking word as the filename. Red if
  # --quiet is taken as the output path, or the error stops naming the cause.
  isnt( $exit_code, 0, 'Dies if -o without filename' );
  like( $stdout, qr/--outfile or -o requires a filename/, 'Error message says -o requires a filename' );
}

# Test 13: Dies if cannot write output file
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=8\n";
  close $fh;

  # Try to write to a non-existent directory
  my $bad_outfile = '/nonexistent/directory/file.out';

  my $stdout    = `$script --rc $tmpfile --outfile $bad_outfile 2>&1`;
  my $exit_code = $? >> 8;

  # write_output dies naming the path. Red if the open failure is ignored
  # and the script exits 0.
  isnt( $exit_code, 0, 'Dies if cannot write output file' );
  like(
    $stdout, qr{Cannot open /nonexistent/directory/file[.]out for writing},
    'Error message names the unwritable output file'
  );
}

# Test 14: Reports Perl::Tidy errors correctly
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );

  # Add an option that Perl::Tidy doesn't recognize
  print {$fh} "--completely-invalid-option-name=value\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  # Perl::Tidy rejects the unknown option and the script dies with its
  # message. Red if the error is swallowed, or no longer names the option.
  isnt( $exit_code, 0, 'Perl::Tidy error exits non-zero' );
  like( $stdout, qr/completely-invalid-option-name/, 'Reports the option Perl::Tidy rejected' );
}

# Test 15: Reports "No configuration parameters remain" when appropriate
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );

  # Use only default values
  print {$fh} "--indent-columns=4\n";  # If this is default
  close $fh;

  # indent-columns=4 is the Perl::Tidy default, so it is dropped and the
  # message goes to stderr with nothing on stdout. Red if the message moves
  # to stdout (it would land in an --outfile), or the default is emitted.
  my $stdout    = `$script --rc $tmpfile 2>/dev/null`;
  my $exit_code = $? >> 8;
  my $stderr    = `$script --rc $tmpfile 2>&1 1>/dev/null`;

  is( $exit_code, 0,   'No remaining parameters exits with code 0' );
  is( $stdout,    q{}, 'No remaining parameters writes nothing to stdout' );
  like( $stderr, qr/No configuration parameters remain/, 'Reports "No configuration parameters remain" on stderr' );
}

# Test 16: Handles RC file with only comments and whitespace
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "# Comment line\n";
  print {$fh} "   \n";                 # Whitespace
  print {$fh} "# Another comment\n";
  print {$fh} "\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'RC file with only comments exits with code 0' );

  # Same as Test 3 with whitespace-only lines added. Red if a whitespace
  # line is read as an option.
  like( $stdout, qr/No configuration parameters remain/, 'RC file with only comments reports no parameters' );
  unlike( $stdout, qr/^--/m, 'RC file with only comments emits no options' );
}

# Test 17: Handles RC file path with spaces
{
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $rcfile = File::Spec->catfile( $tmpdir, 'file with spaces.rc' );
  open my $fh, '>', $rcfile or die "Cannot create $rcfile: $!";
  print {$fh} "--indent-columns=8\n";
  close $fh;

  # Use shell escaping for filename with spaces
  my $escaped_file = $rcfile;
  $escaped_file =~ s/ /\\ /g;
  my $stdout    = `$script --rc $escaped_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'RC file path with spaces exits with code 0' );
  like(
    $stdout, qr/--indent-columns=8/,
    'RC file path with spaces is handled correctly'
  );
}

# Test 18: Handles very large RC file
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );

  # Create a large RC file with many options
  for my $i ( 1 .. 100 ) {
    print {$fh} "--indent-columns=$i\n";
  }
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Very large RC file exits with code 0' );

  # One hundred settings of one option collapse to the last. Red if any
  # earlier value is emitted, or the option is emitted more than once.
  my @indent = $stdout =~ /^--indent-columns=(\d+)/mg;
  is_deeply( \@indent, [100], 'Very large RC file emits indent-columns once, with the last value' );
}

# Test 19: Handles RC file with duplicate options (last one wins)
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=4\n";
  print {$fh} "--indent-columns=8\n";  # Duplicate, should override
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'RC file with duplicate options exits with code 0' );

  # Red if the first value wins, or both are emitted.
  my @indent = $stdout =~ /^--indent-columns=(\d+)/mg;
  is_deeply( \@indent, [8], 'RC file with duplicate options uses last value' );
}

# Test 20: Handles empty string values
#
# character-encoding is a string option. Perl::Tidy refuses it with an empty
# value ("requires an argument"), and the script passes that refusal on.
# (output-encoding, used here before, is not a Perl::Tidy option, so it only
# ever exercised the unknown-option path.) Red if the empty value is
# accepted and the script exits 0, or the error stops naming the option.
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--character-encoding=\n";
  close $fh;

  my $stdout    = `$script --rc $tmpfile 2>&1`;
  my $exit_code = $? >> 8;

  isnt( $exit_code, 0, 'RC file with an empty string value exits non-zero' );
  like( $stdout, qr/character-encoding/, 'RC file with an empty string value names the option' );
}

done_testing();
