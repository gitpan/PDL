# This file provides a class that parses the Code -member
# of the PDL::PP code.
#
# This is what makes the nice loops go around etc.

package PDL::PP::Code;
use Carp;

sub get_pdls {my($this) = @_; return $this->{ParNames};}

# Do the appropriate substitutions in the code.
sub new { my($type,$code,$parnames,$parobjs,$indobjs,$generictypes,
	    $extrageneric,$havethreading) = @_;
	my($this) = bless {
		IndObjs => $indobjs,
		ParNames => $parnames,
		ParObjs => $parobjs,
	},$type;
	$_ = "{$code}";
# First, separate the code into an array of C fragments (strings),
# variable references (strings starting with $) and
# loops (array references, 1. item = variable.
	my $coderef = new PDL::PP::Block;
	my @stack = ($coderef);
	my $control;
	my $threadloops = 0;
	while($_) {
# Parse next statement
		s/^(.*?) # First, some noise is allowed. This may be bad.
		   ( \$[a-zA-Z_]+\([^)]*\)   # $a(...): access
		    |\bloop\([^)]+\)\s*%{   # loop(..) %{
		    |\btypes\([^)]+\)\s*%{  # types(..) %{
		    |\bthreadloop\s*%{        # threadloop %{
		    |%}                     # %}
		    |$)//xs
			or confess("Invalid program $_");
		$control = $2;
# Store the user code.
# Some day we shall parse everything.
		push @{$stack[-1]},$1;
# Then, our control.
		if($control) {
			if($control =~ /^loop\(([^)]+)\)\s*%{/) {
				my $ob = new PDL::PP::Loop([split ',',$1]);
				push @{$stack[-1]},$ob;
				push @stack,$ob;
			} elsif($control =~ /^types\(([^)]+)\)\s*%{/) {
				my $ob = new PDL::PP::Types($1);
				push @{$stack[-1]},$ob;
				push @stack,$ob;
			} elsif($control =~ /^threadloop\s*%{/) {
				my $ob = new PDL::PP::ThreadLoop();
				push @{$stack[-1]},$ob;
				push @stack,$ob;
				$threadloops ++;
			} elsif($control =~ /^\$[a-zA-Z_]+\([^)]*\)/) {
				push @{$stack[-1]},new PDL::PP::Access($control,$this);
			} elsif($control =~ /^%}/) {
				pop @stack;
			} else {
				confess("Invalid control: $control\n");
			}
		} else {
			print("No \$2!\n");
		}
	}
# Now, if there is no explicit threadlooping in the code,
# enclose everything into it.
	if(!$threadloops && $havethreading) {
		my $nc = $coderef;
		$coderef = new PDL::PP::ThreadLoop();
		push @{$coderef},$nc;
	}
# Enclose it all in a genericloop.
	{
# XXX Make genericloop understand denied pointers;...
		my $nc = $coderef;
		$coderef = new PDL::PP::GenericLoop($generictypes,"",
			[grep {!$extrageneric->{$_}} @$parnames],'$PRIV(__datatype)');
		push @{$coderef},$nc;
	}
# Do we have extra generic loops?
# If we do, first reverse the hash:
	my %glh;
	for(keys %$extrageneric) {
		push @{$glh{$extrageneric->{$_}}},$_;
	}
	my $no = 0;
	for(keys %glh) {
		my $nc = $coderef;
		$coderef = new PDL::PP::GenericLoop($generictypes,$no++,
							$glh{$_},$_);
		push @$coderef,$nc;
	}
# Then, in this form, put it together what we want the code to actually do.
	$this->{Code} = $coderef->get_str($this,[]);
	$this->{Code};
}

# This sub determines the index name for this index. 
# For example, a(x,y) and x0 becomes [x,x0]
sub make_loopind { my($this,$ind) = @_;
	my $orig = $ind;
	while(!$this->{IndObjs}{$ind}) {
		if(!((chop $ind) =~ /[0-9]/)) {
			confess("Index not found for $_ ($ind)!\n");
		}
		}
	return [$ind,$orig];
}


#####################################################################
#
# Encapsulate the parsing code objects
# 
# All objects have two methods: 
# 	new - constructor
#	get_str - get the string to be put into the xsub.

###########################
# 
# Encapsulate a block

