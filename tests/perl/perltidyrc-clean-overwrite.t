#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use Cwd;
use File::Temp qw(tempfile);

# Test the --overwrite option

my $script = File::Spec->catfile('bin', 'perltidyrc-clean');

# Test 1: --overwrite without --rc should fail
{
    my $stdout = `$script --overwrite 2>&1`;
    my $exit_code = $? >> 8;
    isnt($exit_code, 0, '--overwrite without --rc exits with non-zero code');
    like($stdout, qr/--overwrite requires --rc/, 'Error message mentions --rc requirement');
}

# Test 2: --overwrite with --outfile should fail (mutually exclusive)
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    print $fh "# test config\n";
    close $fh;
    
    my $stdout = `$script --rc $tmpfile --overwrite --outfile /tmp/other 2>&1`;
    my $exit_code = $? >> 8;
    isnt($exit_code, 0, '--overwrite with --outfile exits with non-zero code');
    like($stdout, qr/mutually exclusive/, 'Error message mentions mutually exclusive');
}

# Test 3: --overwrite with --rc should succeed and overwrite the file
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    # Use non-default options that won't be filtered out
    print $fh "--indent-columns=2\n";
    print $fh "--maximum-line-length=132\n";
    close $fh;
    
    my $stdout = `$script --rc $tmpfile --overwrite 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--overwrite with --rc exits with code 0');
    # stdout should be empty (output goes to file)
    is($stdout, '', '--overwrite produces no stdout output');
    
    # Verify file was overwritten
    open my $read_fh, '<', $tmpfile or die "Cannot read $tmpfile: $!";
    my $content = do { local $/; <$read_fh> };
    close $read_fh;
    
    like($content, qr/perltidy configuration file created/, 'Overwritten file contains header');
    like($content, qr/--indent-columns/, 'Overwritten file contains cleaned options');
}

# Test 4: --overwrite should write cleaned output (removing defaults)
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    # Write a config with some non-default options
    print $fh "--indent-columns=2\n";  # Non-default
    print $fh "--maximum-line-length=132\n";  # Non-default
    close $fh;
    
    my $stdout = `$script --rc $tmpfile --overwrite 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--overwrite cleans defaults and exits with code 0');
    
    # Read the overwritten file
    open my $read_fh, '<', $tmpfile or die "Cannot read $tmpfile: $!";
    my $content = do { local $/; <$read_fh> };
    close $read_fh;
    
    # The file should be cleaned (defaults removed unless --keep-defaults)
    # We can't predict exactly what will be in there, but it should have the header
    like($content, qr/perltidy configuration file created/, 'Overwritten file has cleaned content');
}

# Test 5: --overwrite with --keep-defaults should preserve defaults
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    print $fh "--indent-columns=2\n";  # Non-default
    print $fh "--maximum-line-length=132\n";  # Non-default
    close $fh;
    
    my $stdout = `$script --rc $tmpfile --overwrite --keep-defaults 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--overwrite with --keep-defaults exits with code 0');
    
    # Read the overwritten file
    open my $read_fh, '<', $tmpfile or die "Cannot read $tmpfile: $!";
    my $content = do { local $/; <$read_fh> };
    close $read_fh;
    
    like($content, qr/perltidy configuration file created/, 'Overwritten file with --keep-defaults has content');
}

# Test 6: --overwrite with --quiet should omit header comments
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    print $fh "--indent-columns=2\n";  # Non-default
    print $fh "--maximum-line-length=132\n";  # Non-default
    close $fh;
    
    my $stdout = `$script --rc $tmpfile --overwrite --quiet 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--overwrite with --quiet exits with code 0');
    
    # Read the overwritten file
    open my $read_fh, '<', $tmpfile or die "Cannot read $tmpfile: $!";
    my $content = do { local $/; <$read_fh> };
    close $read_fh;
    
    unlike($content, qr/perltidy configuration file created/, 'Overwritten file with --quiet omits header');
}

