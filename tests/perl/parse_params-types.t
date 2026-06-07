#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec ();
use lib 'tests/perl/lib';
use TestParseParams;

# Type validation: each type accepts a valid value and rejects an invalid one.

my ($out, $err, $rc);

# integer is signed
($out, $err, $rc) = run_pp("n,integer,num", '-n', '42');
is($rc, 0, 'integer accepts 42');
($out, $err, $rc) = run_pp("n,integer,num", '-n', '-5');
is($rc, 0, 'integer accepts -5 (signed)');
like($out, qr/^num='-5'$/m, 'signed integer value preserved');
($out, $err, $rc) = run_pp("n,integer,num", '-n', '3.5');
is($rc, 1, 'integer rejects 3.5');
($out, $err, $rc) = run_pp("n,integer,num", '-n', 'abc');
is($rc, 1, 'integer rejects abc');

# char is exactly one character
($out, $err, $rc) = run_pp("c,char,ch", '-c', 'x');
is($rc, 0, 'char accepts single char');
($out, $err, $rc) = run_pp("c,char,ch", '-c', 'xy');
is($rc, 1, 'char rejects two chars');

# varname is a valid shell identifier
($out, $err, $rc) = run_pp("v,varname,name", '-v', 'my_var1');
is($rc, 0, 'varname accepts my_var1');
($out, $err, $rc) = run_pp("v,varname,name", '-v', '1bad');
is($rc, 1, 'varname rejects 1bad');

# string accepts any non-empty value
($out, $err, $rc) = run_pp("s,string,str", '-s', 'anything goes!');
is($rc, 0, 'string accepts arbitrary text');

# filename: existing readable file ok; non-existent dir fails; result absolute
my $dir = tempdir(CLEANUP => 1);
my $existing = File::Spec->catfile($dir, 'real.txt');
open my $fh, '>', $existing or die $!;
close $fh;

($out, $err, $rc) = run_pp("f,filename,file", '-f', $existing);
is($rc, 0, 'filename accepts an existing readable file');
like($out, qr{^file='/}m, 'filename emitted as an absolute path');

my $creatable = File::Spec->catfile($dir, 'new.txt');
($out, $err, $rc) = run_pp("f,filename,file", '-f', $creatable);
is($rc, 0, 'filename accepts a creatable path (dir exists)');

($out, $err, $rc)
  = run_pp("f,filename,file", '-f', '/no/such/dir/at/all/x.txt');
is($rc, 1, 'filename rejects a path whose dir does not exist');

# date: accepted when `date -d` can parse it
($out, $err, $rc) = run_pp("d,date,when", '-d', '2026-01-15');
is($rc, 0, 'date accepts an ISO date');
($out, $err, $rc) = run_pp("d,date,when", '-d', 'not-a-date');
is($rc, 1, 'date rejects garbage');

done_testing;
