use PDL;
use PDL::Lib::PCA;
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

print "1..1\n";

# Make data: 4 points

$data = (pdl [1,1],[0,0.1],[1,0.9],[0,0]) - 0.5;

print $data;

$eta = pdl 0.1;

$w = pdl 0.1,0.9;

for (1..100) {
	print $w,"\n";
	pca_oja($w,$eta,$data);
}

print "Final wt: $w\n";
ok(1,approx($w,pdl 0.74149,0.67095));
