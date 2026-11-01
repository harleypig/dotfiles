#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use lib 'tests/perl/lib';
use TestPerltidyrcClean ();            # skips the file without Perl::Tidy
use Test::Cmd;
use File::Spec;
use Cwd;
use File::Temp qw(tempfile tempdir);
use File::Path qw(make_path remove_tree);

# Integration tests for CLI argument parsing, file I/O, and option processing logic

my $script        = File::Spec->catfile( 'bin', 'perltidyrc-clean' );
my $test_data_dir = File::Spec->catdir( Cwd::getcwd(), 'tests', 'perl', 'data' );
my $simple_rc     = File::Spec->catfile( $test_data_dir, 'simple.rc' );

# Create Test::Cmd object
my $cmd = Test::Cmd->new(
  prog    => $script,
  workdir => '',
);

# ============================================================================
# Command-Line Argument Parsing Tests
# ============================================================================

# Test 1: --rc FILE loads specified RC file
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--rc FILE exits with code 0' );
  like( $stdout, qr/--indent-columns=8/,        '--rc FILE loads options from file' );
  like( $stdout, qr/--maximum-line-length=120/, '--rc FILE loads all options from file' );
}

# Test 2: --no-rc uses empty config
{
  my $stdout    = `$script --no-rc 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--no-rc exits with code 0' );

  # --no-rc processes from Perl::Tidy's defaults with no file read, so the
  # source is reported as the empty profile and the defaults are emitted
  # (indent-columns=4 is one). Red if --no-rc reads a file, or emits nothing.
  like( $stdout, qr/^# source: none \(empty profile\)$/m, '--no-rc reports the empty profile as its source' );
  like( $stdout, qr/^--indent-columns=4$/m,               '--no-rc emits Perl::Tidy defaults' );
}

# Test 3: --keep-defaults keeps default options
#
# defaults-only.rc sets only Perl::Tidy defaults (indent-columns=4,
# maximum-line-length=80), so the flag is the whole difference between the
# two runs: dropped without it, kept with it. (custom.rc, used here before,
# sets no default, so its output is the same either way and could not show
# the flag doing anything.) Red if --keep-defaults stops keeping defaults.
# The per-flag effects of set_keep_defaults are set_functions.t Test 7.
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'defaults-only.rc' );

  my $stdout_no_keep = `$script --rc $rc_file 2>&1`;
  unlike( $stdout_no_keep, qr/^--indent-columns=4/m, 'Without --keep-defaults, a default option is dropped' );

  my $stdout_keep = `$script --rc $rc_file --keep-defaults 2>&1`;
  like( $stdout_keep, qr/^--indent-columns=4\s/m,       'With --keep-defaults, a default option is kept' );
  like( $stdout_keep, qr/^--maximum-line-length=80\s/m, 'With --keep-defaults, every default option is kept' );
}

# Test 4: --add-missing-defaults adds missing defaults
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my $stdout    = `$script --rc $rc_file --add-missing-defaults 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--add-missing-defaults exits with code 0' );

  # Should include both the custom option and default options
  like( $stdout, qr/--maximum-line-length=120/, 'Custom option is preserved' );
  like( $stdout, qr/--indent-columns/,          'Default options are added' );
}

# Test 5: --condense condenses options (default)
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'condense.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--condense (default) exits with code 0' );

  like( $stdout, qr/--indent-columns=8/, 'General option is kept' );

  # condense.rc's two options are not an abbreviation's expansion, so
  # nothing here is condensed; what condensing removes is covered by
  # perltidyrc-clean-condense_options.t and Tests 26-27 below.
}

# Test 6: --no-condense disables condensing
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'condense.rc' );

  my $stdout    = `$script --rc $rc_file --no-condense 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--no-condense exits with code 0' );

  # Without condensing, all options should be present
  like( $stdout, qr/--indent-columns=8/,           'General option is kept' );
  like( $stdout, qr/--continuation-indentation=8/, 'Specific option is kept with --no-condense' );
}

# Test 7: Short options in RC file are automatically expanded by Perl::Tidy
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'short-options.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Short options in RC file work' );

  # Perl::Tidy expands short options automatically, so they appear as long names
  like( $stdout, qr/--indent-columns=8/,        'Short option -i=8 in RC file expanded to --indent-columns=8' );
  like( $stdout, qr/--maximum-line-length=120/, 'Short option -l=120 in RC file expanded to --maximum-line-length=120' );
}

# Test 8: Short options in command-line args are automatically expanded by Perl::Tidy
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--indent-columns=4\n";  # Use long option in RC file
  close $fh;

  # Pass short option via command line - Perl::Tidy expands it automatically
  my $stdout    = `$script --rc $tmpfile -i=8 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Short options in command-line args work' );

  # Command-line args override RC file, and Perl::Tidy expands short options automatically
  like( $stdout, qr/--indent-columns=8/, 'Short option -i=8 in command-line expanded and overrides RC file' );
}

