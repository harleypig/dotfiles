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
- [x] Includes `--showconfig` option in usage message
- [x] Includes `--overwrite` option in usage message
- [x] Documents difference between `--no-rc` and no config file found

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
- [x] Identifies options that match defaults
- [x] Handles undefined values correctly
- [x] Compares string values correctly
- [x] Returns hash with correct keys

### `extract_outfile($args)`
- [x] Extracts `-o filename` format
- [x] Extracts `--outfile filename` format
- [x] Extracts `-ofilename` format
- [x] Extracts `--outfile=filename` format
- [x] Extracts `--outfilefilename` format (undocumented)
- [x] Dies if `-o` or `--outfile` without filename
- [x] Doesn't consume next arg if it's an option (starts with `-`)
- [x] Removes outfile args from array
- [x] Returns undef if no outfile specified

### `user_defined_abbreviations($abbrev, $abbrev_default)`
- [x] Returns only abbreviations not in defaults
- [x] Handles empty abbreviation hash
- [x] Handles all abbreviations being defaults (returns empty)

## Processing Functions

### `condense_options($opts, $sections, $section_notes)`
- [x] Removes brace-specific options that equal brace-tightness
- [x] Adds section notes for removed options
- [x] Removes continuation-indentation if equals indent-columns
- [x] Adds section note for removed continuation-indentation
- [x] Doesn't remove options that differ from general setting
- [x] Handles missing general options gracefully

### `detect_conflicts($opts, $sections, $section_notes)`
- [x] Detects conflict between brace-left-and-indent and non-indenting-braces
- [x] Detects conflict between tabs and entab-leading-whitespace
- [x] Detects when specific brace options differ from brace-tightness
- [x] Detects when fuzzy-line-length exceeds maximum-line-length
- [x] Detects format disabled but format-skipping enabled
- [x] Adds section notes for all conflicts
- [x] Handles missing section_notes hash (creates empty)

### `dump_options(%args)`
- [x] Groups options by section
- [x] Sorts sections by numeric order
- [x] Outputs header comments when not quiet
- [x] Outputs section headers when not quiet
- [x] Outputs section notes within sections
- [x] Formats options with correct prefixes (--, --no-)
- [x] Quotes non-numeric option values
- [x] Pads default comments to column 40
- [x] Outputs user-defined abbreviations section
- [x] Writes to destination scalar ref when provided
- [x] Writes to stdout when destination not provided
- [x] Handles quiet mode (no headers)
- [x] Sorts options within sections alphabetically
- [x] Handles empty opts hash
- [x] Handles options without sections (uses UNKNOWN)
- [x] Handles multiple section notes
- [x] Handles empty string values
- [x] Handles special characters in values

### `read_perltidyrc($config_file, $perltidy_args, $expand_options)`
- [x] Reads default options when config_file is empty scalar ref
- [x] Reads options from specified RC file
- [x] Uses Perl::Tidy search when config_file is undef
- [x] Expands short options when expand_options is true
- [x] Passes perltidy_args to Perl::Tidy
- [x] Returns error message on Perl::Tidy errors
- [x] Returns all required data structures
- [x] Handles empty perltidy_args array
- [x] Only includes perltidyrc parameter when config_file is defined
- [x] Handles undef perltidy_args (defaults to empty array)
- [x] Reads abbreviations from RC file
- [x] Empty RC file returns empty opts
- [x] perltidy_args override RC file options
- [x] Expansion works with short options in perltidy_args

### `set_keep_defaults()`
- [x] Function exists and is callable
- [x] Can be called multiple times without error
- [x] Sets drop_defaults to 0 (verified through --keep-defaults integration tests)
- [x] Sets keep_defaults to 1 (verified through --keep-defaults integration tests)
- [x] Does not modify other cli values (verified through integration tests)

### `set_add_missing_defaults()`
- [x] Function exists and is callable
- [x] Can be called multiple times without error
- [x] Sets add_missing_defaults to 1 (verified through --add-missing-defaults integration tests)
- [x] Sets drop_defaults to 0 (verified through --add-missing-defaults integration tests)
- [x] Sets keep_defaults to 1 (verified through --add-missing-defaults integration tests)
- [x] Sets condense to 0 (verified through --add-missing-defaults integration tests)
- [x] Does not modify other cli values (verified through integration tests)