# Test 7: --overwrite should work with relative path for --rc
{
    my $cwd = getcwd();
    my $tmpfile = File::Spec->catfile($cwd, 'test_overwrite.rc');
    
    # Create test file with non-default options
    open my $fh, '>', $tmpfile or die "Cannot create $tmpfile: $!";
    print $fh "--indent-columns=2\n";
    print $fh "--maximum-line-length=132\n";
    close $fh;
    
    my $rel_path = File::Spec->abs2rel($tmpfile);
    my $stdout = `$script --rc $rel_path --overwrite 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--overwrite with relative --rc path exits with code 0');
    
    # Verify file was overwritten
    open my $read_fh, '<', $tmpfile or die "Cannot read $tmpfile: $!";
    my $content = do { local $/; <$read_fh> };
    close $read_fh;
    
    like($content, qr/perltidy configuration file created/, 'Overwritten file with relative path has content');
    
    # Clean up
    unlink $tmpfile or warn "Could not remove test file: $!";
}

# Test 8: --overwrite should preserve file permissions (or at least not fail)
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    print $fh "--indent-columns=2\n";  # Non-default
    print $fh "--maximum-line-length=132\n";  # Non-default
    close $fh;
    
    # Set restrictive permissions
    chmod 0600, $tmpfile;
    my $original_mode = (stat $tmpfile)[2];
    
    my $stdout = `$script --rc $tmpfile --overwrite 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--overwrite with restricted permissions exits with code 0');
    
    # File should still exist and be readable
    ok(-f $tmpfile, 'Overwritten file still exists');
    ok(-r $tmpfile, 'Overwritten file is readable');
}

# Test 9: --overwrite should handle config file with only defaults
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    # Create file with only default options (will be filtered out)
    print $fh "--indent-columns=4\n";  # Default value
    close $fh;
    
    my $stdout = `$script --rc $tmpfile --overwrite 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--overwrite with only defaults exits with code 0');
    
    # When no options remain, script prints to STDERR and doesn't overwrite
    like($stdout, qr/No configuration parameters remain/, 'Message about no parameters when only defaults');
    
    # File should remain unchanged (not overwritten when no options)
    open my $read_fh, '<', $tmpfile or die "Cannot read $tmpfile: $!";
    my $content = do { local $/; <$read_fh> };
    close $read_fh;
    
    like($content, qr/--indent-columns=4/, 'File unchanged when no options remain');
}

# Test 10: --overwrite should work with --condense
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    print $fh "--indent-columns=2\n";  # Non-default
    print $fh "--maximum-line-length=132\n";  # Non-default
    close $fh;
    
    my $stdout = `$script --rc $tmpfile --overwrite --condense 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--overwrite with --condense exits with code 0');
    
    ok(-f $tmpfile, 'Overwritten file exists after --condense');
}

# Test 11: --overwrite should work with --no-condense
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    print $fh "--indent-columns=2\n";  # Non-default
    print $fh "--maximum-line-length=132\n";  # Non-default
    close $fh;
    
    my $stdout = `$script --rc $tmpfile --overwrite --no-condense 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--overwrite with --no-condense exits with code 0');
    
    ok(-f $tmpfile, 'Overwritten file exists after --no-condense');
}

# Test 12: --overwrite should fail if file is not writable
{
    my ($fh, $tmpfile) = tempfile(SUFFIX => '.rc', UNLINK => 1);
    # Use non-default options so file will be opened for writing
    print $fh "--indent-columns=2\n";
    print $fh "--maximum-line-length=132\n";
    close $fh;
    
    # Make file read-only
    chmod 0444, $tmpfile;
    
    my $stdout = `$script --rc $tmpfile --overwrite 2>&1`;
    my $exit_code = $? >> 8;
    isnt($exit_code, 0, '--overwrite with read-only file exits with non-zero code');
    like($stdout, qr/Cannot open.*for writing/, 'Error message mentions cannot open for writing');
    
    # Restore permissions for cleanup
    chmod 0644, $tmpfile;
}

done_testing();