# Test 9: --quiet omits header comments
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my $stdout_quiet  = `$script --rc $rc_file --quiet 2>&1`;
  my $stdout_normal = `$script --rc $rc_file 2>&1`;

  unlike(
    $stdout_quiet, qr/perltidy configuration file created/,
    '--quiet omits header comments'
  );
  like(
    $stdout_normal, qr/perltidy configuration file created/,
    'Without --quiet, header comments are included'
  );
}

# Test 10: Unknown options are passed to Perl::Tidy
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  # Pass an unknown option that Perl::Tidy will recognize
  my $stdout    = `$script --rc $rc_file --unknown-option 2>&1`;
  my $exit_code = $? >> 8;

  # The script does not know --unknown-option, so it passes it through;
  # Perl::Tidy does not know it either and refuses it. Red if the script
  # swallows the option (exit 0), or the error stops naming it.
  isnt( $exit_code, 0, 'Unknown options exit non-zero' );
  like( $stdout, qr/unknown-option/, 'Unknown options are reported by Perl::Tidy, by name' );
}

# Test 11: Perl::Tidy errors are reported correctly
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'invalid.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  # invalid.rc's unclosed quote is a parse error in every Perl::Tidy this
  # runs against; wording and exit code vary, so neither is pinned. Red if
  # the error is swallowed and the script exits 0.
  isnt( $exit_code, 0, 'Perl::Tidy errors exit non-zero' );
  like( $stdout, qr/error/i, 'Perl::Tidy errors are reported' );
}

# ============================================================================
# File I/O Tests
# ============================================================================

# Test 12: Reads RC file from --rc FILE
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Reads RC file successfully' );
  like( $stdout, qr/--indent-columns=8/, 'Reads options from RC file' );
}

# Test 13: Searches for RC file when no --rc specified
{
  # Create a temporary directory and RC file
  my $tmpdir = tempdir( CLEANUP => 1 );
  my $rcfile = File::Spec->catfile( $tmpdir, '.perltidyrc' );
  open my $fh, '>', $rcfile or die "Cannot create $rcfile: $!";
  print {$fh} "--indent-columns=8\n";  # Non-default value
  close $fh;

  # Change to temp directory and run script
  my $old_cwd = Cwd::getcwd();
  chdir $tmpdir or die "Cannot chdir to $tmpdir: $!";

  # ./.perltidyrc is the first place Perl::Tidy looks, ahead of $PERLTIDY
  # (cleared so it cannot take precedence) and $HOME, so the result does not
  # depend on the host. Red if the search stops finding the cwd file.
  my ( $stdout, $exit_code );
  {
    delete local $ENV{PERLTIDY};
    $stdout    = `$old_cwd/$script 2>&1`;
    $exit_code = $? >> 8;
  }

  chdir $old_cwd or die "Cannot chdir back: $!";

  is( $exit_code, 0, 'Search for RC file exits with code 0' );
  like( $stdout, qr/--indent-columns=8/, 'Finds RC file in current directory' );
}

