# Test conversions. This is not yet good enough: we need
# nasty test cases, 

use PDL::LiteF;

sub ok {
	my $no = shift ;
	my $result = shift ;
	print "not " unless $result ;
	print "ok $no\n" ;
}

sub approx {
	my($a,$b) = @_;
	my $c = abs($a-$b);
	my $d = max($c);
	$d < 0.01;
}

print "1..6\n";

$a = pdl 42.4;

ok(1,$a->get_datatype == 5);

$b = byte $a;

ok(2,$b->get_datatype == 0);
ok(3,$b->at() == 42);

$c = $b * 3;
ok(4,$c->get_datatype == 3);

$d = $b * 600.0;
ok(5,$d->get_datatype == 5);

$e = $d * 5.5;
ok(6,$e->get_datatype == 5);


