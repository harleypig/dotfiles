#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'tests/perl/lib';
use TestParseParams;

# Option parsing: short/long/combined, VARNAME defaulting, defaults, required.

my ($out, $err, $rc);

# short and long forms set the same variable
($out, $err, $rc) = run_pp("a|app,string,AppName,,required", '--app', 'foo');
is($rc, 0, 'long form exits 0');
like($out, qr/^AppName='foo'$/m, 'long form sets AppName');

($out, $err, $rc) = run_pp("a|app,string,AppName,,required", '-a', 'bar');
is($rc, 0, 'short form exits 0');
like($out, qr/^AppName='bar'$/m, 'short form sets AppName');

# VARNAME defaults to the long option when not given
($out, $err, $rc) = run_pp("a|app,string", '--app', 'x');
like($out, qr/^app='x'$/m, 'VARNAME defaults to long option');

# VARNAME defaults to the short option when there is no long option
($out, $err, $rc) = run_pp("a,string", '-a', 'x');
like($out, qr/^a='x'$/m, 'VARNAME defaults to short option');

# default applies when the option is absent
($out, $err, $rc) = run_pp("n|num,integer,count,7");
is($rc, 0, 'absent option with default exits 0');
like($out, qr/^count='7'$/m, 'default applied when absent');

# default is overridden when the option is given
($out, $err, $rc) = run_pp("n|num,integer,count,7", '--num', '9');
like($out, qr/^count='9'$/m, 'given value overrides default');

# required-but-missing fails with a clear message
($out, $err, $rc) = run_pp("a|app,string,AppName,,required");
is($rc, 1, 'missing required exits 1');
like($err, qr/AppName is required/, 'required error names the variable');
unlike($out, qr/AppName=/, 'no assignment emitted on required failure');

# values with spaces and quotes survive the eval round-trip
($out, $err, $rc) = run_pp("a|app,string,AppName", '--app', "it's a test");
like($out, qr/^AppName='it'\\''s a test'$/m, 'single quote is escaped safely');

# unknown option is rejected
($out, $err, $rc) = run_pp("a|app,string", '--nope', 'x');
is($rc, 1, 'unknown option exits 1');

done_testing;
