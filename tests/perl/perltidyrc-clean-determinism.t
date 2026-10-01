#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Spec;
use lib 'tests/perl/lib';
use TestPerltidyrcClean;

# perltidyrc-clean's output must not depend on Perl's per-process hash order
# (#484). Each case runs the script under several fixed PERL_HASH_SEED values
# and expects byte-identical output. The seeds are fixed, so a regression
# fails every time rather than one run in a few.

my $script = File::Spec->catfile( 'bin', 'perltidyrc-clean' );

# Seeds 1-8 reorder the condense notes for -act=0 four different ways on the
# unfixed script; seed 0 is excluded because it disables hash randomisation.
my @seeds = ( 1 .. 8 );

# Each case condenses several abbreviations at once, so their notes land in
# the same sections and their relative order is visible.
my @cases = (
  ['--no-rc'],
  [ '--no-rc', '-cti=1' ],
  [ '--no-rc', '-cti=2' ],
  [ '--no-rc', '-act=0' ],
  [ '--no-rc', '-vt=2', '-vtc=1' ],
);

sub run_with_seed {
  my ( $seed, @args ) = @_;
  local $ENV{PERL_HASH_SEED}    = $seed;
  local $ENV{PERL_PERTURB_KEYS} = 2;   # deterministic for a given seed

  open my $fh, '-|', $^X, $script, @args
    or die "cannot run $script: $!\n";
  my $output = do { local $/ = undef; <$fh> };
  close $fh;

  # The header carries a timestamp, which may tick between runs.
  $output =~ s/^\# [ ] perltidy [ ] configuration [ ] file [ ] created [ ] .*\n//mx;
  return ( $? >> 8, $output );
}

foreach my $case (@cases) {
  my $label = join ' ', @{$case};
  my ( $first_exit, $first ) = run_with_seed( $seeds[0], @{$case} );

  is( $first_exit, 0, "$label: exits 0" );
  like( $first, qr/^\# [ ] NOTE: .* [ ] can [ ] be [ ] condensed [ ] to [ ]/mx, "$label: produces condense notes" );

  my @differing;
  foreach my $seed ( @seeds[ 1 .. $#seeds ] ) {
    my ( undef, $output ) = run_with_seed( $seed, @{$case} );
    push @differing, $seed if $output ne $first;
  }

  is_deeply( \@differing, [], "$label: identical output across PERL_HASH_SEED values" )
    or diag "seeds whose output differs from seed $seeds[0]: @differing";
}

# The order condense_options applies abbreviations in, pinned directly with
# synthetic abbreviations: broadest first, then by name.
load_perltidyrc_clean();

# Single-option abbreviations, mapping short names to long ones.
my %singles = (
  a => ['alpha'],
  b => ['bravo'],
  c => ['charlie'],
  d => ['delta'],
);

sub condense_notes {
  my ($multi)  = @_;
  my %opts     = map { $_ => 1 } qw(alpha bravo charlie delta);
  my %sections = map { $_ => '1. Section' } keys %opts;
  my %notes;
  condense_options( \%opts, \%sections, \%notes, {}, { %singles, %{$multi} } );
  return $notes{'1. Section'} || [];
}

# Overlap: 'aa' sorts before 'wide' but covers less, so it must not win.
is_deeply(
  condense_notes( { 'aa' => [qw(a=1 b=1)], 'wide' => [qw(a=1 b=1 c=1)] } ),
  [ 'alpha removed; can be condensed to wide',
    'bravo removed; can be condensed to wide',
    'charlie removed; can be condensed to wide',
  ],
  'overlapping abbreviations: the broadest one condenses the shared options'
);

# Same expansion, same name length: the name that sorts first is preferred.
is_deeply(
  condense_notes( { 'xb' => [qw(a=1 b=1)], 'xa' => [qw(a=1 b=1)] } ),
  [ 'alpha removed; can be condensed to xa', 'bravo removed; can be condensed to xa', ],
  'equal-length names for one expansion: the first by name wins'
);

# Disjoint abbreviations of equal breadth: notes follow abbreviation name.
is_deeply(
  condense_notes( { 'zz' => [qw(a=1 b=1)], 'yy' => [qw(c=1 d=1)] } ),
  [ 'charlie removed; can be condensed to yy',
    'delta removed; can be condensed to yy',
    'alpha removed; can be condensed to zz',
    'bravo removed; can be condensed to zz',
  ],
  'equally broad abbreviations: notes are ordered by abbreviation name'
);

done_testing();
