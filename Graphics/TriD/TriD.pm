=head1 NAME

PDL::TriD -- PDL 3D interface

=head1 WARNING

These modules are still in very unfocused state: don't use them yet
if you don't know how to make them work if they happen to do something
strange.

=head1 DESCRIPTION

This module implements a generic 3D plotting interface for PDL.
Points, lines and surfaces are supported.

The key concepts (object types) of TriD are explained in the following:

=head2 Window

This is the object on the "highest" or "lowest" level of abstraction,
depending on how you look at it. A window is simply a view to a 3D
World. Camera is an often-used synonym for Window.

=head2 World

A collection of 3D objects and information about their relationships.
A world has an absolute coordinate system.

=head2 Transformation

An "object" which may contain other objects, which it transforms.

=head2 Object

There are different types of actual objects, like Box, Mesh, Line
or Point. Most of these object types can contain several objects
of the same type, indicated by giving parameters with more dimensions
than necessary for one object.

=cut

package PDL::TriD::Basic;
package PDL::TriD;
use PDL::TriD::Quaternion;
use PDL::TriD::ArcBall;
use PDL::TriD::Mesh;
use PDL::TriD::Lines;
use PDL::TriD::Surface;
use PDL::TriD::Control3D;

# Then, see which display method are we using:

BEGIN {
	my $dev;
	if(!defined ($dev = $::ENV{PDL_3D_DEVICE})) {
		warn "Default PDL 3D device is OOGL: do you have Geomview installed?
Set PDL_3D_DEVICE=OOGL in the future in order not to see this warning.";
		$dev = "OOGL";
	}
	my $dv;
# The following is just a sanity check.
	for($dev) {
		(/^OOGL$/  and $dv="PDL::TriD::OOGL") or
		(/^GL$/  and $dv="PDL::TriD::GL") or
		(die "Invalid PDL 3D device '$_' specified!");
	}
	my $mod = $dv;
	$mod =~ s|::|//|g;
	require "$mod.pm";
	$dv->import;
}

require qw(Exporter);
@ISA = qw/Exporter/;
@EXPORT = qw/imag3d line3d/;

sub objplotcommand {
	my($object) = @_;
	my $win = PDL::TriD::get_current_window();
	my $world = $win->world();
}

sub imag3d {
	my ($data) = @_;
	my $win = PDL::TriD::get_current_window();
	my $mesh = new PDL::TriD::Mesh($data);
	$mesh->normals_flat();
	my $bbox = $mesh->get_boundingbox();
	my $trans = $bbox->normalize(-1,-1,-0.5,1,1,0.5);
	$trans->add_object($mesh);
	$trans->add_object($bbox);
	$win->clear_objects();
	$win->add_object($trans);
	$win->update_list();
	$win->twiddle();
}

# Call: line3d($x,$y,[$z,[$color]]);
sub line3d {
	my($x,$y,$z,$color) = @_;
# fill in undefined args.
	$z = xvals $x 			if !defined $z;
	$color = PDL->pdl(1)  	if !defined $color;
# Std:
	my $win = PDL::TriD::get_current_window();
	my $lines = new PDL::TriD::Lines($x,$y,$z,$color);
	my $bbox = $lines->get_boundingbox();
	my $trans = $bbox->normalize(-1,-1,-1,1,1,1);
	$trans->add_object($lines);
	$trans->add_object($bbox);
	$win->clear_objects();
	$win->add_object($trans);
	$win->update_list();
	$win->twiddle();
}

