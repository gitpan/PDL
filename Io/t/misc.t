
# Test routine for PDL::IO module

use PDL;
use PDL::Io::Misc;

print "1..5\n";

kill INT,$$  if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

$count=1;
sub ok {
        my $no = $count++ ;
        my $result = shift ;
        print "not " unless $result ;
        print "ok $no\n" ;
}

$file = '/tmp/iotest$$';

############# Test rcols with filename and pattern #############

open(OUT, ">$file") || die "Can not open $file for writing\n";
print OUT <<EOD;
1 2
2 33 FOO
3 7
4 9  FOO
5 66 
EOD
close(OUT);

($a,$b) = rcols $file,0,1; $a = long($a); $b=long($b);

ok( (sum($a)==15 && max($b)==66 && $b->getdim(0)==5) );

($a,$b) = rcols $file, "/FOO/",0,1; $a = long($a); $b=long($b);

ok( (sum($a)==6 && max($b)==33 && $b->getdim(0)==2) );

############### Test rgrep with FILEHANDLE #####################

open(OUT, ">$file") || die "Can not open $file for writing\n";
print OUT <<EOD;
foo"1" -2-
foo"2"  Test -33-
foo"3" jvjtvbjktrbv -7-
foo"4" -9-
fjrhfiurhe foo"5" jjjj -66-
EOD
close(OUT);

open(OUT, $file) || die "Can not open $file for reading\n";
($a,$b) = rgrep *OUT, '/foo"(.*)".*-(.*)-/';
$a = long($a); $b=long($b);
close(OUT);

ok( (sum($a)==15 && max($b)==66 && $b->getdim(0)==5) );

################ Test rfits/wfits ########################

$t = long xvals(zeroes(11,20))-5;

wfits $t->slice('-1:0,:'), $file;

$t2 = rfits $file; 

ok( (sum($t->slice('0:4,:')) == -sum($t2->slice('0:4,:')) ));

unlink $file;

########### Explicit test of byte swapping #################

$a = short(3); $b = long(3); # $c=long([3,3]);
bswap2($a); bswap4($b);
ok(sum($a)==768 && sum($b)==50331648);

