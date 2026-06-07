package TestParseParams;

use strict;
use warnings;

use Exporter 'import';
use IPC::Open3 ();
use Symbol qw(gensym);
use File::Spec ();

our @EXPORT = qw(run_pp);

# run_pp($def_string, @args) -> ($stdout, $stderr, $exit_code)
#
# Runs bin/parse_params as a subprocess (relative to the repo root, which is
# the CWD under `prove tests/perl/`), passing the definition string and args
# directly (no shell), and returns its stdout, stderr, and exit code.
sub run_pp {
  my ($def, @args) = @_;

  my $script = File::Spec->catfile('bin', 'parse_params');
  my $err = gensym;
  my $pid = IPC::Open3::open3(my $in, my $out, $err, $script, $def, @args);

  close $in;
  local $/;
  my $stdout = <$out> // '';
  my $stderr = <$err> // '';
  waitpid $pid, 0;

  return ($stdout, $stderr, $? >> 8);
}

1;
