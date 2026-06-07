package TestParseParams;

use strict;
use warnings;

use Exporter 'import';
use IPC::Open3 ();
use Symbol qw(gensym);
use File::Spec ();

our @EXPORT = qw(run_pp run_pp_argv);

# run_pp_argv(@argv) -> ($stdout, $stderr, $exit_code)
#
# Runs bin/parse_params with exactly @argv (no shell), relative to the repo
# root (the CWD under `prove tests/perl/`). Use this when leading parse_params
# options (--usage, --prog, --auto, -h) must come before the definition.
sub run_pp_argv {
  my @argv = @_;

  my $script = File::Spec->catfile('bin', 'parse_params');
  my $err = gensym;
  my $pid = IPC::Open3::open3(my $in, my $out, $err, $script, @argv);

  close $in;
  local $/;
  my $stdout = <$out> // '';
  my $stderr = <$err> // '';
  waitpid $pid, 0;

  return ($stdout, $stderr, $? >> 8);
}

# run_pp($def_string, @args) -> ($stdout, $stderr, $exit_code)
#
# The common case: definition string first, then the args to parse.
sub run_pp {
  my ($def, @args) = @_;
  return run_pp_argv($def, @args);
}

1;
