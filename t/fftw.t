use PDL;
use PDL::FFT;

BEGIN {
        eval "use PDL::FFTW;";
        $loaded = ($@ ? 0 : 1);
}

print "1..8\n";

unless ($loaded) {
	#print STDERR "PDL::Slatec not installed. All tests are skipped.\n";
	for (1..8) {
		print "ok $_ # Skipped: PDL::FFTW not available\n";
	}
	exit;
}




sub ok {
        my $no = shift ;
        my $result = shift ;
        print "not " unless $result ;
        print "ok $no\n" ;
}

sub tapprox {
        my($a,$b) = @_;
        my $c = abs($a-$b);
        my $d = max($c);
        $d < 0.0001;
}


$datatype = eval('$PDL::FFTW::COMPILED_TYPE') if($loaded); # get the type (doubld or float) that PDL::FFTW was linked/compiled with.
							 # use eval to avoid warning message when PDL::GSL::FFTW not loaded
$testNo = 1;

$n = 30;
$m = 40;

$ir = zeroes($n,$m)->$datatype();
$ii = zeroes($n,$m)->$datatype();
$ir = random $ir;
$ii = random $ii;

$i = cat $ir,$ii;
$i = $i->mv(2,0);
$fi = ifftw $i;

$fir = $ir->copy;
$fii = $ii->copy;
fftnd $fir,$fii;
$ffi = cat $fir,$fii;
$ffi = $ffi->mv(2,0);

$t = ($ffi-$fi)*($ffi-$fi);

# print diff fftnd and ifftw: ",sqrt($t->sum),"\n";
ok($testNo++, tapprox(sqrt($t->sum),pdl(0))  );


$orig = fftw $fi;
$orig /= $n*$m;

$t = ($orig-$i)*($orig-$i);
# print "diff ifftw fftw and orig: ",sqrt($t->sum),"\n";
ok($testNo++, tapprox(sqrt($t->sum),pdl(0))  );

# Inplace FFT
$i2 = $i->copy;

infftw($i2);

$t = ($i2-$ffi)*($i2-$ffi);
# print "diff fftnd and infftw: ",sqrt($t->sum),"\n";
ok($testNo++, tapprox(sqrt($t->sum),pdl(0))  );

$i2 = nfftw $i2;
$i2 /= $n*$m;

$t = ($i-$i2)*($i-$i2);
# print "diff infftw nfftw and orig: ",sqrt($t->sum),"\n";
ok($testNo++, tapprox(sqrt($t->sum),pdl(0))  );


$ir = zeroes($n,$m)->$datatype();
$ii = zeroes($n,$m)->$datatype();
$ir = random $ir;

$fir = $ir->copy;
$fii = $ii->copy;
ifftnd $fir,$fii;
$ffi = cat $fir,$fii;
$ffi = $ffi->mv(2,0);
$ffi *= $n*$m;
$sffi = $ffi->mslice(X,[0,$n/2],X);

$fi = rfftw $ir;

$t = ($sffi-$fi)*($sffi-$fi);
# print "diff rfftw and infft: ",sqrt($t->sum),"\n";
ok($testNo++, tapprox(sqrt($t->sum),pdl(0))  );

$orig = irfftw $fi;
$orig /= $n*$m;

$t = ($orig-$ir)*($orig-$ir);
# print "diff ifftw fftw and orig: ",sqrt($t->sum),"\n";
ok($testNo++, tapprox(sqrt($t->sum),pdl(0))  );


$rin = zeroes(2*(int($n/2)+1),$m)->$datatype();
$tmp = $rin->mslice([0,$n-1],X);
$tmp .= $ir;
$srin = $rin->copy;

$rin = nrfftw $rin;

$t = ($sffi-$rin)*($sffi-$rin);
# print "diff nrfftw and infft: ",sqrt($t->sum),"\n";
ok($testNo++, tapprox(sqrt($t->sum),pdl(0))  );

$rin = inrfftw $rin;
$rin /= $n*$m;

$rin = $rin->mslice([0,$n-1],X);
$srin = $srin->mslice([0,$n-1],X);

$t = ($srin-$rin)*($srin-$rin);
# print "diff inrfftw nrfftw and orig: ",sqrt($t->sum),"\n";
ok($testNo++, tapprox(sqrt($t->sum),pdl(0))  );

