#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use TestPerltidyrcClean;

# Test the dump_options function

load_perltidyrc_clean();

# Test 1: Groups options by section
{
    my %opts = (
        'indent-columns' => '4',
        'maximum-line-length' => '80',
        'brace-tightness' => '2',
    );
    my %sections = (
        'indent-columns' => '1. Basic formatting',
        'maximum-line-length' => '1. Basic formatting',
        'brace-tightness' => '2. Brace formatting',
    );
    my %getopt_flags = (
        'indent-columns' => '=',
        'maximum-line-length' => '=',
        'brace-tightness' => '=',
    );
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    # Check that options are grouped by section
    my @lines = split /\n/, $output;
    my %section_groups;
    my $current_section;
    foreach my $line (@lines) {
        if ($line =~ /^--(\S+)/) {
            my $opt = $1;
            $opt =~ s/^no-//;  # Remove no- prefix if present
            $opt =~ s/=.*$//;  # Remove value if present
            if (exists $sections{$opt}) {
                $section_groups{$sections{$opt}}++;
            }
        }
    }
    
    ok(exists $section_groups{'1. Basic formatting'}, 'Options grouped by section: Basic formatting');
    ok(exists $section_groups{'2. Brace formatting'}, 'Options grouped by section: Brace formatting');
    is($section_groups{'1. Basic formatting'}, 2, 'Basic formatting section has 2 options');
    is($section_groups{'2. Brace formatting'}, 1, 'Brace formatting section has 1 option');
}

# Test 2: Sorts sections by numeric order
{
    my %opts = (
        'indent-columns' => '4',
        'brace-tightness' => '2',
        'maximum-line-length' => '80',
    );
    my %sections = (
        'indent-columns' => '1. Basic formatting',
        'brace-tightness' => '2. Brace formatting',
        'maximum-line-length' => '1. Basic formatting',
    );
    my %getopt_flags = (
        'indent-columns' => '=',
        'brace-tightness' => '=',
        'maximum-line-length' => '=',
    );
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    # Extract section order from output
    my @lines = split /\n/, $output;
    my @section_order;
    foreach my $line (@lines) {
        if ($line =~ /^--(\S+)/) {
            my $opt = $1;
            $opt =~ s/^no-//;
            $opt =~ s/=.*$//;
            if (exists $sections{$opt}) {
                push @section_order, $sections{$opt} unless @section_order && $section_order[-1] eq $sections{$opt};
            }
        }
    }
    
    is($section_order[0], '1. Basic formatting', 'Section 1 comes before section 2');
    is($section_order[1], '2. Brace formatting', 'Section 2 comes after section 1');
}

# Test 3: Outputs header comments when not quiet
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        destination => \$output,
        cmdline => 'test command',
        rc_origin => 'test source',
        quiet => 0,
    );
    
    like($output, qr/perltidy configuration file created/, 'Header contains creation date');
    like($output, qr/using: test command/, 'Header contains cmdline');
    like($output, qr/source: test source/, 'Header contains rc_origin');
}

# Test 4: Does not output header comments when quiet
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        destination => \$output,
        cmdline => 'test command',
        rc_origin => 'test source',
        quiet => 1,
    );
    
    unlike($output, qr/perltidy configuration file created/, 'Quiet mode omits header');
    unlike($output, qr/using: test command/, 'Quiet mode omits cmdline');
    unlike($output, qr/source: test source/, 'Quiet mode omits rc_origin');
}

# Test 5: Outputs section headers when not quiet
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 0,
    );
    
    like($output, qr/# Basic formatting/, 'Section header appears in output');
}

# Test 6: Does not output section headers when quiet
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    unlike($output, qr/# Basic formatting/, 'Quiet mode omits section headers');
}

# Test 7: Outputs section notes within sections
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my %section_notes = ('1. Basic formatting' => ['Test note']);
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        section_notes => \%section_notes,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 0,
    );
    
    like($output, qr/# NOTE: Test note/, 'Section notes appear in output');
}

