#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw(looks_like_number);
use lib 't/lib';
use TestPerltidyrcClean;

# Test the looks_like_integer function from bin/perltidyrc-clean
# and verify Scalar::Util::looks_like_number behavior
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

plan tests => 23;

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Test looks_like_integer: Returns true for positive integers
is(looks_like_integer("1"), 1, 'looks_like_integer: Returns 1 for "1"');
is(looks_like_integer("123"), 1, 'looks_like_integer: Returns 1 for "123"');
is(looks_like_integer(42), 1, 'looks_like_integer: Returns 1 for numeric 42');

# Test looks_like_integer: Returns true for negative integers
is(looks_like_integer("-1"), 1, 'looks_like_integer: Returns 1 for "-1"');
is(looks_like_integer("-123"), 1, 'looks_like_integer: Returns 1 for "-123"');
is(looks_like_integer(-42), 1, 'looks_like_integer: Returns 1 for numeric -42');

# Test looks_like_integer: Returns false for decimal numbers
is(looks_like_integer("1.5"), 0, 'looks_like_integer: Returns 0 for "1.5"');
is(looks_like_integer("123.45"), 0, 'looks_like_integer: Returns 0 for "123.45"');
is(looks_like_integer(3.14), 0, 'looks_like_integer: Returns 0 for numeric 3.14');

# Test looks_like_integer: Returns false for undefined values
is(looks_like_integer(undef), 0, 'looks_like_integer: Returns 0 for undefined');

# Test looks_like_integer: Returns false for non-numeric strings
is(looks_like_integer("abc"), 0, 'looks_like_integer: Returns 0 for "abc"');
is(looks_like_integer(""), 0, 'looks_like_integer: Returns 0 for empty string');

# Test looks_like_integer: Returns false for scientific notation (number but not integer)
is(looks_like_integer("1e10"), 0, 'looks_like_integer: Returns 0 for scientific notation "1e10"');
is(looks_like_integer("1.5e2"), 0, 'looks_like_integer: Returns 0 for scientific notation "1.5e2"');

# Test Scalar::Util::looks_like_number: Returns true for positive integers
ok(looks_like_number("1"), 'looks_like_number: Returns true for "1"');
ok(looks_like_number("123"), 'looks_like_number: Returns true for "123"');

# Test Scalar::Util::looks_like_number: Returns true for negative integers
ok(looks_like_number("-1"), 'looks_like_number: Returns true for "-1"');

# Test Scalar::Util::looks_like_number: Returns true for decimal numbers
ok(looks_like_number("1.5"), 'looks_like_number: Returns true for "1.5"');
ok(looks_like_number("123.45"), 'looks_like_number: Returns true for "123.45"');

# Test Scalar::Util::looks_like_number: Returns false for undefined values
ok(!looks_like_number(undef), 'looks_like_number: Returns false for undefined');

# Test Scalar::Util::looks_like_number: Returns false for non-numeric strings
ok(!looks_like_number("abc"), 'looks_like_number: Returns false for "abc"');

# Test Scalar::Util::looks_like_number: Returns true for scientific notation
ok(looks_like_number("1e10"), 'looks_like_number: Returns true for scientific notation "1e10"');
ok(looks_like_number("1.5e2"), 'looks_like_number: Returns true for scientific notation "1.5e2"');

done_testing();

