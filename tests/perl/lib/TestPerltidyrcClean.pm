package TestPerltidyrcClean;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT = qw(load_perltidyrc_clean);

# Load the perltidyrc-clean script and make its functions available for testing.
# Overrides exit so the script doesn't exit the test when it calls exit.
# This function should be called once at the beginning of each test file that
# needs to test functions from bin/perltidyrc-clean.
sub load_perltidyrc_clean {
    # Override exit before loading script
    {
        no warnings 'redefine';
        *CORE::GLOBAL::exit = sub { return; };
    }
    
    # Ensure we're in main package when loading (do executes in current package)
    package main;
    local @ARGV = ('--help');
    # Suppress STDERR to avoid "No configuration parameters remain" message during tests
    # Restore STDERR after loading so errors are still visible
    {
        local *STDERR;
        open STDERR, '>', '/dev/null' or die "Cannot redirect STDERR: $!";
        do './bin/perltidyrc-clean';
        close STDERR;
    }
    if ($@) {
        die "Failed to load script: $@";
    }
    # Verify that at least one expected function is defined
    # (do can return undef even on success, so we check function existence instead)
    unless (defined &is_true || defined &looks_like_integer) {
        die "Script loaded but functions not found - script may have exited early";
    }
    
    return 1;
}

1;

