# TODO: Test Suite for perltidyrc-clean

This document lists all functions and behaviors that need to be tested for
`bin/perltidyrc-clean`. Tests should use `Test::Cmd` since we'll need to test
with various RC files.

## Test Framework Setup

- [x] Use `Test::More` for test framework
- [x] Use `Test::Cmd` for script execution and file management
- [x] Create test RC files in `t/data/` directory
- [x] Test files should be named `t/perltidyrc-clean-*.t`

## Helper/Utility Functions

### `usage($exit_code)`
- [x] Prints usage message to stdout
- [x] Exits with correct exit code (0 for help, 1 for error)
- [x] Handles undefined exit_code (defaults to 0)

### `is_true($value)`
- [x] Returns 1 for positive integers (1-9 followed by digits)
- [x] Returns 1 for truthy values
- [x] Returns 0 for undefined values
- [x] Returns 0 for false values
- [x] Returns 0 for zero

### `looks_like_integer($value)` (replaces `looks_like_number`)
- [x] Returns true for positive integers
- [x] Returns true for negative integers
- [x] Returns false for decimal numbers
- [x] Returns false for undefined values
- [x] Returns false for non-numeric strings
- [x] Returns false for scientific notation (even if it represents an integer)
- [x] Uses Scalar::Util::looks_like_number internally

### `add_section_note($sections, $section_notes, $opt, $text)`
- [x] Adds note to correct section
- [x] Handles unknown options (uses 'UNKNOWN' section)
- [x] Appends multiple notes to same section

### `section_order($section)`
- [x] Extracts numeric prefix from section name
- [x] Returns 999 for sections without numeric prefix
- [x] Handles decimal section numbers (e.g., "1.2")

### `expand_abbrev($arg, $abbr)`
- [x] Expands short options to long names
- [x] Handles negated options (--no-*)
- [x] Preserves option values (=value)
- [x] Returns original arg if not in abbreviation hash
- [x] Handles single and double dashes

### `build_equals_default($opts, $defaults)`
- [ ] Identifies options that match defaults
- [ ] Handles undefined values correctly
- [ ] Compares string values correctly
- [ ] Returns hash with correct keys

### `extract_outfile($args)`
- [ ] Extracts `-o filename` format
- [ ] Extracts `--outfile filename` format
- [ ] Extracts `-ofilename` format
- [ ] Extracts `--outfile=filename` format
- [ ] Extracts `--outfilefilename` format (undocumented)
- [ ] Dies if `-o` or `--outfile` without filename
- [ ] Doesn't consume next arg if it's an option (starts with `-`)
- [ ] Removes outfile args from array
- [ ] Returns undef if no outfile specified

### `user_defined_abbreviations($abbrev, $abbrev_default)`
- [ ] Returns only abbreviations not in defaults
- [ ] Handles empty abbreviation hash
- [ ] Handles all abbreviations being defaults (returns empty)

## Processing Functions

### `condense_options($opts, $sections, $section_notes)`
- [ ] Removes brace-specific options that equal brace-tightness
- [ ] Adds section notes for removed options
- [ ] Removes continuation-indentation if equals indent-columns
- [ ] Adds section note for removed continuation-indentation
- [ ] Doesn't remove options that differ from general setting
- [ ] Handles missing general options gracefully

### `detect_conflicts($opts, $sections, $section_notes)`
- [ ] Detects conflict between brace-left-and-indent and non-indenting-braces
- [ ] Detects conflict between tabs and entab-leading-whitespace
- [ ] Detects when specific brace options differ from brace-tightness
- [ ] Detects when fuzzy-line-length exceeds maximum-line-length
- [ ] Detects format disabled but format-skipping enabled
- [ ] Adds section notes for all conflicts
- [ ] Handles missing section_notes hash (creates empty)

### `dump_options(%args)`
- [ ] Groups options by section
- [ ] Sorts sections by numeric order
- [ ] Outputs header comments when not quiet
- [ ] Outputs section headers when not quiet
- [ ] Outputs section notes within sections
- [ ] Formats options with correct prefixes (--, --no)
- [ ] Quotes non-numeric option values
- [ ] Pads default comments to column 40
- [ ] Outputs user-defined abbreviations section
- [ ] Writes to destination scalar ref when provided
- [ ] Writes to stdout when destination not provided
- [ ] Handles quiet mode (no headers)

