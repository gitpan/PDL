###################################################
#
#	ArcBall.pm
#
# 	From Graphics Gems IV.
#
# This is an example of the controller class:
# the routines set_wh and mouse_moved are the standard routines.
#
# This needs a faster implementation (?)


#
# Original ArcBall
#
package PDL::Graphics::TriD::ArcBall;

@ISA = qw/PDL::Graphics::TriD::QuaterController/;

# x,y to unit quaternion on the sphere.
sub normxy2qua {
	my($this,$x,$y) = @_;
	my $dist = sqrt ($x ** 2 + $y ** 2);
	if($dist > 1.0) {$x /= $dist; $y /= $dist; $dist = 1.0;}
	my $z = sqrt(1-$dist**2);
	return PDL::Graphics::TriD::Quaternion->new(0,$x,$y,$z);
}

# Tjl's version: a cone - more even change of 
package PDL::Graphics::TriD::ArcCone;

@ISA = qw/PDL::Graphics::TriD::QuaterController/;

# x,y to unit quaternion on the sphere.
sub normxy2qua {
	my($this,$x,$y) = @_;
	my $dist = sqrt ($x ** 2 + $y ** 2);
	if($dist > 1.0) {$x /= $dist; $y /= $dist; $dist = 1.0;}
	my $z = 1-$dist;
	my $qua = PDL::Graphics::TriD::Quaternion->new(0,$x,$y,$z);
	$qua->normalize_this();
	return $qua;
}

# Tjl's version2: a bowl -- angle is proportional to displacement.
package PDL::Graphics::TriD::ArcBowl;

@ISA = qw/PDL::Graphics::TriD::QuaterController/;

# x,y to unit quaternion on the sphere.
sub normxy2qua {
	my($this,$x,$y) = @_;
	my $dist = sqrt ($x ** 2 + $y ** 2);
	if($dist > 1.0) {$x /= $dist; $y /= $dist; $dist = 1.0;}
	my $z = cos($dist*3.142/2);
	my $qua = PDL::Graphics::TriD::Quaternion->new(0,$x,$y,$z);
	$qua->normalize_this();
	return $qua;
}


package PDL::Graphics::TriD::QuaterController;

# use PDL::Quaternion;

sub new {my($type,$win,$inv,$quat) = @_;
	my $this = {
		Inv => $inv,
		Quat => (defined($quat) ? $quat : 
			new PDL::Graphics::TriD::Quaternion(1,0,0,0))
	};
	bless $this,$type;
#	$this->set_wh($w,$h);
	$win->add_resizecommand(sub {$this->set_wh(@_)});
	return $this;
}

sub set_wh {
	my($this,$w,$h) = @_;
	print "ARCSETWH: $w,$h\n" if $PDL::Graphics::TriD::verbose;
	$this->{W} = $w; $this->{H} = $h;
	if($w > $h) {
		$this->{SC} = $h/2;
	} else {
		$this->{SC} = $w/2;
	}
}

sub xy2qua {
	my($this,$x,$y) = @_;
	$x -= $this->{W}/2; $y -= $this->{H}/2;
	$x /= $this->{SC}; $y /= $this->{SC};
	$y = -$y; 
	return $this->normxy2qua($x,$y);
}

sub mouse_moved {
	my($this,$x0,$y0,$x1,$y1) = @_;
#	print "ARCBALL: $x0,$y0,$x1,$y1,$this->{W},$this->{H},$this->{SC}\n";
# Convert both to quaternions.
	my ($qua0,$qua1) = ($this->xy2qua($x0,$y0),$this->xy2qua($x1,$y1));
	my $arc = $qua1->multiply($qua0->invert());
#	my $arc = $qua0->invert()->multiply($qua1);
	if($this->{Inv}) {
		$arc->invert_rotation_this();
	}
	$this->{Quat}->set($arc->multiply($this->{Quat}));
#	$this->{Quat}->set($this->{Quat}->multiply($arc));
}



1;