package PDL::PP::Block;

sub new { my($type) = @_; bless [],$type; }

sub myoffs { return 0; }
sub myprelude {}
sub myitem {return "";}
sub mypostlude {}
sub get_str {my ($this,$parent,$context) = @_; 
   my $str = $this->myprelude($parent,$context);
   my $it; my $nth=0;
   MYLOOP: while(1) {
    $it = $this->myitem($parent,$nth);
    if($nth && !$it) {last MYLOOP}
    $str .= $it;
    $str .= (join '',map {ref $_ ? $_->get_str($parent,$context) : $_} 
	@{$this}[$this->myoffs()..$#{$this}]);
    $nth ++;
   }
   $str .= $this->mypostlude($parent,$context);
   $str;
}

###########################
# 
# Encapsulate a loop

package PDL::PP::Loop;
@PDL::PP::Loop::ISA = PDL::PP::Block;

sub new { my($type,$args) = @_;
	bless [$args],$type;
}

sub myoffs { return 1; }
sub myprelude { my($this,$parent,$context) = @_;
	my $text = ""; my $i;
	push @$context, map {
		$i = $parent->make_loopind($_);
		$text .= "{/* Open $_ */ long $_; 
			for($_=0; $_<\$PRIV(__$i->[0]_size); $_++) {";
		$i;
	} @{$this->[0]};
	return $text;
}
sub mypostlude { my($this,$parent,$context) = @_;
	splice @$context, - ($#{$this->[0]}+1);
	return join '',map {"}} /* Close $_ */"} @{$this->[0]};
}

###########################
# 
# Encapsulate a generic type loop

package PDL::PP::GenericLoop;
@PDL::PP::GenericLoop::ISA = PDL::PP::Block;

# Types: BSULFD, 
sub new { my($type,$types,$name,$varnames,$whattype) = @_;
	bless [(PDL::PP::get_generictyperecs($types)),$name,$varnames,
		$whattype],$type;
}

sub myoffs {4}


sub myprelude { my($this,$parent,$context) = @_;
	"/* Start generic loop */\n".
	(join '',map{
		"#undef THISIS$this->[1]_$_\n#define THISIS$this->[1]_$_(a)\n"
	}(B,S,U,L,F,D) ).
	"\tswitch($this->[3]) { case -42: /* Warning eater */ {1;\n";
}

sub myitem { my($this,$parent,$nth) = @_;
	my $item = $this->[0]->[$nth];
	if(!$item) {return "";}
	"\t} break; case $item->[0]: {\n".
	(join '',map {
		"#undef THISIS$this->[1]_$_\n#define THISIS$this->[1]_$_(a)\n";
	} (B,S,U,L,F,D)).
	"#undef THISIS$this->[1]_$item->[3]\n#define THISIS$this->[1]_$item->[3](a) a\n".
	(join '',map{
		$parent->{ParObjs}{$_}->get_xsdatapdecl($item->[1]);
	} (@{$this->[2]})) ;
}

sub mypostlude { my($this,$parent,$context) = @_;
	"\tbreak;}
	default:croak(\"PP INTERNAL ERROR! PLEASE MAKE A BUG REPORT\\n\");}\n";
}


###########################
# 
# Encapsulate a threadloop. 
# There are several different 

package PDL::PP::ThreadLoop;
sub new {
	return PDL::PP::ComplexThreadLoop->new(@_);
}

package PDL::PP::SimpleThreadLoop;
use Carp;
@PDL::PP::SimpleThreadLoop::ISA = PDL::PP::Block;

sub new { my($type) = @_; bless [],$type; }
sub myoffs { return 0; }
sub myprelude {my($this,$parent,$context) = @_;
 my $no;
 my ($ord,$pdls) = $parent->get_pdls();
'	/* THREADLOOPBEGIN */
 PDL->startthreadloop(&($PRIV(__thread)));
   do { 
 '.(join '',map {"${_}_datap += \$PRIV(__thread).offs[".(0+$no++)."];\n"}
 		@$ord).'
';
}

sub mypostlude {my($this,$parent,$context) = @_;
 my $no;
 my ($ord,$pdls) = $parent->get_pdls();
'	/* THREADLOOPEND */
 '.(join '',map {"${_}_datap -= \$PRIV(__thread).offs[".(0+$no++)."];\n"}
 		@$ord).'
	} while(PDL->iterthreadloop(&$PRIV(__thread),0));
 '
}

####
#
# This relies on PP.pm making sure that initthreadloop always sets
# up the two first dimensions even when they are not necessary.
#
package PDL::PP::ComplexThreadLoop;
use Carp;
@PDL::PP::ComplexThreadLoop::ISA = PDL::PP::Block;


sub new { my($type) = @_; bless [],$type; }
sub myoffs { return 0; }
sub myprelude {my($this,$parent,$context) = @_;
 my $no;
 my ($ord,$pdls) = $parent->get_pdls();
'	/* THREADLOOPBEGIN */
 PDL->startthreadloop(&($PRIV(__thread)));
   do { int __tind1=0,__tind2=0;  int __tnpdls = $PRIV(__thread).npdls;
 '.(join '',map {"${_}_datap += \$PRIV(__thread).offs[".(0+$no++)."];\n"}
 		@$ord).'
	for(__tind2=0; __tind2<$PRIV(__thread.dims[1]); __tind2++) {
	 for(__tind1=0; __tind1<$PRIV(__thread.dims[0]); __tind1++) {
	  /* This is the tightest threadloop. Make sure inside is optimal. */
';
}

# Should possibly fold out thread.dims[0] and [1].
sub mypostlude {my($this,$parent,$context) = @_;
 my $no; my $no0; my $no1; my $no2; my $no3; my $no4; my $no5;
 my ($ord,$pdls) = $parent->get_pdls();
'	/* THREADLOOPEND */
	 '.(join '',map {"${_}_datap += \$PRIV(__thread).incs[".(0+$no0++)."];\n"}
 		@$ord).'
	 } '
	 .(join '',map {"${_}_datap += \$PRIV(__thread).incs[__tnpdls+".(0+$no1++)."]
	     			     - \$PRIV(__thread).incs[".(0+$no2++)."] *
				       \$PRIV(__thread).dims[0];\n"}
 		@$ord).'
	} '.
     (join '',map {"${_}_datap -= \$PRIV(__thread).incs[__tnpdls+".(0+$no3++)."] *
     				  \$PRIV(__thread).dims[1];"}
 		@$ord).'
 '.(join '',map {"${_}_datap -= \$PRIV(__thread).offs[".(0+$no++)."];\n"}
 		@$ord).'
	} while(PDL->iterthreadloop(&$PRIV(__thread),2));
 '
}



###########################
# 
# Encapsulate a types() switch

package PDL::PP::Types;
use Carp;
@PDL::PP::Types::ISA = PDL::PP::Block;

sub new { my($type,$ts) = @_; 
	$ts =~ /[BSULFD]+/ or confess "Invalid type access with '$ts'!";
	bless [$ts],$type; }
sub myoffs { return 1; }
sub myprelude {my($this,$parent,$context) = @_;
	"\n#if ". (join '||',map {"(THISIS_$_(1)+0)"} split '',$this->[0])."\n";
}

sub mypostlude {my($this,$parent,$context) = @_;
	"\n#endif\n"
}


###########################
# 
# Encapsulate an access

package PDL::PP::Access;
use Carp;

sub new { my($type,$str,$parent) = @_;
	$str =~ /^\$([a-zA-Z_]+)\(([^)]*)\)/ or
		confess ("Access wrong: $access\n");
	my($pdl,$inds) = ($1,$2);
	if($pdl =~ /^T/) {new PDL::PP::MacroAccess($pdl,$inds);} 
	elsif($pdl =~ /^P$/) {new PDL::PP::PointerAccess($pdl,$inds);}
	elsif($pdl =~ /^PP$/) {new PDL::PP::PhysPointerAccess($pdl,$inds);}
	elsif(!defined $parent->{ParObjs}{$pdl}) {new PDL::PP::OtherAccess($pdl,$inds);}
	else {
		bless [$pdl,$inds],$type;
	}
}

sub get_str { my($this,$parent,$context) = @_;
#	print "AC: $this->[0]\n";
	$parent->{ParObjs}{$this->[0]}->do_access($this->[1],$context)
	 if defined($parent->{ParObjs}{$this->[0]});
}

###########################
#
# Just some other substituted thing.

package PDL::PP::OtherAccess;
sub new { my($type,$pdl,$inds) = @_; bless [$pdl,$inds],$type; }
sub get_str {my($this) = @_;return "\$$this->[0]($this->[1])"}


###########################
# 
# Encapsulate a Pointeraccess

package PDL::PP::PointerAccess;
use Carp;

sub new { my($type,$pdl,$inds) = @_; bless [$inds],$type; }

sub get_str {my($this,$parent,$context) = @_;
	$parent->{ParObjs}{$this->[0]}->do_pointeraccess()
	 if defined($parent->{ParObjs}{$this->[0]});
}


###########################
# 
# Encapsulate a PhysPointeraccess

package PDL::PP::PhysPointerAccess;
use Carp;

sub new { my($type,$pdl,$inds) = @_; bless [$inds],$type; }

sub get_str {my($this,$parent,$context) = @_;
	$parent->{ParObjs}{$this->[0]}->do_physpointeraccess()
	 if defined($parent->{ParObjs}{$this->[0]});
}

###########################
# 
# Encapsulate a macroaccess

package PDL::PP::MacroAccess;
use Carp;

sub new { my($type,$pdl,$inds) = @_; bless [$pdl,$inds],$type; }

sub get_str {my($this,$parent,$context) = @_;
	my ($pdl,$inds) = @{$this};
	$pdl =~ /T([BSULFD]+)/ or confess("Macroaccess wrong: $pdl\n");
	my @lst = split ',',$inds;
	my @ilst = split '',$1;
	if($#lst != $#ilst) {confess("Macroaccess: different nos of args $pdl $inds\n");}
	return join ' ',map {
		"THISIS_$ilst[$_]($lst[$_])"
	} (0..$#lst) ;
}


########################
#
# Type coercion
#
# Now, if TYPES:F given and double arguments, will coerce.

package PDL::PP::TypeConv;

sub print_xscoerce { my($this) = @_;
	$this->printxs("\t__priv->datatype=PDL_B;\n");
# First, go through all the types, selecting the most general.
	for(@{$this->{PdlOrder}}) {
		$this->printxs($this->{Pdls}{$_}->get_xsdatatypetest());
	}
# See which types we are allowed to use.
	$this->printxs("\tif(0) {}\n");
	for(@{$this->get_generictypes()}) {
		$this->printxs("\telse if(__priv->datatype <= $_->[2]) __priv->datatype = $_->[2];\n");
	} 
	$this->{Types} =~ /F/ and (
		$this->printxs("\telse if(__priv->datatype == PDL_D) {__priv->datatype = PDL_F; /* Cast double to float */}\n"));
	$this->printxs("\telse {croak(\"Too high type %d given!\\n\",__priv->datatype);}");
# Then, coerce everything to this type.
	for(@{$this->{PdlOrder}}) {
		$this->printxs($this->{Pdls}{$_}->get_xscoerce());
	}
}
# XXX Should use PDL::Core::Dev;

# STATIC!
sub PDL::PP::get_generictyperecs { my($types) = @_;
	my $foo;
	return [map {$foo = $_;
		( grep {/$foo->[0]/} (@$types) ) ? 
		  [PDL_.($_->[0]eq"U"?"US":$_->[0]),$_->[1],$_->[2],$_->[0]] 
		  : ()
	}
	       ([B,"PDL_Byte",$PDL_B],
		[S,"PDL_Short",$PDL_S],
		[U,"PDL_Ushort",$PDL_US],
		[L,"PDL_Long",$PDL_L],
		[F,"PDL_Float",$PDL_F],
		[D,"PDL_Double",$PDL_D])];
}

sub xxx_get_generictypes { my($this) = @_;
	return [map {
		$this->{Types} =~ /$_->[0]/ ? [PDL_.($_->[0]eq"U"?"US":$_->[0]),$_->[1],$_->[2],$_->[0]] : ()
	}
	       ([B,"PDL_Byte",$PDL_B],
		[S,"PDL_Short",$PDL_S],
		[U,"PDL_Ushort",$PDL_US],
		[L,"PDL_Long",$PDL_L],
		[F,"PDL_Float",$PDL_F],
		[D,"PDL_Double",$PDL_D])];
}

