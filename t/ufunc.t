#!/usr/bin/perl
#
# Test some Basic/Ufunc routines

use strict;
use Test::More tests => 6;

BEGIN {
    # if we've got this far in the tests then 
    # we can probably assume PDL::LiteF works!
    #
    use_ok( "PDL::LiteF" );
}
$| = 1;

sub tapprox ($$) {
    my ( $a, $b ) = @_;
    my $d = abs( $a - $b );
    print "diff = [$d]\n";
    return $d <= 0.0001;
}

# set up test arrays
#
my $a = pdl(0,0,6,3,5,0,7,14,94,5,5,8,7,7,1,6,7,13,10,2,101,19,7,7,5);  # sf.net bug #2019651
my $a_sort = $a->qsort;
my $b = pdl(55);
my $b_sort = $b->qsort;
my $c = cat($a,$a);
my $c_sort = $c->qsort;

# Test a range of values
is $a->pctover(-0.5), $a_sort->at(0), "pct below 0 for 25-elem pdl";
is $a->pctover( 0.0), $a_sort->at(0), "pct equal 0 for 25-elem pdl";
is $a->pctover( 0.9),             19, "pct equal 0.9 for 25-elem pdl (bug num 2019651)";
is $a->pctover( 1.0), $a_sort->at($a->dim(0)-1), "pct equal 1 for 25-elem pdl";
is $a->pctover( 2.0), $a_sort->at($a->dim(0)-1), "pct above 1 for 25-elem pdl";
