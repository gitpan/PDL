=head1 NAME

PDL::LinICA -- Linear Independent Component Analysis (ICA) for PerlDL

=head1 SYNOPSIS

	use PDL::LinICA;

	$ica = new PDL::LinICA($data,4, # 4th degree linear ica.
		{ Accuracy => 0.01 });  # "scale" of data, for minimization

	$newdata = $ica->get_newdata();     # Get transformed data

	print $ica->check_independence(5,3,4); 
					# How independent are  dimensions 
					# 3 and 4 to 5th degree?
	$nodata = $ica->transform($otherdata);
					# Transform some other data.

	undef $ica; 			# Make sure nothing lingers.

=head1 WARNING

This package is not ready for prime-time yet.

=head1 DESCRIPTION

This package implements the linear independent component analysis
(ICA) algorithm described in [1]. The package first does a full PCA
analysis by finding the eigenvalues and -vectors of the covariance matrix
and transforming the data so that its covariance matrix becomes diagonal.

After this a rotation matrix parametrized by an antisymmetric matrix is 
optimized to yield the lowest values of diagonal cumulants.

The package includes some functions to test the resulting alleged
statistical independence between any components of your choosing.
This is very useful for data where you really cannot calculate the full
off-diagonal moment tensor.

The available options are

=over 8

=item Averaged

The data is already averaged. This is most useful when $data is HUGE
and you want to avoid extra copies at all costs.

=item Accuracy

A number that gives an approximate scale on how accurate the ICA
is. Currently not defined too well.

=back

=head1 REFERENCES

Deco & Obradovic: Information-theoretic ... NN. XXX

=head1 AUTHOR

Copyright (C) Tuomas J. Lukka 1997. 

=cut

package PDL::LinICA;

use PDL;
use PDL::Basic;
use PDL::Primitive;
use PDL::Slatec;
use PDL::Lib::PCA;
use PDL::Opt::Simplex;

sub new ($$$;$) {
	my($type,$data,$deg,$opts) = @_;
	if(!$opts->{Averaged}) {
		average($data->xchg(0,1),(my $da=PDL->null));
		$data = $data - $da;
	}
	my $me = bless {Data => $data,Deg => $deg},$type;
	$me->{DCovar} = $me->_covar($data);
	$me->{NVars} = $data->getdim(0);
	$me->_do_full_pca();
# We won't actually make the transformation to pca planes unless
# requested by the user. This is because the data set might be HUGE
# and we really don't want to make copies.
	return $me;
}

sub opt {
	my($me) = @_;
	$me->_optimize_ica();
}

sub _covar {
	my($this,$data) = @_;
	my $datax = $data->xchg(0,1);
# Data: (ninp, ndata)
# Datax: (ndata,ninp)
# Inner: (ndata, ndum1, ninp), (ndata, ninp, ndum2) => (ninp,ninp)
# neat.
	inner($datax->dummy(1),$datax->dummy(2),(my $covar = PDL->null));
	$covar;
}

sub _do_full_pca {
	my($this) = @_;
	(@{$this}{CEigvals,CEigmat}) = eigsys($this->{DCovar});
#	print "CEIGVMAT: $this->{CEigvals},$this->{CEigmat}\n";
	$this->{PCAMat}=$this->{CEigmat} / sqrt($this->{CEigvals}->dummy(0));
#	print "PCAMAt: $this->{PCAMat}\n";
}

sub _calc_diacumsum {
	my($this,$trans) = @_;
	my @dims = ($trans->dims);
	my $cum = PDL->zeroes($this->{Data}->getdim(0),$this->{Deg}-1,
		@dims[2..$#dims]);
	transdiacumusum($this->{Data},$trans,$cum);
	$cum /= $this->{Data}->getdim(1);
	sumover($cum->clump(2),(my $ccl = PDL->null));
	return $ccl;
}

sub transform {
	my($this,$data) = @_;
	my $rot = $this->_get_trans($this->{Optimum});
	inner($data->dummy(1),$rot->dummy(2),(my $res=PDL->null));
	return $res->slice(':,:,(0)');
}

sub transform_pca {
	my($this,$data) = @_;
	my $rot = $this->_get_zerotrans();
	inner($data->dummy(1),$rot->dummy(2),(my $res =PDL->null));
	$res;
#	return $res->slice(':,:,(0)');
}

sub transform_pca_nonorm {
	my($this,$data) = @_;
	inner($data->dummy(1),$this->{CEigmat}->dummy(2),(my $res = PDL->null));
	return $res;
}

sub get_newdata { my($this) = @_; 
	$this->{NData} or
	 $this->{NData} = $this->transform($this->{Data});  
}

sub _cayley2x2 {
	my($av) = @_;
	my $res = PDL->zeroes(2,2,$av->dims);
	(my $x=$res->diagonal(0,1)) .= 1;
	(my $y=$res->slice("(0),(1)")) .= $av;
	(my $z=$res->slice("(1),(0)")) .= -$av;
	$res /= sqrt(1 + $av ** 2);
	$res;
}

# ((1+A)(1-A)^-1)^-1 =
#  (1-A)(1+A)^-1 =
#  (1+A)^T (1-A)^T^-1 =
# 

sub _cayleygen {
	my($this,$av) = @_;
	my @dims = $av->dims; shift @dims; # All but first.
	my $mat = PDL->zeroes($this->{NVars}, $this->{NVars},
			@dims);
#	print "ToVec2Asym($av)";
	vec2asym($av,$mat);
#	print "Got $mat\n";
	my $mat2 = $mat;
	$mat = -1 * $mat;
	(my $t = $mat->diagonal(0,1)) ++;
	($t = $mat2->diagonal(0,1)) ++;
	print "Mat2noinv: $mat2\n";
	$mat2 = inv($mat2);

	print "Mat1,2: $mat,$mat2\n";

#	inner($mat->xchg(0,1)->dummy(2),$mat2->xchg(0,1)->dummy(1),(my $res = PDL->null));
	inner($mat->dummy(2),$mat2->xchg(0,1)->dummy(1),(my $res = PDL->null));
#	inner($mat->dummy(1),$mat2->dummy(2),(my $res = PDL->null));

	return $res;
}

sub _get_trans {
	my($this,$av) = @_;
	my $rot = $this->_cayleygen($av);
	inner($this->{PCAMat}->xchg(0,1)->dummy(2),$rot->dummy(1),
		(my $res = PDL->null));
	print "Rot,Res: $rot,$res\n";
	return $res;
}

sub _get_zeroparvec {
	my($this) = @_;
	return 0.5+PDL->zeroes($this->{NVars} * ($this->{NVars}-1) / 2);
}

sub _get_zerotrans {
	my($this) = @_;
	return $this->_get_trans($this->_get_zeroparvec());
}

sub _evalcum {
# Everything should be threading ok!
	my($this,$x) = @_;
	my $rot = $this->_get_trans($x);
	print "ROT: $rot\n";
	my $res = $this->_calc_diacumsum($rot);
	print "EVALCUM: $res\n";
	return $res;
#	return $res->slice("(0)");
#	return $res;
}

sub _optimize_ica {
	my($this) = @_;
	($opt,$min) = simplex(
		$this->_get_zeroparvec(),
		0.1,
		0.001,
		40,
		sub{$this->_evalcum(@_)},
		sub {print "NOW: @_\n";}
	);
	$this->{Optimum} = $opt;
}

#sub _indep_list {
#	my($this,$deg,$nvars) = @_;
## First generate list of what we want.
#	my @which = map {0} 1..$deg;
#	my @dg = map {0} @list;
#	for(;;) {
#		
#	}
#}

1;
