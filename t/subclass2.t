### Example of subclassing #####
###  This script tests for proper output value typing of the major
###   categories of PDL primitive operations.
###       For example:
###           If $pdlderived is a PDL::derived object (subclassed from PDL),
###              then $pdlderived->sumover should return a PDL::derived object.
###      
use PDL::LiteF;


# Test PDL Subclassing via hashes

sub ok {
        my $no = shift ;
        my $result = shift ;
        print "not " unless $result ;
        print "ok $no\n" ;
}

print "1..13\n";      


########### Subclass typing Test ###########

##  First define a PDL-derived object:
package PDL::Derived;

@PDL::Derived::ISA = qw/PDL/;

sub new {
   my $class = shift;
   my $x = bless {}, $class;
   my $value = shift;
   $$x{PDL} = $value;
   $$x{SomethingElse} = 42;
   return $x;
}


## Now check to see if the different categories of primitive operations
##   return the PDL::Derived type.
package main;

# Create a PDL::Derived instance

$z = PDL::Derived->new( ones(5,5) ) ;

ok(1,ref($z)eq"PDL::Derived");


#### Check the type after incrementing:
$z++;
ok(2,ref($z) eq "PDL::Derived");


#### Check the type after performing sumover:
$y = $z->sumover;
ok(3,ref($y) eq "PDL::Derived");


#### Check the type after adding two PDL::Derived objects:
$x = PDL::Derived->new( ones(5,5) ) ;
$w = $x + $z;
ok(4,ref($w) eq "PDL::Derived");

#### Check the type after calling null:
$a = PDL::Derived->null();
ok(5,ref($a) eq "PDL::Derived");



##### Check the type for a byops2 operation:
$w = ($x == $z);
ok(6,ref($w) eq "PDL::Derived");

##### Check the type for a byops3 operation:
$w = ($x | $z);
ok(7,ref($w) eq "PDL::Derived");

##### Check the type for a ufuncs1 operation:
$w = sqrt($z);
ok(8,ref($w) eq "PDL::Derived");

##### Check the type for a ufuncs1f operation:
$w = sin($z);
ok(9,ref($w) eq "PDL::Derived");

##### Check the type for a ufuncs2 operation:
$w = ! $z;
ok(10,ref($w) eq "PDL::Derived");

##### Check the type for a ufuncs2f operation:
$w = log $z;
ok(11,ref($w) eq "PDL::Derived");

##### Check the type for a bifuncs operation:
$w =  $z**2;
ok(12,ref($w) eq "PDL::Derived");

##### Check the type for a slicing operation:
$a = PDL::Derived->new(1+(xvals zeroes 4,5) + 10*(yvals zeroes 4,5));
$w = $a->slice('1:3:2,2:4:2');
ok(13,ref($w) eq "PDL::Derived");

