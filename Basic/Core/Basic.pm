package PDL::Basic;
use PDL::Core;
@ISA=qw/PDL::Exporter/;
@EXPORT_OK = qw/ rvals axisvals xvals yvals zvals sec ins 
	similar_assign transpose sequence min max sum average avg/;

@EXPORT_STATIC = qw/ sequence /;

# Conveniently named interfaces to axisvals()

sub xvals{ axisvals(shift,0) };
sub yvals{ axisvals(shift,1) };
sub zvals{ axisvals(shift,2) };

# Create array filled with a sequence

use Carp;

sub sequence {
    croak 'Usage: $a = sequence($nx, $ny, $nz ...) or PDL->sequence(...)' 
    	if $#_<1;
    my $class = shift;  my @n = @_; my $n;
    my $nelem = 1; for $n (@n) { croak "Dims must be > 0\n" unless $n>0; $nelem *= $n}
    $pdl = zeroes($nelem); 
    xvals(inplace($pdl)); $$pdl{Dims} = [@_];
    $pdl->flush;
    return $pdl;
} 

sub average {
   my($pdli,$pdlo) = @_;
   PDL::Primitive::sumover($pdli,$pdlo);
   $pdlo /= ($pdli->dims)[0]; # XXX Wont flow right :(
}

sub avg {
   my($pdl) = @_;
   my($tmp) = PDL->null;
   average($pdl->clump(-1),$tmp); $tmp;
}

sub min {
	my($name) = @_; my $tmp;
	PDL::Primitive::minimum($name->clump(-1),($tmp=null));
	return $tmp->at();
}

sub max {
	my($name) = @_; my $tmp;
	PDL::Primitive::maximum($name->clump(-1),($tmp=null));
	return $tmp->at();
}

sub sum {
	my($name) = @_; my $tmp;
	PDL::Primitive::sumover($name->clump(-1),($tmp=null));
	return $tmp->at();
}

sub rvals { # Return radial distance from center in N-dims
    my $x = topdl($PDL::name,shift);
    my $y = $x*0.0;
    my $i;
    for ($i=0; $i<scalar(@{$$x{Dims}}); $i++) {
        $y += (axisvals($x,$i)-int($$x{Dims}[$i]/2))**2;
    }
    return sqrt($y);
}

sub axisvals {
	my($this,$nth) = @_;
	my $dummy = PDL::Core::new_or_inplace($this);
	if($dummy->getndims() <= $nth) {
		croak("Too few dimensions given to axisvals $nth\n");
	}
	my $bar = $dummy->xchg(0,$nth);
	PDL::Primitive::axisvalues($bar);
	return $dummy;
}

sub sec {
	my($this,@coords) = @_;
	my $i; my @maps;
	while($#coords > -1) {
		$i = (shift @coords) ;
		push @maps, "$i:".(shift @coords);
	}
	my $tmp = PDL->null;
	$tmp .= $this->slice(join ',',@maps);
	return $tmp;
}

sub ins {
	my($this,$what,@coords) = @_;
	my $w = PDL::Core::alltopdl($PDL::name,$what);
	my $tmp;
	($tmp = $this->map(
	   (join ',',map {"$coords[$_]:".
	   	(($coords[$_]+$w->{Dims}[$_]-1)<$this->{Dims}[$_] ?
	   	($coords[$_]+$w->{Dims}[$_]-1):$this->{Dims}[$_])
	   	} 
	   	0..$#coords)))
		.= $w;
}

sub similar_assign {
	my($from,$to) = @_;
	if((join ',',@{$from->{Dims}}) ne (join ',',@{$to->{Dims}})) {
		confess "Similar_assign: dimensions [".
			(join ',',@{$from->{Dims}})."] and [".
			(join ',',@{$to->{Dims}})."] do not match!\n";
	}
	$to .= $from;
}

sub transpose {
	my($this) = @_;
	if($#{$this->{Dims}} == 0) {
# 1-Dim: add dummy
		return pdl $this->dummy(0);
	}
	my $tmp = PDL->null;
	$tmp .= $this->xchg(0,1);
	return $tmp;
}

1;

