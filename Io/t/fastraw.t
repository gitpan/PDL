

use PDL;
# PDL::Core::set_debugging(1);
kill INT,$$  if $ENV{UNDER_DEBUGGER}; # Useful for debugging.

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

use PDL;
use PDL::Io::FastRaw;

print "1..1\n";

$a = pdl [2,3],[4,5],[6,7];

print $a;

unlink "tmp0","tmp0.hdr";

writefraw($a,"tmp0");

$b = readfraw("tmp0");

print $b;

$b->dump;

ok(1,approx($a,$b));

# unlink "tmp0","tmp0.hdr";
