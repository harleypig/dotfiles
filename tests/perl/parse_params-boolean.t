#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'tests/perl/lib';
use TestParseParams;

# Boolean semantics, negation, inverted default, repeatable, positional.

my ($out, $err, $rc);

# present -> 1, absent -> 0 (so ((VAR)) is true when the flag is given)
($out, $err, $rc) = run_pp("v|verbose,boolean", '--verbose');
like($out, qr/^verbose=1$/m, 'boolean present -> 1');
($out, $err, $rc) = run_pp("v|verbose,boolean");
like($out, qr/^verbose=0$/m, 'boolean absent -> 0');
($out, $err, $rc) = run_pp("v|verbose,boolean", '-v');
like($out, qr/^verbose=1$/m, 'short boolean present -> 1');

# negatable: --no-LONG sets 0
($out, $err, $rc) = run_pp("v|verbose,boolean", '--no-verbose');
like($out, qr/^verbose=0$/m, '--no-verbose -> 0');

# inverted (default-on) via DEFAULT=1
($out, $err, $rc) = run_pp("c|color,boolean,color,1");
like($out, qr/^color=1$/m, 'default-on boolean absent -> 1');
($out, $err, $rc) = run_pp("c|color,boolean,color,1", '--no-color');
like($out, qr/^color=0$/m, 'default-on boolean --no- -> 0');

# a non-0/1 boolean default is a definition error
($out, $err, $rc) = run_pp("c|color,boolean,color,yes");
is($rc, 2, 'boolean default must be 0 or 1 (definition error)');

# repeatable type@ collects into a shell array; spaces preserved
($out, $err, $rc)
  = run_pp("i|inc,string\@,includes", '-i', 'one', '-i', 'two three');
is($rc, 0, 'repeatable exits 0');
like($out, qr/^includes=\('one' 'two three'\)$/m,
  'repeatable emits a shell array preserving spaces');
($out, $err, $rc) = run_pp("i|inc,string\@,includes");
like($out, qr/^includes=\(\)$/m, 'repeatable with no values -> empty array');

# boolean cannot be repeatable
($out, $err, $rc) = run_pp("b,boolean\@,flag");
is($rc, 2, 'boolean@ is a definition error');

# positional assignment in order, with type checking
($out, $err, $rc) = run_pp("#,string,target\n#,integer,count", 'host', '5');
is($rc, 0, 'positionals exit 0');
like($out, qr/^target='host'$/m, 'first positional assigned');
like($out, qr/^count='5'$/m,    'second positional assigned');
($out, $err, $rc) = run_pp("#,integer,count", 'notnum');
is($rc, 1, 'positional type mismatch exits 1');

done_testing;
