# Script to test some of the primitive operations for returning the correct values.
#
#  
#  Testing utility functions:
sub ok {
        my $no = shift ;
        my $result = shift ;
        print "not " unless $result ;
        print "ok $no\n" ;
}

sub approx {
        my($a,$b) = @_;
        my $c = abs($a-$b);
        my $d = ref($c) ? max($c) : $c ;  # don't do a make if were are dealing 
					  # with a scalar
        $c < 0.01;
}


###### Testing Begins #########
print "1..17\n";  


use PDL::LiteF;


$im = new PDL [
  [ 1, 2,  3,  3 , 5],
  [ 2,  3,  4,  5,  6],
  [13, 13, 13, 13, 13],
  [ 1,  3,  1,  3,  1],
  [10, 10,  2,  2,  2,]
 ];


my @minMax = $im->minmax;
# print "MinMax = ".join(", ",@minMax)."\n";

my $testNo = 1;

ok($testNo++, $minMax[0] == 1 );
ok($testNo++, $minMax[1] == 13 );


ok($testNo++, ($im x $im)->sum == 3429 );


my @statsRes = $im->stats;

ok($testNo++, approx($statsRes[0],5.36) );
ok($testNo++, approx($statsRes[1],4.4621) );
ok($testNo++, approx($statsRes[2],3) );
ok($testNo++, approx($statsRes[3],1) );
ok($testNo++, approx($statsRes[4],13) );

# print "StatRes = ".join(", ",@statsRes)."\n";


my $ones = ones(5,5);

@statsRes = $im->stats($ones);

# print "StatRes with moments = ".join(", ",@statsRes)."\n";
ok($testNo++, approx($statsRes[0],5.36) );
ok($testNo++, approx($statsRes[1],4.4621) );
ok($testNo++, approx($statsRes[2],3) );
ok($testNo++, approx($statsRes[3],1) );
ok($testNo++, approx($statsRes[4],13) );


# which ND test
my $a= PDL->sequence(10,10,3,4);  

($x, $y, $z, $w)=whichND($a == 203);

ok($testNo++,$a->at($x->list,$y->list,$z->list,$w->list) == 203 );
 

# clip tests
ok($testNo++, approx($im->hclip(5)->sum,83) );

ok($testNo++, approx($im->lclip(5)->sum,176) );


ok($testNo++, approx($im->clip(5,7)->sum,140) );

