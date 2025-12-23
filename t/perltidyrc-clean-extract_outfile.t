#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the extract_outfile function from bin/perltidyrc-clean
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Test 1: Extracts `-o filename` format
{
    my @args = ('-o', 'output.txt', '--other-option');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'output.txt', 'Extracts -o filename format');
    is_deeply(\@args, ['--other-option'], 'Removes -o and filename from args');
}

# Test 2: Extracts `--outfile filename` format
{
    my @args = ('--outfile', 'result.txt', '--option');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'result.txt', 'Extracts --outfile filename format');
    is_deeply(\@args, ['--option'], 'Removes --outfile and filename from args');
}

# Test 3: Extracts `-ofilename` format
{
    my @args = ('-otest.txt', '--other');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'test.txt', 'Extracts -ofilename format');
    is_deeply(\@args, ['--other'], 'Removes -ofilename from args');
}

# Test 4: Extracts `--outfile=filename` format
{
    my @args = ('--outfile=output.txt', '--option');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'output.txt', 'Extracts --outfile=filename format');
    is_deeply(\@args, ['--option'], 'Removes --outfile=filename from args');
}

# Test 5: Extracts `--outfilefilename` format (undocumented)
{
    my @args = ('--outfiletest.txt', '--option');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'test.txt', 'Extracts --outfilefilename format');
    is_deeply(\@args, ['--option'], 'Removes --outfilefilename from args');
}

# Test 6: Dies if `-o` without filename
{
    my @args = ('-o');
    eval { extract_outfile(\@args) };
    like($@, qr/Error: --outfile or -o requires a filename/, 'Dies if -o without filename');
}

# Test 7: Dies if `--outfile` without filename
{
    my @args = ('--outfile');
    eval { extract_outfile(\@args) };
    like($@, qr/Error: --outfile or -o requires a filename/, 'Dies if --outfile without filename');
}

# Test 8: Dies if `-o` followed by option (starts with `-`)
{
    my @args = ('-o', '--no-rc', '--other');
    eval { extract_outfile(\@args) };
    like($@, qr/Error: --outfile or -o requires a filename/, 'Dies if -o followed by option');
    is_deeply(\@args, ['--no-rc', '--other'], 'Does not consume option after -o');
}

# Test 9: Dies if `--outfile` followed by option
{
    my @args = ('--outfile', '--help', '--other');
    eval { extract_outfile(\@args) };
    like($@, qr/Error: --outfile or -o requires a filename/, 'Dies if --outfile followed by option');
    is_deeply(\@args, ['--help', '--other'], 'Does not consume option after --outfile');
}

# Test 10: Removes outfile args from array
{
    my @args = ('--option1', '-o', 'file.txt', '--option2');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'file.txt', 'Extracts outfile correctly');
    is_deeply(\@args, ['--option1', '--option2'], 'Removes -o and filename from middle of args');
}

# Test 11: Returns undef if no outfile specified
{
    my @args = ('--option1', '--option2');
    my $outfile = extract_outfile(\@args);
    is($outfile, undef, 'Returns undef if no outfile specified');
    is_deeply(\@args, ['--option1', '--option2'], 'Args unchanged when no outfile');
}

# Test 12: Handles multiple outfile options (takes last)
{
    my @args = ('-o', 'first.txt', '-o', 'second.txt');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'second.txt', 'Takes last outfile when multiple present');
    is_deeply(\@args, [], 'Removes all outfile options');
}

# Test 13: Handles empty array
{
    my @args = ();
    my $outfile = extract_outfile(\@args);
    is($outfile, undef, 'Returns undef for empty array');
    is_deeply(\@args, [], 'Empty array remains empty');
}

# Test 14: Handles filename with spaces (extracts only first word)
{
    my @args = ('-o', 'file', 'with', 'spaces.txt', '--option');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'file', 'Extracts only first word when filename has spaces');
    is_deeply(\@args, ['with', 'spaces.txt', '--option'], 'Removes -o and first word only');
}

# Test 15: `-o filename` as last argument (no following options)
{
    my @args = ('-o', 'output.txt');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'output.txt', 'Extracts -o filename when it is the last argument');
    is_deeply(\@args, [], 'Removes -o and filename, leaves empty array');
}

# Test 16: `--outfile filename` as last argument (no following options)
{
    my @args = ('--outfile', 'result.txt');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'result.txt', 'Extracts --outfile filename when it is the last argument');
    is_deeply(\@args, [], 'Removes --outfile and filename, leaves empty array');
}

# Test 17: `-o 'filename with spaces'` (quoted filename with spaces as single argument)
{
    my @args = ('-o', 'filename with spaces.txt');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'filename with spaces.txt', 'Extracts entire quoted filename with spaces');
    is_deeply(\@args, [], 'Removes -o and quoted filename');
}

# Test 18: `--outfile 'filename with spaces'` (quoted filename with spaces as single argument)
{
    my @args = ('--outfile', 'filename with spaces.txt');
    my $outfile = extract_outfile(\@args);
    is($outfile, 'filename with spaces.txt', 'Extracts entire quoted filename with spaces');
    is_deeply(\@args, [], 'Removes --outfile and quoted filename');
}

done_testing();