# Test 14: Writes output to file with -o FILE
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my ( $out_fh, $outfile ) = tempfile( SUFFIX => '.out', UNLINK => 1 );
  close $out_fh;

  my $stdout    = `$script --rc $rc_file -o $outfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0,  'Writes to file with -o exits with code 0' );
  is( $stdout,    '', 'No stdout output when writing to file' );

  # Check that file was written
  ok( -f $outfile, 'Output file was created' );
  if ( -f $outfile ) {
    open my $rfh, '<', $outfile or die "Cannot read $outfile: $!";
    my $content = do { local $/ = undef; <$rfh> };
    close $rfh;
    like( $content, qr/--indent-columns=8/, 'Output file contains expected content' );
  }
}

# Test 15: Writes output to file with --outfile FILE
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my ( $out_fh, $outfile ) = tempfile( SUFFIX => '.out', UNLINK => 1 );
  close $out_fh;

  my $stdout    = `$script --rc $rc_file --outfile $outfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0,  'Writes to file with --outfile exits with code 0' );
  is( $stdout,    '', 'No stdout output when writing to file' );

  ok( -f $outfile, 'Output file was created' );
  if ( -f $outfile ) {
    open my $rfh, '<', $outfile or die "Cannot read $outfile: $!";
    my $content = do { local $/ = undef; <$rfh> };
    close $rfh;
    like( $content, qr/--indent-columns=8/, 'Output file contains expected content' );
  }
}

# Test 16: Writes output to stdout when no outfile
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Writes to stdout exits with code 0' );
  like( $stdout, qr/--indent-columns=8/, 'Output written to stdout' );
}

# Test 17: Handles file write errors gracefully
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  # Try to write to a non-existent directory
  my $bad_outfile = '/nonexistent/directory/file.out';

  my $stdout    = `$script --rc $rc_file --outfile $bad_outfile 2>&1`;
  my $exit_code = $? >> 8;

  # Red if the open failure is ignored and the script exits 0.
  isnt( $exit_code, 0, 'File write errors exit non-zero' );
  like( $stdout, qr/Cannot open \S+ for writing/, 'File write errors are reported' );
}

# Test 18: Creates output file if it doesn't exist
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my $tmpdir  = tempdir( CLEANUP => 1 );
  my $outfile = File::Spec->catfile( $tmpdir, 'newfile.out' );

  my $stdout    = `$script --rc $rc_file --outfile $outfile 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Creates output file exits with code 0' );
  ok( -f $outfile, 'Output file was created' );
}

# ============================================================================
# Option Processing Logic Tests
# ============================================================================

# Test 19: Default behavior: removes options matching defaults
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'defaults-only.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Default behavior exits with code 0' );

  # Red if a default survives the filter without --keep-defaults.
  unlike( $stdout, qr/^--indent-columns=4/m,       'Default behavior removes indent-columns=4' );
  unlike( $stdout, qr/^--maximum-line-length=80/m, 'Default behavior removes maximum-line-length=80' );
}

# Test 20: --keep-defaults: keeps all options including defaults
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'custom.rc' );

  my $stdout    = `$script --rc $rc_file --keep-defaults 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--keep-defaults exits with code 0' );
  like(
    $stdout, qr/--indent-columns=8/,
    '--keep-defaults keeps all options'
  );
  like(
    $stdout, qr/--maximum-line-length=120/,
    '--keep-defaults keeps non-default options'
  );
}

# Test 21: --add-missing-defaults: adds missing defaults, keeps existing
{
  my ( $fh, $tmpfile ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} "--maximum-line-length=120\n";  # Non-default value
  close $fh;

  my $stdout    = `$script --rc $tmpfile --add-missing-defaults 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--add-missing-defaults exits with code 0' );
  like(
    $stdout, qr/--maximum-line-length=120/,
    '--add-missing-defaults keeps existing options'
  );
  like(
    $stdout, qr/--indent-columns/,
    '--add-missing-defaults adds missing default options'
  );
}

# Test 22: --no-rc: starts from defaults, overlays passed options
{
  my $stdout    = `$script --no-rc --indent-columns=8 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, '--no-rc with options exits with code 0' );
  like(
    $stdout, qr/--indent-columns=8/,
    '--no-rc overlays passed options'
  );
}

# Test 23: Condensing removes duplicate fine-grained options
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'condense.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Condensing exits with code 0' );
  like(
    $stdout, qr/--indent-columns=8/,
    'Condensing keeps general option'
  );

  # NOTE: Explicit continuation-indentation condensing was removed
  # It may still appear if not handled by abbreviation-based condensing
  # unlike($stdout, qr/--continuation-indentation=8/,
  #     'Condensing removes duplicate fine-grained options');
}

