##############################################
#
# Quaternions... inefficiently.
#
# Should probably use PDL and C... ?
#
# Stored as [c,x,y,z].

package PDL::Graphics::TriD::Quaternion;

sub new {
	my($type,$c,$x,$y,$z) = @_;
	my $this = bless [$c,$x,$y,$z],$type;
	$this->normalize_this();
	return $this;
}

# Yuck
sub multiply {
	my($this,$with) = @_;
	return PDL::Graphics::TriD::Quaternion->new(
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
	return PDL::Graphics::TriD::Quaternion->new(
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
	return PDL::Graphics::TriD::Quaternion->new(
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

sub rotate {
  my ($this,$vec) = @_;
#  print "CP: ",(join ',',@$this)," and ",(join ',',@$vec),"\n";
  return $vec if $this->[0] == 1 or $this->[0] == -1;
# 1. cross product of my vector and rotated vector
# XXX I'm not sure of any signs!
  my @u = @$this[1..3];
  my @v = @$vec;
  my @cp = (
  	$u[1] * $v[2] - $u[2] * $v[1],
  	$u[0] * $v[2] - $u[2] * $v[0],
  	$u[0] * $v[1] - $u[1] * $v[0],
  );
# Cross product of this and my vector
  my @cp2 = (
  	$u[1] * $cp[2] - $u[2] * $cp[1],
  	$u[0] * $cp[2] - $u[2] * $cp[0],
  	$u[0] * $cp[1] - $u[1] * $cp[0],
  );
  my $mult1 = (1-$this->[0]);
  my $mult2 = sqrt(1-$this->[0]**2);
  my $res = [map {
  	$v[$_] - $mult1 * $cp2[$_] + $mult2 * $cp[$_]
  } 0..2];
#  print "RES: ",(join ',',@$res),"\n";
  return $res;
}

1;
