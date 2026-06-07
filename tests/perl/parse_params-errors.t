#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'tests/perl/lib';
use TestParseParams;

# Definition errors (exit 2), usage generation, and auto --help.

my ($out, $err, $rc);

# no definition string at all
($out, $err, $rc) = run_pp('');
is($rc, 2, 'empty definition is a definition error');

# unknown type
($out, $err, $rc) = run_pp("x,bogus");
is($rc, 2, 'unknown type exits 2');
like($err, qr/unknown type/, 'unknown type message');

# missing type
($out, $err, $rc) = run_pp("x");
is($rc, 2, 'missing type exits 2');

# invalid variable name
($out, $err, $rc) = run_pp("a,string,1bad");
is($rc, 2, 'invalid varname exits 2');

# repeated option
($out, $err, $rc) = run_pp("a,string,one\na,string,two");
is($rc, 2, 'repeated short option exits 2');

# bad REQUIRED field
($out, $err, $rc) = run_pp("a,string,v,,sometimes");
is($rc, 2, 'invalid REQUIRED value exits 2');

# --usage prints generated help to stdout and exits 0
($out, $err, $rc) = run_pp('--usage', "a|app,string,AppName,,required\nv|verbose,boolean");
is($rc, 0, '--usage exits 0');
like($out, qr/Options:/,   'usage lists Options');
like($out, qr/--app/,      'usage shows the long option');
like($out, qr/required/,   'usage marks required options');

# auto --help: usage to stderr, `exit 0` to stdout so the caller stops cleanly
($out, $err, $rc) = run_pp("a|app,string,AppName,,required", '--help');
is($rc, 0, '--help exits 0');
like($err, qr/Options:/,   'help text goes to stderr');
is($out, "exit 0\n",       'help emits `exit 0` for the caller to eval');

# a caller-defined -h/--help is NOT intercepted
($out, $err, $rc) = run_pp("h|help,boolean,help", '--help');
like($out, qr/^help=1$/m, 'caller-defined --help is honored, not intercepted');

done_testing;