# Test 8: Formats options with correct prefixes (--, --no-)
{
    my %opts = (
        'indent-columns' => '4',
        'tabs' => '0',  # false value should get --no-
    );
    my %sections = (
        'indent-columns' => '1. Basic formatting',
        'tabs' => '1. Basic formatting',
    );
    my %getopt_flags = (
        'indent-columns' => '=',
        'tabs' => '!',  # boolean flag
    );
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    like($output, qr/^--indent-columns=4/m, 'Regular option uses -- prefix');
    like($output, qr/^--no-tabs/m, 'False boolean option uses --no- prefix');
}

# Test 9: Formats true boolean options with -- prefix (not --no-)
{
    my %opts = ('tabs' => '1');
    my %sections = ('tabs' => '1. Basic formatting');
    my %getopt_flags = ('tabs' => '!');
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    like($output, qr/^--tabs/, 'True boolean option uses -- prefix');
    unlike($output, qr/^--no-tabs/, 'True boolean option does not use --no- prefix');
}

# Test 10: Quotes non-numeric option values
{
    my %opts = (
        'indent-columns' => '4',  # numeric, should not be quoted
        'maximum-line-length' => '80',  # numeric, should not be quoted
        'output-encoding' => 'utf8',  # non-numeric, should be quoted
    );
    my %sections = (
        'indent-columns' => '1. Basic formatting',
        'maximum-line-length' => '1. Basic formatting',
        'output-encoding' => '1. Basic formatting',
    );
    my %getopt_flags = (
        'indent-columns' => '=',
        'maximum-line-length' => '=',
        'output-encoding' => '=',
    );
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    like($output, qr/--indent-columns=4/, 'Numeric value not quoted');
    like($output, qr/--maximum-line-length=80/, 'Numeric value not quoted');
    like($output, qr/--output-encoding="utf8"/, 'Non-numeric value is quoted');
}

# Test 11: Pads default comments to column 40
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my %equals_default = ('indent-columns' => 1);
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        equals_default => \%equals_default,
        keep_defaults => 1,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    my @lines = split /\n/, $output;
    my $found_default = 0;
    foreach my $line (@lines) {
        if ($line =~ /--indent-columns=4\s+#\s+default/) {
            $found_default = 1;
            # Check padding - # should be at or after column 40
            # Find position of # character
            my $hash_pos = index($line, '#');
            ok($hash_pos >= 40, "Default comment padded (# at column $hash_pos, should be >= 40)");
        }
    }
    ok($found_default, 'Default comment appears in output');
}

# Test 12: Uses minimum 2 spaces padding for default comments
{
    my %opts = ('very-long-option-name-that-exceeds-forty-characters' => '4');
    my %sections = ('very-long-option-name-that-exceeds-forty-characters' => '1. Basic formatting');
    my %getopt_flags = ('very-long-option-name-that-exceeds-forty-characters' => '=');
    my %equals_default = ('very-long-option-name-that-exceeds-forty-characters' => 1);
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        equals_default => \%equals_default,
        keep_defaults => 1,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    my @lines = split /\n/, $output;
    my $found_default = 0;
    foreach my $line (@lines) {
        if ($line =~ /--very-long-option-name-that-exceeds-forty-characters=4\s+#\s+default/) {
            $found_default = 1;
            # Check that there are at least 2 spaces before #
            my ($spaces) = $line =~ /=\d+(\s+)#/;
            if (defined $spaces) {
                my $space_count = length($spaces);
                ok($space_count >= 2, "Minimum 2 spaces padding (found: $space_count)");
            }
        }
    }
    ok($found_default, 'Default comment appears for long option');
}

# Test 13: Outputs user-defined abbreviations section
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my %abbreviations_user = ('i' => ['indent-columns']);
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => \%abbreviations_user,
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 0,
    );
    
    like($output, qr/# Abbreviations/, 'Abbreviations section header appears');
    like($output, qr/i \{indent-columns\}/, 'User abbreviation appears in output');
}

# Test 14: Does not output abbreviations section when quiet
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my %abbreviations_user = ('i' => ['indent-columns']);
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => \%abbreviations_user,
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    unlike($output, qr/# Abbreviations/, 'Quiet mode omits abbreviations header');
    like($output, qr/i \{indent-columns\}/, 'Abbreviation still appears without header');
}

