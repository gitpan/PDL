# Test ->slice(). This is not yet good enough: we need
# nasty test cases, 

use PDL;
# kill INT,$$  if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

sub ok {
	my $no = shift ;
	my $result = shift ;
	print "not " unless $result ;
	print "ok $no\n" ;
}

sub approx {
	my($a,$b) = @_;
	$c = abs($a-$b);
	$d = max($c);
	$d < 0.01;
}

print "1..20\n";

if(1) {


{

$a = (1+(xvals zeroes 4,5) + 10*(yvals zeroes 4,5));

print "FOO\n";

print $a;

print "BAR\n";

ok(1,$a->at(2,2) == 23);

$b = $a->slice('1:3:2,2:4:2');

# print $a; print $b;

ok(2,$b->at(0,0) == 22);
ok(3,$b->at(1,0) == 24);
ok(4,$b->at(0,1) == 42);
ok(5,$b->at(1,1) == 44);


$b .= 0.5 * double ones(2,2);

 print $a;

ok(6,$a->at(2,2) == 23);   # Check that nothing happened to other elems
ok(7,$a->at(1,2) == 0.5);

$a = pdl (1,2);
$b = pdl [[1,2],[1,2],[1,2]];
$c = $a->slice(',*3');

print $a,$b,$c;

# $c = $a->dummy(1,3);
sumover($c->clump(-1),($sum=null));
# check dimensions, sum of elements and correct order of els (using approx)
ok(8,approx($b,$c));
ok(9,$sum->at == 9);
ok(10,(join ',',$c->dims) eq "2,3");

$b = pdl [[1,1,1],[2,2,2]];
$c = $a->slice('*3,');
sumover($c->clump(-1),($sum=null));
# check dimensions, sum of elements and correct order of els (using approx)
ok(11,approx($b,$c));
ok(12,$sum->at == 9);
ok(13,(join ',',$c->dims) eq "3,2");


# we are using more dims than are available
# this should raise an error or maybe it should do something else
# but probably not what it does now
eval {$c = $b->clump(3); $c->make_physical();};
print "ERROR WAS: '$@'\n";
ok(14,$@ =~ /error/i);

}

# test stringify
$a = zeroes(3,3);
$line = $a->slice(':,(0)');

$a++;
# $line += 0; # that's how to force an update before interpolation
$linepr = "$line";


ok(15,$linepr eq '[1 1 1]'); 

# Test whether error is properly returned:

$b = zeroes(5,3,3);
$c = $b->slice(":,:,1");

ok(16,(join ',',$c->dims) eq "5,3,1");
eval {$d = $c->slice(":,:,2"); print $d;};

print "ERROR WAS: '$@'\n";
ok(17,$@ =~ /Slice cannot start or end/i);



$a = zeroes 3,3;
print $a;


$b = $a->slice("1,1:2");
# print $b;
kill INT,$$  if $ENV{UNDER_DEBUGGER}; # Useful for debugging.
$b .= 1;

print $b;
print $a;

if(1) {

$a = xvals zeroes 20,20;
print $a;
kill INT,$$  if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

$b = $a->slice("1:18:2,:");
$c = $b->slice(":,1:18:2");
$d = $c->slice("3:5,:");
$e = $d->slice(":,(0)");
$f = $d->slice(":,(1)");

kill INT,$$  if $ENV{UNDER_DEBUGGER}; # Useful for debugging.
print "TOPRINT\n";

# print $b;
print $e,$f;
print $d,$c,$b,$a;

ok(18,"$e" eq "[7 9 11]");
ok(19,"$f" eq "[7 9 11]");

}
}

# Make sure that vaffining is properly working:

$a = zeroes 5,6,2;

$b = (xvals $a) + 0.1 * (yvals $a) + 0.01 * (zvals $a);

$b = $b->copy;

print $b;

$c = $b->slice("2:3");

$d = $c->copy;

$c->dump;
$d->dump;

$e = $c-$d;

print $e;

print $c;
print $d;

$c->dump; $d->dump;

ok(20,(max(abs($e))) == 0);

print "OUTOUTOUT!\n";

