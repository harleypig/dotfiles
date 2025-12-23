#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the section_order function from bin/perltidyrc-clean
#
# We use load_perltidyrc_clean() to load the script, which executes it but
# makes the function available for testing. This approach tests the actual
# function from the working code.

# Load the script - it will execute but exit quickly with --help
load_perltidyrc_clean();

# Test 1: Extracts numeric prefix from section name
is(section_order('1. Indentation'), 1, 'Extracts "1" from "1. Indentation"');
is(section_order('2. Whitespace control'), 2, 'Extracts "2" from "2. Whitespace control"');
is(section_order('10. Advanced options'), 10, 'Extracts "10" from "10. Advanced options"');

# Test 2: Handles decimal section numbers (e.g., "1.2")
is(section_order('1.2. Subsection'), 1.2, 'Extracts "1.2" from "1.2. Subsection"');
is(section_order('2.5. Another subsection'), 2.5, 'Extracts "2.5" from "2.5. Another subsection"');
is(section_order('10.3. Deep subsection'), 10.3, 'Extracts "10.3" from "10.3. Deep subsection"');

# Test 3: Returns 999 for sections without numeric prefix
is(section_order('UNKNOWN'), 999, 'Returns 999 for "UNKNOWN"');
is(section_order('No number here'), 999, 'Returns 999 for section without number');
is(section_order(''), 999, 'Returns 999 for empty string');
is(section_order('Text only'), 999, 'Returns 999 for text-only section');

# Test 4: Handles sections that start with non-numeric characters
is(section_order('A. Letter prefix'), 999, 'Returns 999 for letter prefix');
is(section_order('. Starts with dot'), 999, 'Returns 999 for dot prefix');

done_testing();

