#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Cmd;
use File::Spec;
use Cwd;
use File::Temp qw(tempfile);

# Test the usage function behavior through script execution

my $script = File::Spec->catfile('bin', 'perltidyrc-clean');

# Create Test::Cmd object for file management (we'll use it for RC files later)
my $cmd = Test::Cmd->new(
    prog    => $script,
    workdir => '',
);

# Test 1: --help prints usage message to stdout and exits with code 0
# Use backticks for reliable output capture
my $stdout = `$script --help 2>&1`;
my $exit_code = $? >> 8;
is($exit_code, 0, '--help exits with code 0');
like($stdout, qr/perltidyrc-clean/, 'Usage message contains script name');
like($stdout, qr/--rc FILE/, 'Usage message contains --rc option');
like($stdout, qr/--no-rc/, 'Usage message contains --no-rc option');
like($stdout, qr/--keep-defaults/, 'Usage message contains --keep-defaults option');
like($stdout, qr/--add-missing-defaults/, 'Usage message contains --add-missing-defaults option');
like($stdout, qr/--showconfig/, 'Usage message contains --showconfig option');
like($stdout, qr/--overwrite/, 'Usage message contains --overwrite option');

# Test 2: Mutually exclusive options trigger error
# --rc and --no-rc together should die with error message
$stdout = `$script --rc test.rc --no-rc 2>&1`;
$exit_code = $? >> 8;
isnt($exit_code, 0, 'Mutually exclusive options exit with non-zero code');
like($stdout, qr/mutually exclusive/i, 'Error message mentions mutually exclusive');

# Test 3: --overwrite requires --rc
$stdout = `$script --overwrite 2>&1`;
$exit_code = $? >> 8;
isnt($exit_code, 0, '--overwrite without --rc exits with non-zero code');
like($stdout, qr/--overwrite requires --rc/, 'Error message mentions --rc requirement');

# Test 4: --overwrite and --outfile are mutually exclusive
my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
print $fh "# test\n";
close $fh;
$stdout = `$script --rc $tmpfile --overwrite --outfile /tmp/other 2>&1`;
$exit_code = $? >> 8;
isnt($exit_code, 0, '--overwrite with --outfile exits with non-zero code');
like($stdout, qr/mutually exclusive/i, 'Error message mentions mutually exclusive');

# Test 5: --showconfig takes precedence over --overwrite (exits early)
$stdout = `$script --rc $tmpfile --showconfig --overwrite 2>&1`;
$exit_code = $? >> 8;
is($exit_code, 0, '--showconfig with --overwrite exits with code 0');
# Should show config location, not overwrite (output should be a file path or "none")
like($stdout, qr/^\/.*\n$|^none\n$/, '--showconfig shows config location, ignores --overwrite');
unlike($stdout, qr/perltidy configuration file created/, '--showconfig does not process config');

# Test 6: --showconfig takes precedence over other options
$stdout = `$script --rc $tmpfile --showconfig --keep-defaults --condense --quiet 2>&1`;
$exit_code = $? >> 8;
is($exit_code, 0, '--showconfig with other options exits with code 0');
# Should show config location, not process options
like($stdout, qr/^\/.*\n$|^none\n$/, '--showconfig shows config location, ignores other options');
unlike($stdout, qr/perltidy configuration file created/, '--showconfig does not process config');

done_testing();

