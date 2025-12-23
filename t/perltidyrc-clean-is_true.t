#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the is_true function from bin/perltidyrc-clean
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

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