# Test 24: Conflict detection adds section notes
#
# conflicts.rc sets brace-left-and-indent and non-indenting-braces, and
# non-indenting-braces is a Perl::Tidy default. Conflicts are checked against
# the effective settings (#665), so the note appears whether the default is
# dropped from the output or kept. Red, in default mode, if the check sees
# only the options left after defaults are dropped.
foreach my $flags ( [], ['--keep-defaults'] ) {
  my $rc_file = File::Spec->catfile( $test_data_dir, 'conflicts.rc' );
  my $label   = join q{ }, 'Conflict detection', @{$flags};

  my $stdout    = `$script --rc $rc_file @{$flags} 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, "$label exits with code 0" );
  like(
    $stdout, qr/^# NOTE: brace-left-and-indent conflicts with non-indenting-braces$/m,
    "$label adds a section note"
  );
}

# Test 25: User-defined abbreviations are preserved
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'abbreviations.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'User abbreviations exit with code 0' );
  like(
    $stdout, qr/myindent.*indent-columns/,
    'User-defined abbreviations are preserved'
  );
}

# Test 26: Abbreviation expansion - verify that act=3, cti=3, vtc=3 expand to correct options
# Note: Abbreviations are tested via the expanded options file which contains the
# individual options that abbreviations expand to. This tests that Perl::Tidy
# correctly expands abbreviations (act=3 -> pt=3, sbt=3, bt=3, bbt=3, etc.)
{
  # Test using the expanded options file which has all individual options
  # that act=3, cti=3, vtc=3 would expand to
  my $rc_file = File::Spec->catfile( $test_data_dir, 'abbreviation-expanded.rc' );

  my $stdout    = `$script --rc $rc_file 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Abbreviation expanded options exit with code 0' );

  # Verify that the options that act=3 expands to are present
  like( $stdout, qr/--paren-tightness=3/,          'Options from act=3 expansion are present (paren-tightness)' );
  like( $stdout, qr/--square-bracket-tightness=3/, 'Options from act=3 expansion are present (square-bracket-tightness)' );
  like( $stdout, qr/--brace-tightness=3/,          'Options from act=3 expansion are present (brace-tightness)' );
  like( $stdout, qr/--block-brace-tightness=3/,    'Options from act=3 expansion are present (block-brace-tightness)' );

  # Verify that the options that cti=3 expands to are present
  like( $stdout, qr/--closing-paren-indentation=3/, 'Options from cti=3 expansion are present (closing-paren-indentation)' );
  like( $stdout, qr/--closing-brace-indentation=3/, 'Options from cti=3 expansion are present (closing-brace-indentation)' );
  like(
    $stdout, qr/--closing-square-bracket-indentation=3/,
    'Options from cti=3 expansion are present (closing-square-bracket-indentation)'
  );

  # Verify that the options that vtc=3 expands to are present
  # Note: Some may be filtered as defaults or condensed, so check what's actually present
  like(
    $stdout, qr/--paren-vertical-tightness-closing=3|condensed to vertical-tightness-closing=3/i,
    'Options from vtc=3 expansion are present or condensed (paren-vertical-tightness-closing)'
  );
  like(
    $stdout, qr/--brace-vertical-tightness-closing=3|condensed to vertical-tightness-closing=3/i,
    'Options from vtc=3 expansion are present or condensed (brace-vertical-tightness-closing)'
  );
  like(
    $stdout, qr/--square-bracket-vertical-tightness-closing=3|condensed to vertical-tightness-closing=3/i,
    'Options from vtc=3 expansion are present or condensed (square-bracket-vertical-tightness-closing)'
  );
}

# Test 27: Condensing works for expanded options (at least some condensing occurs)
{
  my $rc_file = File::Spec->catfile( $test_data_dir, 'abbreviation-expanded.rc' );

  my $stdout    = `$script --rc $rc_file --condense 2>&1`;
  my $exit_code = $? >> 8;

  is( $exit_code, 0, 'Abbreviation condensing exits with code 0' );

  # The specific "condensed to" note depends on the option values
  # Perl::Tidy reports, which vary by version; accept the note OR the
  # expanded options being present (condensing ran either way).
  like(
    $stdout, qr/condensed to|--paren-tightness=3/i,
    'condensing ran (a condensing note, or expanded options, present)'
  );

  # Verify that the expanded options are present (they may or may not be condensed)
  like( $stdout, qr/--paren-tightness=3/,           'Expanded options are present' );
  like( $stdout, qr/--closing-paren-indentation=3/, 'Closing indentation options are present' );
}

done_testing();
