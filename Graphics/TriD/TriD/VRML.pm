use PDL::Graphics::VRML;
use PDL::LiteF;
PDL::Graphics::VRMLNode->import();
PDL::Graphics::VRMLProto->import();

sub PDL::Graphics::TriD::Logo::tovrml {
   my ($this) = @_;
   my ($p,$tri) = ("","");
   PDL::Graphics::VRMLPdlNode::v3array($this->{Points},\$p,"");
   PDL::Graphics::VRMLPdlNode::triangles((map 
                     {$this->{Index}->slice("($_)")} (0..2)),\$tri,"");
   my $indface = vrn('IndexedFaceSet',
                    'coord' => vrn('Coordinate',
                                   'point' => "[ $p ]"),
                    'coordIndex' => "[ $tri ]",
                    'solid' => 'TRUE');
   return vrn('Transform',
              'children' => [vrn('Anchor',
                                 'description' => "\"The PDL Homepage\"",
                                 'url' => 
"\"http://www.aao.gov.au/local/www/kgb/perldl/\"",
                                 'children' => vrn('Shape',
                                                   'appearance' => vrn('Appearance',
                                                                       'material' => 
$this->{Material}->tovrml),
                                                   'geometry' => $indface)),
			vrn(Viewpoint,
				position => '0 0 25',
				description => "\"PDL Logo\""
			)
						   
		],
              'translation' => vrml3v($this->{Pos}),
              'scale'    => vrml3v([map {$this->{Size}} (0..2)]));
}

sub PDL::Graphics::TriD::Description::tovrml {
	my($this) = @_;
#	print "DESCRTIPTION : TOVRML\n";
	return vrn(Transform,
	 	rotation => '1 0.1 0 1.1',
		translation => '1.5 0 0.5',
		children => [
		vrn(Shape,
			geometry => vrn(Text,
					string => $this->{TText},
					fontStyle =>     vrn(FontStyle,
							    'family' => "\"SANS\"",
							   size => '0.075',
							   spacing => '1.33',
							   justify => '["BEGIN","MIDDLE"]'
							 ),
			),
			appearance => vrn(Appearance,
				material => vrn(Material,
					   diffuseColor => '0.9 0.9 0.9',
					   ambientIntensity => '0.1'
				)
			)
		),
		vrn(Viewpoint,
			position => '0 0 3',
			description => "\"Description\""
		)
		]
	);
}

sub PDL::Graphics::VRML::vrmltext {
  my ($this,$text,$coords) = @_;
  $this->uses('TriDGraphText');
  return vrn('TriDGraphText',
	     'text' => "\"$text\"",
	     'position' => vrml3v($coords));
}

sub PDL::Graphics::TriD::Material::tovrml {
  my $this = shift;
  my $ambi = (pdl(@{$this->{Ambient}})**2)->sum /
    (pdl(@{$this->{Diffuse}})**2)->sum;
  $ambi = sqrt($ambi);
  new PDL::Graphics::VRMLNode('Material',
			'diffuseColor' => vrml3v($this->{Diffuse}),
			'emissiveColor' => vrml3v($this->{Emissive}),
			'shininess' => $this->{Shine},
			'ambientIntensity' => $ambi,
			'specularColor' => vrml3v($this->{Specular}),
		     );
}

sub PDL::Graphics::TriD::Scale::tovrml {my ($this) = @_;
	print "Scale ",(join ',',@{$this->{Args}}),"\n";
	new PDL::Graphics::VRMLNode('Transform',
		   'scale',vrml3v(@{$this->{Args}}));
}


sub PDL::Graphics::TriD::Translation::tovrml {
  my ($this) = @_;
  new PDL::Graphics::VRMLNode('Transform',
		   'translation',vrml3v(@{$this->{Args}}));
}

# XXXXX this has to be fixed -> wrap in one transform + children
sub PDL::Graphics::TriD::Transformation::tovrml {
	my($this) = @_;
	my @nodes = map {$_->tovrml()} @{$this->{Transforms}};
	push @nodes,$this->SUPER::tovrml();
}


sub PDL::Graphics::TriD::Quaternion::tovrml {my($this) = @_;
	if(abs($this->[0]) == 1) { return ; }
	if(abs($this->[0]) >= 1) { 
		# die "Unnormalized Quaternion!\n"; 
		$this->normalize_this();
	}
	new PDL::Graphics::VRMLNode('Transform',
		   'rotation',vrml3v(@{$this}[1..3])." $this->[0]");
}


sub PDL::Graphics::TriD::GObject::tovrml {
	return $_[0]->vdraw($_[0]->{Points});
}

sub PDL::Graphics::TriD::GObject::tovrml_graph {
	return $_[0]->vdraw($_[2]);
}

