package PDL::TriD::Control3D;

# Mustn't have empty package in some perl versions.

package PDL::TriD::EventHandler;
use OpenGL;
use strict;

sub new {
	my($type) = @_;
	my $this = bless {X => -1, Y => -1,Buttons => []},$type;
	return $this;
}

sub event {
	my($this,$type,@args) = @_;
	print "EH: $type\n";
	if($type == &MotionNotify) {
		print "MOTION\n";
		if($args[0] & (&Button1Mask)) {
			print "BUTTON1MOTION\n";
			if($this->{Buttons}[0]) {
				$this->{Buttons}[0]->mouse_moved(
					$this->{X},$this->{Y},
					$args[1],$args[2]);
			}
		}
		$this->{X} = $args[1]; $this->{Y} = $args[2];
	} elsif($type == &ButtonPress) {
		print "BUTTONPRESS\n";
		$this->{X} = $args[1]; $this->{Y} = $args[2];
	} elsif($type == &ButtonRelease) {
		print "BUTTONRELEASE\n";
	}
}

sub set_button {
	my($this,$butno,$act) = @_;
	$this->{Buttons}[$butno] = $act;
}

##############################################
#
# A quaternion-based controller framework with the following transformations:
#   1. world "origin". This is what the world revolves around
#   2. world "rotation" at origin.
#   3. camera "distance" along z axis after that (camera looks 
#	at negative z axis).
#   4. camera "rotation" after that (not always usable).

package PDL::TriD::SimpleController;
use OpenGL;
use strict;

sub new {
	my($type) = @_;
	my $this = bless {
	},$type;
	$this->reset();
	return $this;
}

sub normalize { my($this) = @_;
	$this->{WRotation}->normalize_this();
	$this->{CRotation}->normalize_this();
}

sub reset { my($this) = @_;
	$this->{WOrigin}   = [0,0,0];
	$this->{WRotation} = PDL::TriD::Quaternion->new(1,0,0,0);
	$this->{CDistance} = 5;
	$this->{CRotation} = PDL::TriD::Quaternion->new(1,0,0,0);
}

sub togl {
	my($this) = @_;
	print "CONTROL\n";
	$this->{CRotation}->togl();
	glTranslatef(0,0,-$this->{CDistance});
	$this->{WRotation}->togl();
	glTranslatef(map {-$_} @{$this->{WOrigin}});
}


1;
