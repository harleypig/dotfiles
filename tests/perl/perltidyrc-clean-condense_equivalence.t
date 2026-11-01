#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Temp qw(tempfile);
use lib 'tests/perl/lib';
use TestPerltidyrcClean;
use Perl::Tidy ();

# Condensing must not change what an rc does: a cleaned rc formats code the
# same as the rc it was cleaned from (#664). Each case writes an rc, cleans it
# with the script, formats the same sample under both, and compares. Red if
# condensing drops the options it condenses instead of writing the
# abbreviation, which leaves the cleaned rc formatting with defaults.

my $script = File::Spec->catfile( 'bin', 'perltidyrc-clean' );

# The closing tokens, the container spacing, and the indent width all differ
# from Perl::Tidy's defaults under the rcs below.
my $sample = <<'SAMPLE';
my @list = [
    $first_argument, $second_argument,
    $third_argument, $fourth_argument_here, $fifth_argument_goes_here_too, $sixth
];
my $h = {
    first => $first_argument, second => $second_argument,
    third => $third_argument, fourth => $fourth_argument_here, fifth => $sixth
};
if ( $x ) { foo( $a, $b ); my $y = $h{ key } + $a[ 0 ]; }
SAMPLE

sub write_rc {
  my (@lines) = @_;
  my ( $fh, $file ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  print {$fh} map { "$_\n" } @lines;
  close $fh or die "cannot close $file: $!\n";
  return $file;
}

sub slurp {
  my ($file) = @_;
  open my $fh, '<', $file or die "cannot read $file: $!\n";
  my $text = do { local $/ = undef; <$fh> };
  close $fh or die "cannot close $file: $!\n";
  return $text;
}

sub tidy_with {
  my ($rc) = @_;
  my ( $out, $err ) = ( q{}, q{} );
  my $failed = Perl::Tidy::perltidy(
    source      => \$sample,
    destination => \$out,
    perltidyrc  => $rc,
    stderr      => \$err,
    argv        => [],
  );
  die "perltidy failed with $rc: $err\n" if $failed;
  return $out;
}

# Returns the cleaned rc's text. The outfile already exists, empty, so a run
# that writes nothing leaves an empty rc rather than a missing one.
sub clean_rc {
  my ( $rc,   @flags )   = @_;
  my ( undef, $cleaned ) = tempfile( SUFFIX => '.rc', UNLINK => 1 );
  system( $^X, $script, '--rc', $rc, '-o', $cleaned, @flags ) == 0
    or die "$script failed on $rc\n";
  return ( $cleaned, slurp($cleaned) );
}

my $builtin_rc = write_rc( qw(
    --indent-columns=2
    --closing-paren-indentation=2
    --closing-brace-indentation=2
    --closing-square-bracket-indentation=2
    --paren-tightness=2
    --square-bracket-tightness=2
    --brace-tightness=2
    --block-brace-tightness=2
) );

# The rc must change the formatting, or the comparison proves nothing.
isnt( tidy_with($builtin_rc), tidy_with( \q{} ), 'the sample is sensitive to the test rc' );

foreach my $flags ( [], ['--quiet'] ) {
  my $label = join q{ }, 'built-in abbreviations', @{$flags};
  my ( $cleaned, $text ) = clean_rc( $builtin_rc, @{$flags} );

  like( $text, qr/^--closing-token-indentation=2$/m, "$label: writes closing-token-indentation" );
  like( $text, qr/^--all-containers-tightness=2$/m,  "$label: writes all-containers-tightness" );
  unlike( $text, qr/^--closing-paren-indentation/m, "$label: drops the options it condensed" );
  is( tidy_with($cleaned), tidy_with($builtin_rc), "$label: cleaned rc formats like the original" );
}

# A user-defined abbreviation is written before the definition at the end of
# the file; Perl::Tidy reads the whole file before expanding, so that holds.
{
  my $user_rc = write_rc(
    qw(--closing-paren-indentation=2 --closing-brace-indentation=2), 'pair {', '-cpi=2', '-cbi=2',
    '}'
  );
  my ( $cleaned, $text ) = clean_rc($user_rc);

  like( $text, qr/^--pair$/m, 'user abbreviation: writes the abbreviation' );
  is( tidy_with($cleaned), tidy_with($user_rc), 'user abbreviation: cleaned rc formats like the original' );
}

done_testing();