sub PDL::Graphics::TriD::Points::vdraw {
	my($this,$points) = @_;
	new PDL::Graphics::VRMLNode('Shape',
			 'geometry' =>
			 new PDL::Graphics::VRMLPdlNode($points,$this->{Colors},
					     {Title => 'PointSet',
					     DefColors => $this->defcols}));
}

sub PDL::Graphics::TriD::Lines::vdraw {
	my($this,$points) = @_;
	new PDL::Graphics::VRMLNode('Shape',
			 'geometry' =>
			 new PDL::Graphics::VRMLPdlNode($points,$this->{Colors},
					     {Title => 'IndexedLineSet',
					      DefColors => $this->defcols}));
}

sub PDL::Graphics::TriD::Lattice::vdraw {
	my($this,$points) = @_;
	new PDL::Graphics::VRMLNode('Shape',
			 'geometry' =>
			 new PDL::Graphics::VRMLPdlNode($points,$this->{Colors},
					     {Title => 'IndexedLineSet',
					      DefColors => $this->defcols,
					      IsLattice => 1}));
}

sub PDL::Graphics::TriD::SLattice::vdraw {
	my($this,$points) = @_;
	my $children = [vrn('Shape',
		'geometry' =>
		 new PDL::Graphics::VRMLPdlNode($points,$this->{Colors},
				      {Title => 'IndexedFaceSet',
				       DefColors => $this->defcols,
				       IsLattice => 1,
				      }))];
	push @$children, vrn('Shape',
		 'geometry' =>
		 new PDL::Graphics::VRMLPdlNode($points,$this->{Colors},
				      {Title => 'IndexedLineSet',
				       DefColors => 0,
				       Surface => 1,
				       Lines => 1,
				       IsLattice => 1,
				      }))
	  if $this->{Options}->{Lines};
	vrn('Group',
	    'children' => $children);
}

sub PDL::Graphics::TriD::SLattice_S::vdraw {
	my($this,$points) = @_;
	my $mat = $PDL::Graphics::TriD::current_window->{DefMaterial}->tovrml;
	my $children = [vrn('Shape',
		 'appearance' => vrn('Appearance',
				    'material' => $mat),
		'geometry' =>
		 new PDL::Graphics::VRMLPdlNode($points,$this->{Colors},
				      {Title => 'IndexedFaceSet',
				       DefColors => 1,
				       IsLattice => 1,
				       Smooth => $this->{Options}->{Smooth},
				      }))];
	push @$children, vrn('Shape',
		 'geometry' =>
		 new PDL::Graphics::VRMLPdlNode($points,$this->{Colors},
				      {Title => 'IndexedLineSet',
				       DefColors => 0,
				       Surface => 1,
				       Lines => 1,
				       IsLattice => 1,
				      }))
	  if $this->{Options}->{Lines};
	vrn('Group',
	    'children' => $children);
}

sub PDL::Graphics::TriD::Graph::tovrml {
	my($this) = @_;
	my @children = ();
	for(keys %{$this->{Axis}}) {
		if($_ eq "Default") {next}
		push @children, @{$this->{Axis}{$_}->tovrml_axis($this)};
	}
	for(keys %{$this->{Data}}) {
	    push @children,
	     $this->{Data}{$_}->tovrml_graph($this,$this->get_points($_));
	}
	return vrn('Group', 'children' => [@children]);
}


sub PDL::Graphics::TriD::EuclidAxes::tovrml_axis {
  my($this,$graph) = @_;
  my $vrml = $PDL::Graphics::VRML::cur;
  my $lset = vrn('Shape',
		 'geometry' => vrn('IndexedLineSet',
				   'coord', 
				   vrn('Coordinate',
				       'point',["0 0 0",
						"1 0 0",
						"0 1 0",
						"0 0 1"]),
				   'coordIndex',["0,1,-1",
						 "0,2,-1",
						 "0,3,-1"]));
  my ($vert,$indx,$j) = ([],[],0);
  my @children = ($lset);
  for $dim (0..2) {
    my @coords = (0,0,0);
    my @coords0 = (0,0,0);
    for(0..2) {
      if($dim != $_) { $coords[$_] -= 0.1 }
    }
    my $s = $this->{Scale}[$dim];
    my $ndiv = 3;
    my $radd = 1.0/$ndiv;
    my $nadd = ($s->[1]-$s->[0])/$ndiv;
    my $nc = $s->[0];
    for(0..$ndiv) {
      push @children, $vrml->vrmltext(sprintf("%.3f",$nc),[@coords]);
      push @$vert,(vrml3v([@coords0]),vrml3v([@coords]));
      push @$indx,$j++.", ".$j++.", -1";
      $coords[$dim] += $radd;
      $coords0[$dim] += $radd;
      $nc += $nadd;
    }
    $coords0[$dim] = 1.1;
    push @children, $vrml->vrmltext($this->{Names}[$dim],[@coords0]);
  }
  push @children, vrn('Shape',
		      'geometry' => vrn('IndexedLineSet',
					'coord' =>
				          vrn('Coordinate',
					      'point' => $vert),
				        'coordIndex' => $indx));
  return [@children];
}

