#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Cmd;
use File::Spec;
use Cwd;

# Test the usage function behavior through script execution

my $script = File::Spec->catfile('bin', 'perltidyrc-clean');
plan tests => 8;

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

# Test 2: Mutually exclusive options trigger error
# --rc and --no-rc together should die with error message
$stdout = `$script --rc test.rc --no-rc 2>&1`;
$exit_code = $? >> 8;
isnt($exit_code, 0, 'Mutually exclusive options exit with non-zero code');
like($stdout, qr/mutually exclusive/i, 'Error message mentions mutually exclusive');

done_testing();