$PDL::TriD::cur = {};
$PDL::TriD::create_window_sub = undef;
sub get_current_window {
	my $win = $PDL::TriD::cur;
	if(!$win->{Window}) {
		if(!$PDL::TriD::create_window_sub) {
			croak("PDL::TriD must be used with a display mechanism: for example PDL::TriD::GL!\n");
		}
		$win->{Window} = & $PDL::TriD::create_window_sub();
		$win->{EventHandler} = new PDL::TriD::EventHandler();
		$win->{Window}->set_eventhandler($win->{EventHandler});
		$win->{Control} = new PDL::TriD::SimpleController();
		$win->{ArcBall1} = new PDL::TriD::ArcBall(
			$win->{Window}->get_size(), 0, 
			$win->{Control}{WRotation});
		$win->{EventHandler}->set_button(0,$win->{ArcBall1});
		$win->{Window}->set_transformer($win->{Control});
		$PDL::TriD::current_window = $win->{Window};
	}
	return $PDL::TriD::current_window;
}

###################################
#
#
package PDL::TriD::BoundingBox;

sub new { my($type,$x0,$y0,$z0,$x1,$y1,$z1) = @_;
	bless [$x0,$y0,$z0,$x1,$y1,$z1],$type;
}

sub normalize {my($this,$x0,$y0,$z0,$x1,$y1,$z1) = @_;
	my $trans = PDL::TriD::Transformation->new();
	my $sx = ($x1-$x0)/($this->[3]-$this->[0]);
	my $sy = ($y1-$y0)/($this->[4]-$this->[1]);
	my $sz = ($z1-$z0)/($this->[5]-$this->[2]);
	$trans->add_transformation(
		PDL::TriD::Translation->new(
			($x0-$this->[0]*$sx),
			($y0-$this->[1]*$sy),
			($z0-$this->[2]*$sz)
		));
	$trans->add_transformation(PDL::TriD::Scale->new($sx,$sy,$sz));
	return $trans;
}

sub togl { my($this) = @_;
	OpenGL::glBegin(&OpenGL::GL_LINE_STRIP);
	for([0,4,2],[0,1,2],[0,1,5],[0,4,5],[0,4,2],[3,4,2],
		[3,1,2],[3,1,5],[3,4,5],[3,4,2]) {
		OpenGL::glVertex3d(@{$this}[@$_]);
	}
	OpenGL::glEnd();
	OpenGL::glBegin(&OpenGL::GL_LINES);
	for([0,1,2],[3,1,2],[0,1,5],[3,1,5],[0,4,5],[3,4,5]) {
		OpenGL::glVertex3d(@{$this}[@$_]);
	}
	OpenGL::glEnd();
}

###################################
#
#
package PDL::TriD::Object;

sub clear_objects() {
	my($this) = @_;
	$this->{Objects} = [];
}

sub add_object() {
	my($this,$object) = @_;
	push @{$this->{Objects}},$object;
}

###################################
#
#
package PDL::TriD::Scale;
@ISA = qw/PDL::TriD::OneTransformation/;
sub togl {my ($this) = @_;
	print "Scale ",(join ',',@{$this->{Args}}),"\n";
	OpenGL::glScalef(@{$this->{Args}});
}

#package PDL::TriD::Rotation;
#@ISA = qw/PDL::TriD::OneTransformation/;

package PDL::TriD::Translation;
@ISA = qw/PDL::TriD::OneTransformation/;
sub togl {my($this) = @_;
	print "Transl ",(join ',',@{$this->{Args}}),"\n";
	OpenGL::glTranslatef(@{$this->{Args}});
}

package PDL::TriD::OneTransformation;

sub new {
	my($type,@args) = @_;
	my $this = {Args => [@args]};
	bless $this,$type;
}

package PDL::TriD::Transformation;
@ISA = qw/PDL::TriD::Object/;

sub new {
	my($type) = @_;
	bless {},$type;
}

sub add_transformation {
	my($this,$trans) = @_;
	push @{$this->{Transforms}},$trans;
}

sub togl {
	my($this) = @_;
	OpenGL::glPushMatrix();
	for (@{$this->{Transforms}}) {$_->togl();}
	$this->SUPER::togl();
	OpenGL::glPopMatrix();
}

=head1 BUGS

Not well enough documented. 

Not enough is there yet.

=head1 AUTHOR

Copyright (C) 1997 Tuomas J. Lukka. Redistribution in book form
forbidden.

=cut