sub PDL::Graphics::TriD::SimpleController::tovrml {
  # World origin is disregarded XXXXXXX
  my $this = shift;
  my $inv = new PDL::Graphics::TriD::Quaternion(@{$this->{WRotation}});
  $inv->invert_rotation_this;
  my $pos = $inv->rotate([0,0,1]);
#  print "SC: POS0:",(join ',',@$pos),"\n";
  for (@$pos) { $_ *=  $this->{CDistance}}
#  print "SC: POS:",(join ',',@$pos),"\n";
# ASSUME CRotation 0 for now
  return vrn('Viewpoint',
	     'position' => vrml3v($pos),
#	     'orientation' => vrml3v(@{$this->{CRotation}}[1..3]).
#	                " $this->{CRotation}->[0]",
	     'orientation' => vrml3v([@{$inv}[1..3]])." ".
	     		-atan2(sqrt(1-$this->{WRotation}[0]**2),
				$this->{WRotation}[0]),
	     'description' => "\"Home\"");
}


package PDL::Graphics::TriD::VRML;
$PDL::Graphics::VRML::cur = undef;
$PDL::Graphics::TriD::create_window_sub = sub {
	return new PDL::Graphics::TriD::VRML::Window;
};


package PDL::Graphics::TriD::VRMLObject;
@ISA = qw/PDL::Graphics::TriD::Object/;

sub new {
	my($type,$node) = @_;
	bless {Node => $node}, $type;
}

sub tovrml {
	return $_[0]->{Node};
}

package PDL::Graphics::TriD::Object;

sub vrml_update {
  my ($this) = @_;
  $this->{VRML} = new PDL::Graphics::VRMLNode('Transform',
				   'translation' => "-1 -1 -1",
				   'scale' => "2 2 2");
  $this->{ValidList} = 1;
}

sub tovrml {
	my($this) = @_;
	if (!$this->{ValidList}) {
	  $this->vrml_update();
	}
	$this->{VRML}->add('children',
			   [map {$_->tovrml()} @{$this->{Objects}}]);
}

package PDL::Graphics::TriD::VRML::Window;
use PDL::Graphics::TriD::Control3D;
PDL::Graphics::VRMLNode->import();
PDL::Graphics::VRMLProto->import();

@ISA = qw/PDL::Graphics::TriD::Window/;
use strict;

sub new {
  my($type) = @_;
  my $this = bless {}, $type;
  require PDL::Version if not defined $PDL::Version::VERSION;
  $this->{VRMLTop} = new PDL::Graphics::VRML("\"PDL::Graphics::TriD::VRML Scene\"",
				  ["\"generated by the PDL::Graphics::TriD module\"",
				   "\"version $PDL::Version::VERSION\""]);
  my $fontstyle = new PDL::Graphics::VRMLNode('FontStyle',
				    'size' => 0.04,
				    'family' => "\"SANS\"",
				    'justify' => "\"MIDDLE\"");
  $PDL::Graphics::TriD::VRML::fontstyle = $fontstyle;
  $this->{VRMLTop}->add_proto(PDL::Graphics::TriD::SimpleController->new->tovrml);
  $PDL::Graphics::VRML::cur = $this->{VRMLTop};
  $this->{VRMLTop}->register_proto(
	    vrp('TriDGraphText',
		[fv3f('position',"0 0 0"),
		 fmstr('text')],
		vrn('Transform',
		    'translation' => "IS position",
		    'children' =>
		      [vrn('Billboard',
			  'axisOfRotation' => '0 0 0',
			  'children' =>
			    [vrn('Shape',
			   'geometry' =>
			       vrn('Text',
				   'string' => "IS text",
				   'fontStyle' => $fontstyle))])])));
  return $this;
}

sub set_material {
  $_[0]->{DefMaterial} = $_[1];
}

sub clear_viewports{
  my $this = shift;
  # XXX Hmh, not much to do under VRML ?
}

sub display {
  my $this = shift;
  $this->tovrml;
  if ($this->{Transformer}) {
    $this->{VRMLTop}->addview($this->{Transformer}->tovrml)
  }
  $this->{VRMLTop}->ensure_protos();
  $this->{VRMLTop}->set_vrml($this->{VRML});
  my $tmpname = "/tmp/tridvrml_$$.wrl";
  if($_[0] eq 'file') {
	$tmpname = $_[1];
  }
  $this->{VRMLTop}->print($tmpname);
  SWITCH: {
      last SWITCH unless $#_ > -1;
      system('netscape','-remote',"openURL(file:$tmpname#Home)"), last SWITCH
	if $_[0] eq 'netscape';
      last SWITCH if $_[0] eq 'file';
  }
}

sub twiddle {
  my $this = shift;
  $this->display();
  # should probably wait for input of character 'q' ?
}

1;
