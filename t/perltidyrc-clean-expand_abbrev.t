#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the expand_abbrev function from bin/perltidyrc-clean
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Set up abbreviation hash for testing
my %abbr = (
    'i' => 'indent-columns',
    'l' => 'line-length',
    'n' => 'nologfile',
    'q' => 'quiet',
);

# Test 1: Expands short options to long names (single dash)
is(expand_abbrev('-i', \%abbr), '--indent-columns', 'Expands -i to --indent-columns');
is(expand_abbrev('-l', \%abbr), '--line-length', 'Expands -l to --line-length');
is(expand_abbrev('-q', \%abbr), '--quiet', 'Expands -q to --quiet');

# Test 2: Expands short options to long names (double dash)
is(expand_abbrev('--i', \%abbr), '--indent-columns', 'Expands --i to --indent-columns');
is(expand_abbrev('--l', \%abbr), '--line-length', 'Expands --l to --line-length');

# Test 3: Handles negated options (--no-*)
is(expand_abbrev('-noi', \%abbr), '--noindent-columns', 'Expands -noi to --noindent-columns');
is(expand_abbrev('--noi', \%abbr), '--noindent-columns', 'Expands --noi to --noindent-columns');
is(expand_abbrev('-nol', \%abbr), '--noline-length', 'Expands -nol to --noline-length');

# Test 4: Preserves option values (=value)
is(expand_abbrev('-i=4', \%abbr), '--indent-columns=4', 'Preserves value: -i=4');
is(expand_abbrev('--i=8', \%abbr), '--indent-columns=8', 'Preserves value: --i=8');
is(expand_abbrev('-l=120', \%abbr), '--line-length=120', 'Preserves value: -l=120');
is(expand_abbrev('-noi=value', \%abbr), '--noindent-columns=value', 'Preserves value with negation');

# Test 5: Returns original arg if not in abbreviation hash
is(expand_abbrev('-x', \%abbr), '-x', 'Returns original for unknown short option');
is(expand_abbrev('--unknown', \%abbr), '--unknown', 'Returns original for unknown long option');
is(expand_abbrev('not-an-option', \%abbr), 'not-an-option', 'Returns original for non-option string');
is(expand_abbrev('', \%abbr), '', 'Returns original for empty string');

# Test 6: Handles options with underscores and numbers in names
my %abbr_complex = (
    'i2' => 'indent-columns-2',
    'l10' => 'line-length-10',
    'test_opt' => 'test-option',
);
is(expand_abbrev('-i2', \%abbr_complex), '--indent-columns-2', 'Handles numbers in abbreviation');
is(expand_abbrev('-l10', \%abbr_complex), '--line-length-10', 'Handles numbers in abbreviation');
is(expand_abbrev('-test_opt', \%abbr_complex), '--test-option', 'Handles underscores in abbreviation');

# Test 7: Handles options that don't match the pattern
is(expand_abbrev('plaintext', \%abbr), 'plaintext', 'Returns non-option text unchanged');
is(expand_abbrev('123', \%abbr), '123', 'Returns numeric string unchanged');

# Test 8: Handles edge cases with empty abbreviation hash
my %empty_abbr;
is(expand_abbrev('-i', \%empty_abbr), '-i', 'Returns original when abbreviation hash is empty');

done_testing();

