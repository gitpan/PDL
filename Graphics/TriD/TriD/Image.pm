
# What makes this complicated is that we want
# imag(3,x,y,z,q,d,f) 
# appear in one 2D image, flattened out appropriately, with 
# one black space between the subimages.
# The X coordinate will be ((x+1)*z+1)*d and the 
# Y coordinate ((y+1)*q+1)*f. We need to use splitdim to obtain
# a piddle of the imag dimensions from the flat piddle.

package PDL::Graphics::TriD::Image;
@ISA=qw/PDL::Graphics::TriD::Object/;
use PDL::Graphics::OpenGL;
use PDL;

my $defaultvert = PDL->pdl([
	[0,0,0],
	[1,0,0],
	[1,1,0],
	[0,1,0]
]);

# r,g,b = 0..1
sub new {
	my($type,$color,$opts) = @_;
	my $im = PDL::Graphics::TriD::realcoords(COLOR,$color);
	my $this = {
		Im => $im,
		Opts => $opts,
		Points => $defaultvert,
	};
	if(defined $opts->{Points}) {
		$this->{Points} = $opts->{Points};
		if("ARRAY" eq ref $this->{Points}) {
			$this->{Points} = PDL->pdl($this->{Points});
		}
	}
	bless $this,$type;
}

sub get_points {
	return $_[0]->{Points};
}

# In the future, have this happen automatically by the piddles.
sub data_changed {
	my($this) = @_;
	$this->changed();
}

# In the future, have this happen automatically by the piddles.
sub data_changed {
	my($this) = @_;
	$this->changed();
}

sub togl {
	$_[0]->gdraw();
}

sub togl_graph {
	&togl;
}

# The quick method is to use texturing for the good effect.
sub gdraw {
	my($this,$vert) = @_;
	my($x,$y);
	my @dims = $this->{Im}->dims;
	shift @dims; # get rid of the '3'
	my $xd = $dims[0]; my $yd = $dims[1];
	my $xdr = $xd; my $ydr = $yd;
# Calculate the whole width of the image.
	my $ind = 0;
	my $xm = 0; my $ym = 0;
	for(@dims[2..$#dims]) {
		if($ind % 2 == 0) {
			$xd ++; # = $dims[$ind-2];
			$xd *= $_;
			$xdr ++;
			$xdr *= $_;
#			$xd --; # = $dims[$ind-2];
			$xm++;
		} else {
			$yd ++; # = $dims[$ind-2];
			$yd *= $_;
			$ydr ++;
			$ydr *= $_;
#			$yd --; # = $dims[$ind-2];
			$ym++;
		}
		$ind++;
	}
	$xd -= $xm; $yd -= $ym;

# R because the final texture must be 2**x-aligned ;(
	my ($txd ,$tyd);
	for($txd = 0; $txd < 10 and 2**$txd < $xdr; $txd++) {};
	for($tyd = 0; $tyd < 10 and 2**$tyd < $ydr; $tyd++) {};
	$txd = 2**$txd; $tyd = 2**$tyd;
	my $xxd = ($xdr > $txd ? $xdr : $txd);
	my $yyd = ($ydr > $tyd ? $ydr : $tyd);

	if($#dims > 1) {
#		print "XALL: $xd $yd $xdr $ydr $txd $tyd\n";
#		print "DIMS: ",(join ',',$this->{Im}->dims),"\n";
	}

use PDL::Dbg;
#	$PDL::verbose=1;

	my $p = PDL->zeroes(PDL::float(),3,$xxd,$yyd);


	if(defined $this->{Opts}{Bg}) {
		$p .= $this->{Opts}{Bg};
	}

#	print "MKFOOP\n";
	my $foop = $p->slice(":,0:".($xdr-1).",0:".($ydr-1));


	$ind = $#dims;
	my $firstx = 1;
	my $firsty = 1;
	my $spi;
	for(@dims[reverse(2..$#dims)]) {
		$foop->make_physdims();
#		print "FOOP: \n"; $foop->dump;
		if($ind % 2 == 0) {
			$spi = $foop->getdim(1)/$_;
			$foop = $foop->splitdim(1,$spi)->slice(":,0:-2")->
				mv(2,3);
		} else {
			$spi = $foop->getdim(2)/$_;
			$foop = $foop->splitdim(2,$spi)->slice(":,:,0:-2");
		}
#		print "IND+\n";
		$ind++; # Just to keep even/odd correct
	}
#	$foop->dump;
	print "ASSGNFOOP!\n" if $PDL::verbose;

	$foop .= $this->{Im};
#	print "P: $p\n";
	glColor3d(1,1,1);
	glTexImage2D(&GL_TEXTURE_2D,
		0,
		&GL_RGB,
		$txd,
		$tyd,
		0,
		&GL_RGB,
		&GL_FLOAT,
		${$p->get_dataref()}
	);
	 glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
	    glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
	       glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT );
	          glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT );
		    
	glDisable(&GL_LIGHTING);
	glNormal3d(0,0,1);
	glEnable(&GL_TEXTURE_2D);
	glBegin(&GL_QUADS);
	my @texvert = (
		[0,0],
		[$xd/$txd, 0],
		[$xd/$txd, $yd/$tyd],
		[0, $yd/$tyd]
	);
	if(!defined $vert) {$vert = $this->{Points}}
	for(0..3) {
#	for([0,0],[$xd/$txd,0],[$xd/$txd,$yd/$tyd],[0,$yd/$tyd]) {
		glTexCoord2f(@{$texvert[$_]});
		glVertex3f($vert->slice(":,($_)")->list);
	}
	glEnd();
	glEnable(&GL_LIGHTING);
	glDisable(&GL_TEXTURE_2D);
}

# XXX NOT USED

# The careful method is to plot the image as quadrilaterals inside
# the 0..1,0..1,0 box
sub togl_old {
	my($this) = @_;
	my($x,$y);
	my @dims = $this->{Im}->dims;
	shift @dims; # remove the '3'
	glDisable(GL_LIGHTING);
	glNormal3d(0,0,1);
	my $xmul = 1.0/$dims[0]; my $ymul = 1.0/$dims[1];
#	print "IMAG2GL, $this->{R}, $this->{G}, $this->{B}\n";
	my @rvals = $this->{R}->list;
	my @gvals = $this->{G}->list;
	my @bvals = $this->{B}->list;
	for $x (0..$dims[0]-1) {
#		print "$x\n";
		for $y (0..$dims[1]-1) {
			glColor3f((shift @rvals),(shift @gvals),(shift @bvals));
			glRectd($x*$xmul,$y*$ymul,
				($x+1)*$xmul,($y+1)*$ymul);
		}
	}
#	print "IMAGDONE\n";
	glEnd();
	glEnable(GL_LIGHTING);
}
