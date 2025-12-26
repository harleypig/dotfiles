#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use Cwd;
use File::Temp qw(tempdir tempfile);

# Test the --showconfig option

my $script = File::Spec->catfile('bin', 'perltidyrc-clean');

# Test 1: --showconfig with no config file found (should print "none")
{
    my $stdout = `$script --showconfig 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--showconfig exits with code 0 when no config found');
    is($stdout, "none\n", '--showconfig prints "none" when no config file found');
}

# Test 2: --showconfig with --no-rc (should print "none")
{
    my $stdout = `$script --showconfig --no-rc 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--showconfig --no-rc exits with code 0');
    is($stdout, "none\n", '--showconfig --no-rc prints "none"');
}

# Test 3: --showconfig with --rc FILE (should print absolute path)
{
    my $test_file = File::Spec->catfile('config', 'perl', 'perltidyrc');
    if (-f $test_file) {
        my $stdout = `$script --showconfig --rc $test_file 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, '--showconfig --rc exits with code 0');
        my $abs_path = File::Spec->rel2abs($test_file);
        is($stdout, "$abs_path\n", '--showconfig --rc prints absolute path');
    } else {
        skip("Test config file not found", 2);
    }
}

# Test 4: --showconfig with --rc relative path (should convert to absolute)
{
    my $test_file = File::Spec->catfile('config', 'perl', 'perltidyrc');
    if (-f $test_file) {
        my $rel_path = File::Spec->catfile('.', 'config', 'perl', 'perltidyrc');
        my $stdout = `$script --showconfig --rc $rel_path 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, '--showconfig --rc with relative path exits with code 0');
        my $abs_path = File::Spec->rel2abs($test_file);
        is($stdout, "$abs_path\n", '--showconfig --rc with relative path prints absolute path');
    } else {
        skip("Test config file not found", 2);
    }
}

# Test 5: --showconfig with --rc non-existent file (should error)
{
    my $stdout = `$script --showconfig --rc /nonexistent/file 2>&1`;
    my $exit_code = $? >> 8;
    isnt($exit_code, 0, '--showconfig --rc with non-existent file exits with non-zero code');
    like($stdout, qr/not found or not readable/, 'Error message mentions file not found');
}

# Test 6: --showconfig with PERLTIDY env var pointing to a file
{
    my $test_file = File::Spec->catfile('config', 'perl', 'perltidyrc');
    if (-f $test_file) {
        my $abs_path = File::Spec->rel2abs($test_file);
        local $ENV{PERLTIDY} = $test_file;
        my $stdout = `$script --showconfig 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, '--showconfig with PERLTIDY=file exits with code 0');
        is($stdout, "$abs_path\n", '--showconfig with PERLTIDY=file prints absolute path');
    } else {
        skip("Test config file not found", 2);
    }
}

# Test 7: --showconfig with PERLTIDY env var pointing to a directory
{
    my $tmpdir = tempdir(CLEANUP => 1);
    my $rc_file = File::Spec->catfile($tmpdir, '.perltidyrc');
    open my $fh, '>', $rc_file or die "Cannot create test file: $!";
    print $fh "# test config\n";
    close $fh;
    
    local $ENV{PERLTIDY} = $tmpdir;
    my $stdout = `$script --showconfig 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--showconfig with PERLTIDY=directory exits with code 0');
    my $abs_path = File::Spec->rel2abs($rc_file);
    is($stdout, "$abs_path\n", '--showconfig with PERLTIDY=directory prints absolute path');
}

# Test 8: --showconfig with config file in current directory
{
    my $cwd = getcwd();
    my $rc_file = File::Spec->catfile($cwd, '.perltidyrc');
    
    # Create a temporary config file
    open my $fh, '>', $rc_file or die "Cannot create test file: $!";
    print $fh "# test config\n";
    close $fh;
    
    my $stdout = `$script --showconfig 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--showconfig with config in current directory exits with code 0');
    is($stdout, "$rc_file\n", '--showconfig finds config in current directory');
    
    # Clean up
    unlink $rc_file or warn "Could not remove test file: $!";
}

# Test 9: --showconfig with --help (should show help, not config)
{
    my $stdout = `$script --showconfig --help 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--showconfig --help exits with code 0');
    like($stdout, qr/perltidyrc-clean/, '--showconfig --help shows usage message');
    unlike($stdout, qr/^none$|^\/.*perltidyrc$/m, '--showconfig --help does not show config location');
}

# Test 10: --showconfig ignores other options
{
    my $test_file = File::Spec->catfile('config', 'perl', 'perltidyrc');
    if (-f $test_file) {
        my $stdout = `$script --showconfig --keep-defaults --condense --quiet --rc $test_file 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, '--showconfig with other options exits with code 0');
        my $abs_path = File::Spec->rel2abs($test_file);
        is($stdout, "$abs_path\n", '--showconfig ignores other options and shows config');
    } else {
        skip("Test config file not found", 2);
    }
}

# Test 11: --showconfig with --rc in perltidy_args (pass-through)
{
    my $test_file = File::Spec->catfile('config', 'perl', 'perltidyrc');
    if (-f $test_file) {
        # Note: --rc in perltidy_args would be filtered out by our @ARGV filtering
        # But let's test that --no-rc in perltidy_args works
        my $stdout = `$script --showconfig --no-rc 2>&1`;
        my $exit_code = $? >> 8;
        is($exit_code, 0, '--showconfig --no-rc exits with code 0');
        is($stdout, "none\n", '--showconfig --no-rc prints "none"');
    } else {
        skip("Test config file not found", 2);
    }
}

# Test 12: --showconfig with PERLTIDY pointing to non-existent directory
{
    local $ENV{PERLTIDY} = '/nonexistent/directory';
    my $stdout = `$script --showconfig 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--showconfig with PERLTIDY=non-existent directory exits with code 0');
    # Should fall back to searching current directory and home
    # If no config found, should print "none"
    like($stdout, qr/^(none|\/.*\.perltidyrc)$/, '--showconfig falls back when PERLTIDY directory not found');
}

# Test 13: --showconfig with PERLTIDY pointing to directory without .perltidyrc
{
    my $tmpdir = tempdir(CLEANUP => 1);
    local $ENV{PERLTIDY} = $tmpdir;
    my $stdout = `$script --showconfig 2>&1`;
    my $exit_code = $? >> 8;
    is($exit_code, 0, '--showconfig with PERLTIDY=directory without .perltidyrc exits with code 0');
    # Should fall back to searching current directory and home
    like($stdout, qr/^(none|\/.*\.perltidyrc)$/, '--showconfig falls back when PERLTIDY directory has no config');
}

done_testing();

