#
#
# This file is currently *not supported*. 
# 
# If you want the pumpkin for this file, email pdl-porters.
#


package PDL::TriD::GL;

$PDL::TriD::create_window_sub = sub {
	return new PDL::TriD::GL::Window;
};

package PDL::TriD::Object;
use OpenGL;

sub update_list {
	my($this) = @_;
	if($this->{List}) {
		glDeleteLists($this->{List},1);
	}
	my $lno = glGenLists(1);
	$this->{List} = $lno;
	print "GENLIST $lno\n";
	glNewList($lno,GL_COMPILE);
	for(@{$this->{Objects}}) {
		$_->togl();
	}
	print "EGENLIST $lno\n";
#	pdltotrianglemesh($pdl, 0, 1, 0, ($pdl->{Dims}[1]-1)*$mult);
	glEndList();
}

sub call_list {
	my($this) = @_;
	print "CALLIST $this->{List}!\n";
	glCallList($this->{List});
}

sub togl {
	my($this) = @_;
	for(@{$this->{Objects}}) { $_->togl() }
}


##############################################
#
# A window with mouse control over rotation.
#
# Do not make two of these!
#
package PDL::TriD::GL::Window;
use OpenGL;
@ISA = qw/PDL::TriD::Object/;
use strict;
$PDL::TriD::GL::size = 300;

sub new {my($type) = @_;
	glpOpenWindow(attributes=>[GLX_RGBA,GLX_DOUBLEBUFFER],
		mask => (KeyPressMask | ButtonPressMask |
			ButtonMotionMask | ButtonReleaseMask |
			StructureNotifyMask),
		width => $PDL::TriD::GL::size, height => $PDL::TriD::GL::size);
	glClearColor(0,0,0,1);
	glShadeModel (GL_FLAT);
	glEnable(GL_DEPTH_TEST);
	glEnable(GL_NORMALIZE);
	glEnable(GL_LIGHTING);
	glEnable(GL_LIGHT0);
	glLightModeli(GL_LIGHT_MODEL_TWO_SIDE, GL_TRUE);
	my $this = bless {
		"Ev" => {	&ConfigureNotify => \&doconfig,
				&MotionNotify => \&domotion,
		},
		"Angle" => 0.0,
		"Mouse" => [undef,undef,undef],
	},$type;
	$this->reshape();
	my $light = pack "f*",1.0,1.0,1.0,0.0;
	glLightfv(GL_LIGHT0,GL_POSITION,$light);
	my $shin = pack "f*",20.0;
	glMaterialfv(GL_FRONT_AND_BACK,GL_SHININESS,$shin);
	my $spec = pack "f*",1.0,0.0,0.0,0.0;
	glMaterialfv(GL_FRONT_AND_BACK,GL_SPECULAR,$spec);
	my $amb = pack "f*",0.0,1.0,0.0,0.0;
	glMaterialfv(GL_FRONT_AND_BACK,GL_AMBIENT,$amb);
	my $diff = pack "f*",0.0,0.0,1.0,0.0;
	glMaterialfv(GL_FRONT_AND_BACK,GL_DIFFUSE,$diff);

	glColor3f(1,1,1);

	return $this;
}

sub get_size {return ($PDL::TriD::GL::size,$PDL::TriD::GL::size);}

sub set_eventhandler {my($this,$handler) = @_;
	$this->{EHandler} = $handler;
}

sub set_transformer {my($this,$transform) = @_;
	$this->{Transformer} = $transform;
}

sub reshape {
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
#	glOrtho (-50.0, 50.0, -50.0,50.0,-1.0,1.0);
	gluPerspective(60.0, 1.0 , 0.1, 20.0);
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity ();
#	glTranslatef(0,0,-3);
}

sub setlist { my($this,$list) = @_;
	$this->{List} = $list;
	
}

sub doconfig {
	my($this) = @_;
	$this->reshape();
	print "CONFIGURENOTIFY\n";
}

sub domotion {
	my($this) = @_;
	print "MOTIONENOTIFY\n";
}

sub display {my($this) = @_;
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	glPushMatrix();
	if($this->{Transformer}) {
		print "Transforming!\n";
		$this->{Transformer}->togl();
		$this->call_list();
	} else {
		glTranslatef(0,0,-3);
		glRotatef($this->{"Angle"},sin($this->{"Angle"}/360),cos($this->{"Angle"}/360),
			sin(2.5*$this->{Angle}/360));
	}
	glCallList($this->{List});
	glPopMatrix();
	glFlush();
	glXSwapBuffers();
	$this->{Angle}+= 3;
}

sub twiddle {my($this) = @_;
	my ($p,@e);
	$this->display();
#	while($p = &XPending()) {
	TWIDLOOP: while(1) {
		print "EVENT!\n";
		@e = &glpXNextEvent();
		if($e[0] == &ConfigureNotify) {
			$this->reshape();
		}
		if($e[0] == &KeyPress) {
			print "KEYPRESS: '$e[1]'\n";
			if((lc $e[1]) eq "q") {
				last TWIDLOOP;
			}
		}
		if(defined($this->{EHandler})) {
			print "HANDLING\n";
			$this->{EHandler}->event(@e);
		}
		if(!&XPending()) {$this->display();}
	}
	print "STOPTWIDDLE\n";
}

###############
#
# Because of the way GL does texturing, this must be the very last thing
# in the object stack before the actual surface. There must not be any
# transformations after this.
# 
# There may be several of these but all of these must have just one texture.
package PDL::TriD::GL::SliceTexture;
use OpenGL;

@PDL::TriD::GL::SliceTexture::ISA = /PDL::TriD::Object/;

sub new {
	my $image;
	glPixelStorei(GL_UNPACK_ALIGNMENT,1);
	glTexImage1D(GL_TEXTURE_1D,0 , 4, 2,0,GL_RGBA,GL_UNSIGNED_BYTE,
		$image);
	glTexParameterf(GL_TEXTURE_1D,GL_TEXTURE_WRAP_S,GL_CLAMP);
	glTexEnvf(GL_TEXTURE_ENV,GL_TEXTURE_ENV_MODE,GL_DECAL);
	
}

sub togl {
	my ($this) = @_;
	glEnable(GL_TEXTURE_1D);
	glTexGen();
	$this->SUPER::togl();
	glDisable(GL_TEXTURE_1D);
}



1;
