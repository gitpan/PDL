=head1 NAME

PDL::Opt::Simplex -- Simplex optimization routines

=head1 SYNOPSIS

	use PDL::Opt::Simplex;

	($optimum,$ssize) = simplex($init,$initsize,$minsize,
			$maxiter,
			sub {evaluate_func_at($_[0])},
			sub {display_simplex($_[0])}
			);

=head1 DESCRIPTION

This package implements the commonly used simplex optimization
algorithm. The basic idea of the algorithm is that in a 
N-dimensional search space you choose a simplex of N+1 points
which is then moved according to certain rules. The main
benefit of the algorithm is that you do not need to calculate
the derivatives of your function. 

The initial simplex is generated with its centroid at $init,
which is assumed to be one-dimensional.

The sub is assumed to understand more than 1 dimensions and threading.
Its signature is 'inp(ndims); [ret]out()'.

$ssize gives a very very approximate estimate of how close we might
be - it might be miles wrong. It is the euclidean distance between
the best and the worst vertices. If it is not very small, the algorithm
has not converged.

=head1 CAVEATS

Do not use the simplex method if your function has local minima.
It will not work. Use genetic algorithms or simulated annealing
or conjugate gradient or momentum gradient descent.

They will not work either but they are not guaranteed not to work ;)

=head1 SEE ALSO

Ron Shaffer's chemometrics web page and references therein:
C<http://chem1.nrl.navy.mil/~shaffer/chemoweb.html>.

Numerical Recipes (bla bla bla).

The demonstration (Examples/Simplex/tsimp.pl).

=head1 BUGS

Bad documentation. 

=head1 AUTHOR

Copyright(C) 1997 Tuomas J. Lukka. 

=cut

package PDL::Opt::Simplex;
use PDL;
use PDL::Primitive;
use strict;
use Exporter;
# use AutoLoader;

@PDL::Opt::Simplex::ISA = qw/Exporter/;

@PDL::Opt::Simplex::EXPORT = qw/simplex/;

sub simplex {
	my($init,$initsize,$minsize,$maxiter,$sub,$logsub) = @_;
	my ($i,$j); my $nd = $init->getdim(0);
	my $simp = PDL->zeroes($nd,$nd+1);
	$simp .= $init;
# Constructing a tetrahedron:
# At step n (starting from zero)
# take vertices 0..n and move them 1/(n+1) to negative dir on axis n.
# Take vertex n+1 and move it n/(n+1) to positive dir on axis n 
	for($i=0; $i<$nd; $i++) {
		my $pj = $i/($i+1);
		(my $stoopid = $simp->slice("$i,0:$i"))
				  -= $initsize * $pj;
		(my $stoopid1 = $simp->slice("$i,".($i+1)))
				  += $initsize * (1-$pj);
	}
	my $maxind = PDL->null;
	my $minind = PDL->zeroes(2);;
	my $ssum = PDL->null;
	my $worst;
	my $new;
	my $realnew;
	my $vals = &{$sub}($simp);
	&{$logsub}($simp,$vals)
		if $logsub;
	while($maxiter--) {
		maximum_ind($vals,$maxind);
		minimum_n_ind($vals,$minind);
		my $worstval = ($vals->at("$maxind"));
		my @bestvals = map {$vals->at($minind->at($_))} 0..1;
		
		sumover($simp->xchg(0,1),$ssum);
		$ssum -= ($worst = $simp->slice(":,($maxind)"));
		$ssum /= $nd;
		$new = 2*$ssum - $worst;
		my $valv = &{$sub}($new);
		my $val = $valv->at();
		if(($val) < $bestvals[0]) {
			my $newnew = $new + $ssum-$worst;
			my $val2 = &{$sub}($newnew);
			if($val2->at() < $val) {
#				print "CASE1\n";
				$realnew = $newnew;
			} else {
#				print "CASE2, $newnew, $val, $val2\n";
				$realnew = $new;
			}
		} elsif($val < $bestvals[1]) {
#			print "CASE3\n";
			$realnew = $new;
		} elsif($val < $worstval) {
#			print "CASE4\n";
			$realnew = 1.5*$ssum-0.5*$worst;
		} else {
#			print "CASE5\n";
			$realnew = 0.5*$ssum+0.5*$worst;
		}
		$worst .= $realnew;
		(my $stoopid2= $vals->slice("($maxind)")) .= &{$sub}($worst);
		&{$logsub}($simp,$vals)
			if $logsub;
	}
	minimum_ind($vals,(my $mmind=PDL->null));
	return ($simp->slice(":,$mmind"),"XXX");
}


