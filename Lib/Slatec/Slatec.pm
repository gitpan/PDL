
# 
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Slatec;

@EXPORT = qw( eigsys inv svdc poco geco gefa podi gedi rs );

use PDL::Core;
use DynaLoader;
@ISA    = qw( PDL::Exporter DynaLoader ); 

bootstrap PDL::Slatec;


use PDL;
use PDL::Basic;

# Note: handles only real symmetric positive-definite.

sub eigsys {
	my($h) = @_;
	$h = float($h);
	rs($h, 
		(my $eigval=PDL->null),
		(long pdl 1),(my $eigmat=PDL->null),
		(my $fvone = PDL->null),(my $fvtwo = PDL->null),
		(my $errflag=PDL->null)
	);
#	print $covar,$eigval,$eigmat,$fvone,$fvtwo,$errflag;
	if(sum($errflag) > 0) {
		croak("Non-positive-definite matrix given to eigsys: $h\n");
	}
	return ($eigval,$eigmat);
}

sub inv {
	my($m) = @_;
	$m = $m->copy(); # Make sure we don't overwrite :(
	gefa($m,(my $ipvt=null),(my $info=null));
	if(sum($info) > 0) {
		croak("Uninvertible matrix given to inv: $m\n");
	}
	gedi($m,$ipvt,(pdl 0,0),(null),(long pdl 1));
	$m;
}

;

;# Exit with OK status

1;

