##############################################
#
# Quaternions... inefficiently.
#
# Should probably use PDL and C... ?
#
# Stored as [c,x,y,z].

package PDL::TriD::Quaternion;
use POSIX qw/acos/;
use OpenGL;

sub new {
	my($type,$c,$x,$y,$z) = @_;
	bless [$c,$x,$y,$z],$type;
}

# Yuck
sub multiply {
	my($this,$with) = @_;
	return PDL::TriD::Quaternion->new(
		$this->[0] * $with->[0] -
		$this->[1] * $with->[1] -
		$this->[2] * $with->[2] -
		$this->[3] * $with->[3],
			$this->[2] * $with->[3] -
			$this->[3] * $with->[2] +
			$this->[0] * $with->[1] +
			$this->[1] * $with->[0],
		$this->[3] * $with->[1] -
		$this->[1] * $with->[3] +
		$this->[0] * $with->[2] +
		$this->[2] * $with->[0],
			$this->[1] * $with->[2] -
			$this->[2] * $with->[1] +
			$this->[0] * $with->[3] +
			$this->[3] * $with->[0],
	);
}

sub set {
	my($this,$new) = @_;
	@$this = @$new;
}

sub add {
	my($this,$with) = @_;
	return PDL::TriD::Quaternion->new(
		$this->[0] * $with->[0],
		$this->[1] * $with->[1],
		$this->[2] * $with->[2],
		$this->[3] * $with->[3]);
}

sub abssq {
	my($this) = @_;
	return  $this->[0] ** 2 + 
		$this->[1] ** 2 +
		$this->[2] ** 2 +
		$this->[3] ** 2 ;
}

sub invert {
	my($this) = @_;
	my $abssq = $this->abssq();
	return PDL::TriD::Quaternion->new(
		 1/$abssq * $this->[0] ,
		-1/$abssq * $this->[1] ,
		-1/$abssq * $this->[2] ,
		-1/$abssq * $this->[3] );
}

sub invert_rotation_this {
	my($this) = @_;
	$this->[0] = - $this->[0];
}

sub normalize_this {
	my($this) = @_;
	my $abs = sqrt($this->abssq());
	@$this = map {$_/$abs} @$this;
}

sub togl {my($this) = @_;
	if(abs($this->[0]) == 1) { return ; }
	if(abs($this->[0]) >= 1) { die "Unnormalized Quaternion!\n"; }
	glRotatef(acos($this->[0])/3.14*360, @{$this}[1..3]);
}

1;