### `read_perltidyrc($config_file, $perltidy_args, $expand_options)`
- [ ] Reads default options when config_file is empty scalar ref
- [ ] Reads options from specified RC file
- [ ] Uses Perl::Tidy search when config_file is undef
- [ ] Expands short options when expand_options is true
- [ ] Passes perltidy_args to Perl::Tidy
- [ ] Returns error message on Perl::Tidy errors
- [ ] Returns all required data structures
- [ ] Handles empty perltidy_args array
- [ ] Only includes perltidyrc parameter when config_file is defined

### `set_keep_defaults()`
- [ ] Sets drop_defaults to 0
- [ ] Sets keep_defaults to 1

### `set_add_missing_defaults()`
- [ ] Sets add_missing_defaults to 1
- [ ] Sets drop_defaults to 0
- [ ] Sets keep_defaults to 1
- [ ] Sets condense to 0

## Main Script Behavior (Integration Tests)

### Command-Line Argument Parsing
- [ ] `--rc FILE` loads specified RC file
- [ ] `--no-rc` uses empty config
- [ ] `--keep-defaults` keeps default options
- [ ] `--add-missing-defaults` adds missing defaults
- [ ] `--condense` condenses options (default)
- [ ] `--no-condense` disables condensing
- [ ] `--expand-options` expands short options (default)
- [ ] `--no-expand-options` disables expansion
- [ ] `--quiet` omits header comments
- [ ] `--help` shows usage and exits
- [ ] `--rc` and `--no-rc` are mutually exclusive (dies)
- [ ] Unknown options are passed to Perl::Tidy
- [ ] Perl::Tidy errors are reported correctly

### File I/O
- [ ] Reads RC file from `--rc FILE`
- [ ] Searches for RC file when no `--rc` specified
- [ ] Writes output to file with `-o FILE`
- [ ] Writes output to file with `--outfile FILE`
- [ ] Writes output to stdout when no outfile
- [ ] Handles file write errors gracefully
- [ ] Creates output file if it doesn't exist

### Option Processing Logic
- [ ] Default behavior: removes options matching defaults
- [ ] `--keep-defaults`: keeps all options including defaults
- [ ] `--add-missing-defaults`: adds missing defaults, keeps existing
- [ ] `--no-rc`: starts from defaults, overlays passed options
- [ ] Condensing removes duplicate fine-grained options
- [ ] Conflict detection adds section notes
- [ ] User-defined abbreviations are preserved

### Output Formatting
- [ ] Options grouped by section
- [ ] Sections sorted numerically
- [ ] Default comments padded to column 40
- [ ] Section notes appear in correct sections
- [ ] Header includes date, cmdline, and source
- [ ] Quiet mode omits headers

### Edge Cases
- [ ] Empty RC file
- [ ] RC file with only defaults (all removed)
- [ ] RC file with no valid options
- [ ] RC file with conflicts
- [ ] RC file with user abbreviations
- [ ] No RC file found (uses defaults)
- [ ] RC file with invalid syntax (Perl::Tidy error)
- [ ] Very long option names (padding still works)
- [ ] Options with special characters in values

### Error Handling
- [ ] Dies if Perl::Tidy not installed
- [ ] Dies if Perl::Tidy version too old
- [ ] Dies if `--rc` and `--no-rc` both specified
- [ ] Dies if `-o` without filename
- [ ] Dies if cannot write output file
- [ ] Reports Perl::Tidy errors correctly
- [ ] Reports "No configuration parameters remain" when appropriate

## Test Data Files Needed

Create test RC files in `t/data/`:

- [ ] `empty.rc` - Empty RC file
- [ ] `defaults-only.rc` - Only default options
- [ ] `custom.rc` - Custom non-default options
- [ ] `conflicts.rc` - Options with conflicts
- [ ] `abbreviations.rc` - User-defined abbreviations
- [ ] `condense.rc` - Options that can be condensed
- [ ] `long-names.rc` - Options with very long names
- [ ] `special-chars.rc` - Options with special characters
- [ ] `invalid.rc` - Invalid RC syntax (for error testing)