# Test 15: Writes to destination scalar ref when provided
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    ok($output ne "", 'Output written to scalar ref');
    like($output, qr/--indent-columns/, 'Output contains expected content');
}

# Test 16: Writes to stdout when destination not provided
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    
    # Capture stdout using a scalar reference
    my $stdout_output = "";
    {
        local *STDOUT;
        open STDOUT, '>', \$stdout_output or die "Cannot redirect STDOUT: $!";
        
        dump_options(
            opts => \%opts,
            sections => \%sections,
            getopt_flags => \%getopt_flags,
            abbreviations_user => {},
            cmdline => '',
            rc_origin => '',
            quiet => 1,
        );
    }
    
    ok($stdout_output ne "", 'Output written to stdout');
    like($stdout_output, qr/--indent-columns/, 'Stdout contains expected content');
}

# Test 17: Handles empty opts hash
{
    my %opts = ();
    my %sections = ();
    my %getopt_flags = ();
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    is($output, "", 'Empty opts produces empty output');
}

# Test 18: Handles options without sections (uses UNKNOWN)
{
    my %opts = ('unknown-option' => 'value');
    my %sections = ();  # No section mapping
    my %getopt_flags = ('unknown-option' => '=');
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    like($output, qr/--unknown-option="value"/, 'Option without section still appears (non-numeric value quoted)');
}

# Test 19: Handles multiple section notes
{
    my %opts = ('indent-columns' => '4');
    my %sections = ('indent-columns' => '1. Basic formatting');
    my %getopt_flags = ('indent-columns' => '=');
    my %section_notes = ('1. Basic formatting' => ['Note 1', 'Note 2']);
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        section_notes => \%section_notes,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 0,
    );
    
    my @note_lines = $output =~ /# NOTE: (.*)/g;
    is(scalar @note_lines, 2, 'Multiple section notes appear');
    is($note_lines[0], 'Note 1', 'First note appears');
    is($note_lines[1], 'Note 2', 'Second note appears');
}

# Test 20: Handles options with empty string values
{
    my %opts = ('output-encoding' => '');
    my %sections = ('output-encoding' => '1. Basic formatting');
    my %getopt_flags = ('output-encoding' => '=');
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    like($output, qr/--output-encoding=""/, 'Empty string value is quoted');
}

# Test 21: Handles options with special characters in values
{
    my %opts = ('output-encoding' => 'utf-8');
    my %sections = ('output-encoding' => '1. Basic formatting');
    my %getopt_flags = ('output-encoding' => '=');
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    like($output, qr/--output-encoding="utf-8"/, 'Value with hyphen is quoted');
}

# Test 22: Sorts options within sections alphabetically
{
    my %opts = (
        'maximum-line-length' => '80',
        'indent-columns' => '4',
        'brace-tightness' => '2',
    );
    my %sections = (
        'indent-columns' => '1. Basic formatting',
        'maximum-line-length' => '1. Basic formatting',
        'brace-tightness' => '1. Basic formatting',
    );
    my %getopt_flags = (
        'indent-columns' => '=',
        'maximum-line-length' => '=',
        'brace-tightness' => '=',
    );
    my $output = "";
    dump_options(
        opts => \%opts,
        sections => \%sections,
        getopt_flags => \%getopt_flags,
        abbreviations_user => {},
        cmdline => '',
        rc_origin => '',
        destination => \$output,
        quiet => 1,
    );
    
    my @lines = split /\n/, $output;
    my @options;
    foreach my $line (@lines) {
        if ($line =~ /^--(\S+)/) {
            my $opt = $1;
            $opt =~ s/=.*$//;
            push @options, $opt;
        }
    }
    
    is($options[0], 'brace-tightness', 'Options sorted alphabetically: brace-tightness first');
    is($options[1], 'indent-columns', 'Options sorted alphabetically: indent-columns second');
    is($options[2], 'maximum-line-length', 'Options sorted alphabetically: maximum-line-length third');
}

done_testing();

