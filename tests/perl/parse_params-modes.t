#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'tests/perl/lib';
use TestParseParams;

# Leading parse_params options: -h/--help (own help), --prog, --auto.

my ($out, $err, $rc);

# parse_params's own help (leading -h / --help) -> stdout, exit 0
($out, $err, $rc) = run_pp_argv('-h');
is($rc, 0, '-h exits 0');
like($out, qr/parse_params - validate/, '-h prints parse_params own help');
# Assert on POD *body* content, not rendered section headers, which Pod::Text
# formats differently across versions.
like($out, qr/OPTION, TYPE, VARNAME/, '-h documents the definition format');
like($out, qr/--auto/, '-h lists parse_params own options (from POD)');

($out, $err, $rc) = run_pp_argv('--help');
is($rc, 0, '--help exits 0');
like($out, qr/parse_params - validate/, '--help prints own help');

# --prog NAME shows the program name in the generated usage header
($out, $err, $rc) = run_pp_argv('--usage', '--prog', 'myscript', "a|app,string");
is($rc, 0, '--usage --prog exits 0');
like($out, qr/^Usage: myscript \[options\]/m, '--prog sets the usage header');

# a leading --prog needs a value
($out, $err, $rc) = run_pp_argv('--prog');
is($rc, 2, 'leading --prog with no value is a definition error');

# --auto: success still emits assignments
($out, $err, $rc)
  = run_pp_argv('--auto', "a|app,string,AppName,,required", '--app', 'ok');
is($rc, 0, '--auto success exits 0');
like($out, qr/^AppName='ok'$/m, '--auto success emits assignments');

# --auto: bad input -> errors + usage to stderr, `exit 2` on stdout, rc 0
# (rc 0 because the caller is expected to `eval` the emitted `exit 2`)
($out, $err, $rc)
  = run_pp_argv('--auto', '--prog', 'myscript', "a|app,string,AppName,,required");
is($rc, 0, '--auto failure exits 0 (the emitted code carries the status)');
is($out, "exit 2\n", '--auto failure emits `exit 2` for the caller to eval');
like($err, qr/AppName is required/, '--auto failure reports the error on stderr');
like($err, qr/Usage: myscript/,     '--auto failure prints usage on stderr');

# --auto: a broken definition also emits `exit 2` so the caller stops
($out, $err, $rc) = run_pp_argv('--auto', "x,bogus");
is($out, "exit 2\n", '--auto definition error emits `exit 2`');
like($err, qr/definition error/, '--auto definition error reported on stderr');

# leading -h is parse_params help; -h after the definition is the caller's
# generated usage (auto-help) -- the two do not collide
($out, $err, $rc) = run_pp("a|app,string,AppName", '--help');
is($out, "exit 0\n", 'caller --help (after def) emits `exit 0`');
like($err, qr/Options:/, 'caller --help prints generated usage on stderr');

done_testing;
