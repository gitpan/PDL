=head1 NAME

PDL::PCA - Principal Component Analysis routines for PDL

=head1 SYNOPSIS

	$a = new PDL::PCA($data,{Averaged => 1,IncludeDims => 2});

	$tdata = $a->trans();

	$todata = $a->trans($otherdata);

	$wdata = $a->wtrans();  # Get whitened data

	$tmat = $a->get_trans(); # Get trans matrix

=head1 WARNING

This is alpha-state code.

=head1 DESCRIPTION

This module implements several different algorithms for doing
PCA, both off-line (statistics based) and on-line (neural-type) (XXX
on-line not yet implemented).

The Averaged and IncludeDims flags are for use when you absolutely
want to conserve space (i.e. $data is HUGE).

=cut

package PDL::PCA;
use PDL::Basic;
use PDL::Primitive;
use PDL::Slatec;
use strict;

sub new ($$;$) {
	my($type,$data,$opts) = @_;
	$data = $this->_average_if($data,$opts);
	$this->{Data} = $data;
	$this->{DCovar} = $this->_covar($data);
	$this->_do_full_pca();
}

sub trans ($;$) {
	my($this,$data) = @_;
	$data = ($data or 
}

sub _average_if {
	my($this,$data,$opts) = @_;
	if(!$opts->{Averaged}) {
		average($data->xchg(0,1),(my $da=PDL->null));
		for(1..($opts->{IncludeDims} or 0)) {
			average($da->xchg(0,1),(my $nda=PDL->null));
			$da = $nda;
		}
		$data = $data - $da;
	}
	$data;
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
}

sub _get_wmat {
	my($this) = @_;
	if(!defined $this->{WPCAMat}) {
		$this->{WPCAMat}=$this->{CEigmat} / sqrt($this->{CEigvals}->dummy(0));
	}
#	print "PCAMAt: $this->{WPCAMat}\n";
	$this->{WPCAMat};
}