## Main Script Behavior (Integration Tests)

### Command-Line Argument Parsing
- [x] `--rc FILE` loads specified RC file
- [x] `--no-rc` uses empty config
- [x] `--keep-defaults` keeps default options
- [x] `--add-missing-defaults` adds missing defaults
- [x] `--condense` condenses options (default)
- [x] `--no-condense` disables condensing
- [x] `--expand-options` expands short options (default)
- [x] `--no-expand-options` disables expansion
- [x] `--quiet` omits header comments
- [x] `--showconfig` prints config file location and exits
- [x] `--overwrite` overwrites --rc file with cleaned output
- [x] `--help` shows usage and exits
- [x] `--rc` and `--no-rc` are mutually exclusive (dies)
- [x] `--overwrite` requires `--rc` to be specified (dies)
- [x] `--overwrite` and `--outfile` are mutually exclusive (dies)
- [x] `--showconfig` takes precedence over other options (exits early)
- [x] Unknown options are passed to Perl::Tidy
- [x] Perl::Tidy errors are reported correctly

### File I/O
- [x] Reads RC file from `--rc FILE`
- [x] Searches for RC file when no `--rc` specified
- [x] Writes output to file with `-o FILE`
- [x] Writes output to file with `--outfile FILE`
- [x] Writes output to `--rc` file with `--overwrite`
- [x] Writes output to stdout when no outfile
- [x] `--overwrite` overwrites existing RC file
- [x] Handles file write errors gracefully
- [x] Handles read-only file errors with `--overwrite`
- [x] Creates output file if it doesn't exist

### `--showconfig` Option Behavior
- [x] Prints "none" when no config file found
- [x] Prints "none" when `--no-rc` specified
- [x] Prints absolute path when `--rc FILE` specified
- [x] Converts relative paths to absolute
- [x] Handles PERLTIDY environment variable (file)
- [x] Handles PERLTIDY environment variable (directory)
- [x] Finds config in current directory
- [x] Finds config in home directory
- [x] Uses Perl::Tidy::find_config_file for accuracy
- [x] Exits with code 0
- [x] Ignores all other options (except --help)
- [x] `--help` takes precedence over `--showconfig`

### `--overwrite` Option Behavior
- [x] Overwrites `--rc` file with cleaned output
- [x] Works with `--keep-defaults`
- [x] Works with `--quiet` (omits headers)
- [x] Works with `--condense` and `--no-condense`
- [x] Works with relative paths for `--rc`
- [x] Preserves file permissions (or handles appropriately)
- [x] Does not overwrite when no options remain (prints to STDERR)
- [x] Produces no stdout output (writes to file only)
- [x] Sets `$cli{outfile}` internally for efficiency

### Option Processing Logic
- [x] Default behavior: removes options matching defaults
- [x] `--keep-defaults`: keeps all options including defaults
- [x] `--add-missing-defaults`: adds missing defaults, keeps existing
- [x] `--no-rc`: starts from defaults, overlays passed options
- [x] Condensing removes duplicate fine-grained options
- [x] Conflict detection adds section notes
- [x] User-defined abbreviations are preserved

### Output Formatting
- [x] Options grouped by section
- [x] Sections sorted numerically
- [x] Default comments padded to column 40
- [x] Section notes appear in correct sections
- [x] Header includes date, cmdline, and source
- [x] Quiet mode omits headers
- [x] Options within sections sorted alphabetically
- [x] Output format consistency (no duplicate sections)
- [x] Empty lines between sections
- [x] Abbreviations section appears after options

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
- [x] Dies if `--overwrite` without `--rc`
- [x] Dies if `--overwrite` and `--outfile` both specified
- [ ] Dies if `-o` without filename
- [ ] Dies if cannot write output file
- [x] Dies if cannot write to read-only file with `--overwrite`
- [ ] Reports Perl::Tidy errors correctly
- [ ] Reports "No configuration parameters remain" when appropriate
- [x] Reports "No configuration parameters remain" when using `--overwrite` with only defaults

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

