#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# POD syntax check for the repo's perl CLIs (Test::Pod). Catches malformed POD
# -- e.g. non-ASCII text with no `=encoding` declaration. Skips cleanly when
# Test::Pod is absent so a machine without it is not blocked; CI installs
# libtest-pod-perl so it runs there. Paths are relative to the repo root, so
# prove must run from the checkout root (as the rest of tests/perl/ does).

eval { require Test::Pod; Test::Pod->import; 1 }
  or plan skip_all => 'Test::Pod not installed';

my @files = ( 'bin/parse_params', 'bin/perltidyrc-clean', 'bin/xdg-audit' );

plan tests => scalar @files;

pod_file_ok( $_, "POD syntax OK: $_" ) for @files;
