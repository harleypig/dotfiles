#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

# Test the is_true function from bin/perltidyrc-clean
#
# We use 'do' to load the script, which executes it but makes the function
# available for testing. We pass --help to make the script exit quickly.
# This approach tests the actual function from the working code.
#
# Alternative (Option 1): If the script's execution path becomes problematic
# (e.g., adds early checks that interfere with testing), we could switch to
# extracting the function definition from the file using regex and eval'ing
# it, which would test the function in isolation without executing the script.

plan tests => 10;

# Load the script - it will execute but exit quickly with --help
# We override exit to prevent the test from exiting when the script calls it
BEGIN {
    no warnings 'redefine';
    *CORE::GLOBAL::exit = sub { return; };
}
local @ARGV = ('--help');
do './bin/perltidyrc-clean';
die "Failed to load script: $@" if $@;

# Test 1: Returns 1 for positive integers (1-9 followed by digits)
is(is_true("1"), 1, 'Returns 1 for "1"');
is(is_true("2"), 1, 'Returns 1 for "2"');
is(is_true("10"), 1, 'Returns 1 for "10"');
is(is_true("123"), 1, 'Returns 1 for "123"');

# Test 2: Returns 1 for truthy values
is(is_true(1), 1, 'Returns 1 for numeric 1');
is(is_true("yes"), 1, 'Returns 1 for truthy string "yes"');

# Test 3: Returns 0 for undefined values
is(is_true(undef), 0, 'Returns 0 for undefined');

# Test 4: Returns 0 for false values
is(is_true(0), 0, 'Returns 0 for zero');
is(is_true(""), 0, 'Returns 0 for empty string');
is(is_true("0"), 0, 'Returns 0 for string "0"');

done_testing();

