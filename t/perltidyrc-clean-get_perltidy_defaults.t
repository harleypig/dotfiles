#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use lib 't/lib';
use TestPerltidyrcClean;

# Load the script
load_perltidyrc_clean();

# Test 1: Returns hash references for defaults and abbreviations
{
    my ( $opts_default, $abbreviations_default ) = get_perltidy_defaults();

    ok( ref($opts_default) eq 'HASH', 'Returns opts_default hash ref' );
    ok( ref($abbreviations_default) eq 'HASH',
        'Returns abbreviations_default hash ref' );
    ok( keys(%$opts_default) > 0, 'Defaults hash is populated' );
    ok( keys(%$abbreviations_default) > 0,
        'Default abbreviations hash is populated' );
}

# Test 2: Returns consistent defaults across multiple calls
{
    my ( $opts1, $abbr1 ) = get_perltidy_defaults();
    my ( $opts2, $abbr2 ) = get_perltidy_defaults();

    # Should return the same defaults
    is_deeply( $opts1, $opts2,
        'get_perltidy_defaults returns consistent defaults' );
    is_deeply( $abbr1, $abbr2,
        'get_perltidy_defaults returns consistent abbreviations' );
}

# Test 3: Defaults contain expected common options
{
    my ( $opts_default, $abbreviations_default ) = get_perltidy_defaults();

    # Check for some common options that should exist
    ok( exists $opts_default->{'indent-columns'},
        'Defaults contain indent-columns option' );
    ok( exists $opts_default->{'maximum-line-length'},
        'Defaults contain maximum-line-length option' );

    # Check for some common abbreviations
    ok( exists $abbreviations_default->{'i'},
        'Defaults contain i abbreviation' );
    ok( exists $abbreviations_default->{'l'},
        'Defaults contain l abbreviation' );
}

# Test 4: Abbreviations structure is valid
{
    my ( $opts_default, $abbreviations_default ) = get_perltidy_defaults();

    # Check that abbreviations have valid structure (array refs)
    my $valid_count = 0;
    my $total_count = 0;
    foreach my $abbr ( keys %$abbreviations_default ) {
        $total_count++;
        my $val = $abbreviations_default->{$abbr};
        if ( ref($val) eq 'ARRAY' && @$val > 0 ) {
            $valid_count++;
        }
    }
    
    ok( $valid_count > 0, 'Abbreviations have valid structure' );
    ok( $valid_count == $total_count, 
        "All abbreviations have valid structure ($valid_count/$total_count)" );
    
    # Check a few common abbreviations map to something reasonable
    if ( exists $abbreviations_default->{'i'} ) {
        my @vals = @{ $abbreviations_default->{'i'} };
        ok( @vals > 0, 'Common abbreviation i maps to at least one option' );
    }
    if ( exists $abbreviations_default->{'l'} ) {
        my @vals = @{ $abbreviations_default->{'l'} };
        ok( @vals > 0, 'Common abbreviation l maps to at least one option' );
    }
}

# Test 5: Function does not die on normal execution
{
    my $died = 0;
    eval {
        my ( $opts_default, $abbreviations_default ) = get_perltidy_defaults();
    };
    if ($@) {
        $died = 1;
        diag("get_perltidy_defaults died: $@");
    }

    ok( !$died, 'get_perltidy_defaults does not die on normal execution' );
}

done_testing();

