
# Core routines for PDL module

package PDL::Core;
use PDL::Types;

# Functions exportable in this part of the module

@EXPORT_OK = qw( howbig nelem dims threadids
	      pdl topdl null byte short ushort long float double
	      convert log10 inplace zeroes ones list
	      listindices set at flows
	      callext convolve hist stats reshape );

@EXPORT_STATIC = qw( pdl topdl zeroes ones sequence );

use DynaLoader; use Carp;  
@ISA    = qw( PDL::Exporter DynaLoader ); 

bootstrap PDL::Core;

# Important variables (place in PDL namespace)

$PDL::verbose      =	       # Eat "used only once" warning
$PDL::verbose      = 0;        # Whether or not functions waffle
$PDL::name         = "PDL";    # what to call PDL objects
$PDL::use_commas   = 0;        # Whether to insert commas when printing arrays
$PDL::floatformat  = "%7g";    # Default print format for long numbers 
$PDL::doubleformat = "%10.8g"; 

*PDL::Core::null = \&PDL::null;

####################### Overloaded operators #######################

{ package PDL;

BEGIN {
@PDL::biops1  = qw( + * - / );
@PDL::biops2  = qw( > < <= >= == != );
@PDL::biops3  = qw( << >> | & ^ );

@PDL::ufuncs1 = qw( sqrt sin cos abs );
@PDL::ufuncs2 = qw( log exp ! ~ NOTHING );
@PDL::bifuncs = ("pow",["pow","**"],"atan2",["MODULO","%"],["SPACESHIP","<=>"]);
};

   use overload (
     (map {my $op = $_;
     	    ($op => sub {my $foo = PDL::null(); # print "OP: $op\n";
     		       PDL::Ops::my_biop1(&PDL::Core::rswap,$foo,$op); $foo;},
	    "$op=" => sub {PDL::Ops::my_biop1(&PDL::Core::rswapass,$op); 
	    	          return $_[0];})} @PDL::biops1),
     (map {my $op = $_;
     	    ($op => sub {my $foo = PDL::null(); 
     		       PDL::Ops::my_biop2(&PDL::Core::rswap,$foo,$op); $foo;})} 
		       			  @PDL::biops2),
     (map {my $op = $_;
     	    ($op => sub {my $foo = PDL::null(); 
     		       PDL::Ops::my_biop3(&PDL::Core::rswap,$foo,$op); $foo;},
	    "$op=" => sub {PDL::Ops::my_biop3(&PDL::Core::rswapass,$op); 
	    	          return $_[0];})} @PDL::biops3),

     (map {my $op = $_;
     	    ($op => sub {my $foo = PDL::Core::new_or_inplace($_[0]);
     		       PDL::Ops::my_ufunc1($_[0],$foo,$op); $foo;})} @PDL::ufuncs1),
     (map {my $op = $_;
     	    ($op => sub {my $foo = PDL::Core::new_or_inplace($_[0]);
     		       PDL::Ops::my_ufunc2($_[0],$foo,$op); $foo;})} @PDL::ufuncs2),

     (map {my $op = (ref $_ ? $_->[0] : $_); 
     	   my $opname = (ref $_ ? $_->[1] : $_);
    ($opname => sub {my $foo = PDL::null();
		PDL::Ops::my_bifunc1(&PDL::Core::rswap,$foo,$op); $foo;})} 
		   @PDL::bifuncs),

#     "="      =>  sub {shift->pdl_hard_copy}, # Copy 
     "="      =>  sub {$_[0]}, # Don't copy 

     "**="    => sub {my @args = (&PDL::Core::rswap);
     			PDL::Ops::my_bifunc1(@args,$args[0],"pow"); $args[0];},
     "%="    => sub {my @args = (&PDL::Core::rswap);
     			PDL::Ops::my_bifunc1(@args,$args[0],"MODULO"); $args[0];},

     ".="     => sub {my @args = reverse &PDL::Core::rswap;
     	PDL::Primitive::assgn(@args);
	return $args[1];},
     
     'x'      =>  sub{my $foo = PDL::null();
     		      PDL::Primitive::matmult(@_[0,1],$foo); $foo;},
     '~'      =>  \&PDL::Basic::transpose,               
     "\"\""   =>  \&PDL::Core::string
   );
}

sub rswap {
	if($_[2]) { return  @_[1,0] } else { return @_[0,1] }
}
sub rswapass {
	if($_[2]) { return  @_[1,0,1] } else { return @_[0,1,0] }
}

sub log10{ my $x = shift; my $y = log $x; $y /= log(10); return $y };

##################### Data type/conversion stuff ########################

# XXX Optimize!

sub dims {  # Return dimensions as @list
   my $pdl = topdl ($PDL::name, shift);
   my @dims = ();
   for(0..$pdl->getndims()-1) {push @dims,($pdl->getdim($_))}
   return @dims;
}

sub threadids {  # Return dimensions as @list
   my $pdl = topdl ($PDL::name, shift);
   my @dims = ();
   for(0..$pdl->getnthreadids()) {push @dims,($pdl->getthreadid($_))}
   return @dims;
}

################# Creation/copying functions #######################


# Create a new pdl variable, e.g.:
#
# $a = pdl 42;            # From scalar. This has 0 dims.
# $a = pdl 4,243;         # From list. Notice that this has 1 dim
# $a = pdl [1,2,3,4];     # From list
# $a = pdl ([1,2],[3,4]); # Ditto
# $a = pdl @x;            # Ditto
# $a = pdl $b;            # From another pdl (copy)

sub pdl { my $x = shift; return $x->new(@_) }

# Inheritable 'new' method for PDL objects

#sub null {  # Special token for PDL::PP
#   my $class = shift;
#   my $new = bless {}, $class;
#   $$new{Data}="";
#   $$new{Datatype}=0;
#   $new->setdims([0]);
#   return $new;
#}

sub PDL::doflow {
	my $this = shift;
	$this->set_dataflow_f(1);
	$this->set_dataflow_b(1);
}
  
sub flows {
 	my $this = shift;
         return ($this->fflows || $this->bflows);
}

sub PDL::new {         
   my $this = shift;
   return $this->copy if ref($this);
   my $new = PDL::null();
   $new->set_datatype($PDL_D);
   my $value = (scalar(@_)>1 ? [@_] : shift);  # ref thyself
   $value = 0 if !defined($value);
   if (ref(\$value) eq "SCALAR") { 
       $new->setdims([]);
       ${$new->get_dataref}     = pack( $pack[$new->get_datatype], $value ); 
       $new->upd_data();
   }
   elsif (ref($value) eq "ARRAY") { 
       $level = 0; @dims = (); # package vars
       my $str = rpack($value); 
       $new->setdims([reverse @dims]);
       ${$new->get_dataref()} = $str;
       $new->upd_data();
   }
   elsif (blessed($value)) { # Object 
       $new = $value->copy;
   }
   else {
       croak("Can not interpret argument $value of type ".ref($value) );
   }
   return $new;
}

# Inheritable copy method
#
# XXX Must be fixed
# Inplace is handled by the op currently.

sub PDL::copy { 
    my $value = shift;
    croak("Argument is an ".ref($value)." not an object") unless blessed($value);
    my $option  = shift;
    $option = "" if !defined $option;
    if ($value->is_inplace) {   # Copy protection
       $value->set_inplace(0);
       return $value;
    }
    my $new = $value->pdl_hard_copy();
    return $new;
}

sub PDL::unwind {
	my $value = shift;
	my $foo = PDL::null();
	$foo .= $value->unthread();
	return $foo;
}

sub PDL::dummy($$;$) {
   croak ("too high/low dimension in call to dummy, allowed min/max=0/"
 	 . $_[0]->getndims)
     if $_[1]>$_[0]->getndims || $_[1] < 0;
         $_[2] = 1 if ($#_ < 2);
         $_[0]->slice((','x$_[1])."*$_[2]");
}

sub PDL::thread {
	my $var = shift;
	$var->threadI(1,\@_);
}

sub PDL::diagonal {
	my $var = shift;
	$var->diagonalI(\@_);
}

sub PDL::thread1 {
	my $var = shift;
	$var->threadI(1,\@_);
}

sub PDL::thread2 {
	my $var = shift;
	$var->threadI(2,\@_);
}

sub PDL::thread3 {
	my $var = shift;
	$var->threadI(3,\@_);
}

sub PDL::physical_copy {
	(my $foo = PDL::null()) .= $_[0];
	return $foo;
}

sub dereference {
	my $ref = shift; while(ref $ref) {$ref = $$ref;}
	return $ref;
}

# Utility to determine if argument is blessed object

sub blessed { 
    my $ref = ref(shift);
    return $ref =~ /^(REF|SCALAR|ARRAY|HASH|CODE|GLOB||)$/ ? 0 : 1;
} 
       
# Convert numbers to PDL if not already

sub topdl {      
    return $_[1] if blessed($_[1]); # Fall through
    return $_[0]->new($_[1]) if ref(\$_[1]) eq "SCALAR";
    croak("Can not convert a ".ref($_[1])." to a ".$_[0]);
0;}

# Convert everything to PDL if not blessed

sub alltopdl {    
    return $_[1] if blessed($_[1]); # Fall through
    return $_[0]->new($_[1]);
0;}

# Flag pdl for in-place operations

sub inplace {
    my $pdl = topdl($PDL::name,shift); $$pdl{Inplace}=1; return $pdl;
}

# Copy if not inplace

sub new_or_inplace {
	my $pdl = shift;
	if($pdl->is_inplace) {
		$pdl->set_inplace(0); $pdl;
	} else {
		$pdl->copy();
	}
}

# Create zero filled array (function/inheritable constructor)

sub zeroes {
    my $class = shift; 
    my $nelems = 1; my @dims;
    my $type = ref($_[0]) eq 'PDL::Type' ? ${shift @_}[0]  : $PDL_D;

    for (@_) { 
       croak "Dimensions must be positive" if $_<=0;
       $nelems *= $_; push @dims, $_ 
    }
    my $pdl = PDL::null();
    $pdl->set_datatype($type);
    $pdl->setdims([@dims]);
    my $dref = $pdl->get_dataref();
    $$dref  = "\0"x($nelems*howbig($type));
    print "Dims: ",(join ',',@dims)," DLen: ",(length $$dref),"\n";
    $pdl->upd_data();
    return $pdl;
} 

# Create one-filled array

sub ones { 
  croak 'Usage: $a = ones($nx, $ny, $nz ...) or PDL->ones(...)' if $#_<1;
  my $x = zeroes(@_); return ++$x 
}

# Reshape PDL array

# Doesn't work.

#sub reshape {
#   croak 'Usage reshape($a, $nx, $ny, $nz...)' if $#_<1;
#   my $a  = topdl($PDL::name,shift); my @n = @_; my $n;
#   my $nelem = 1; for $n (@n) { croak "Dims must be > 0\n" unless $n>0; $nelem *= $n}
#   $nelem = ($nelem-nelem($a)) * howbig($$a{Datatype});
#   $$a{Dims} = [@_];
#   if ($nelem>=0) {
#      $$a{Data}.="\0"x$nelem;       # Zero extend
#   }else{
#      $$a{Data} = substr($$a{Data},0,length($$a{Data})+$nelem); # Chop
#   }
#   $a->flush;
#1;}

# type to type conversion functions (with automatic conversion to pdl vars)

for(
	["byte",'$PDL_B'],
	["short",'$PDL_S'],
	["ushort",'$PDL_US'],
	["long",'$PDL_L'],
	["float",'$PDL_F'],
	["double",'$PDL_D']
) {
	eval ("sub $_->[0] { ".
		'return bless ['.$_->[1].'], PDL::Type unless @_;
		 convert(alltopdl($PDL::name,shift),'.$_->[1].') 
		}');
}

{package PDL::Type;
 sub new {my($type,$val) = @_;
          bless [$val],$type}
}

##################### Printing ####################

$PDL::_STRINGIZING = 0;

sub string { 
    my($self,$format)=@_;
    if($PDL::_STRINGIZING) {
    	return "ALREADY_STRINGIZING_NO_LOOPS";
    }
    local $PDL::_STRINGIZING = 1;
    $self->make_physical();
    my $ndims = scalar(dims($self));
    if(length ${$self->get_dataref} > 10000) {
    	return "TOO LONG TO PRINT";
    }
    return "Null" if $ndims==1 && $self->getdim(0)==0; # Null token
    if ($ndims==0) {
       my @x = $self->at();
       return ($format ? sprintf($format, $x[0]) : "$x[0]");
    }
    local $sep  = $PDL::use_commas ? "," : " ";
    local $sep2 = $PDL::use_commas ? "," : "";
    if ($ndims==1) {
       return str1D($self,$format);
    }
    else{
       return strND($self,$format,0);
    }
}

############## Section/subsection functions ###################

# No threading, just the ordinary dims.
sub list{ # pdl -> @list
     croak 'Usage: list($pdl)' if $#_!=0;
     my $pdl = topdl($PDL::name,shift);
     list_c($pdl);
}

sub listindices{ # Return list of index values for 1D pdl
     croak 'Usage: list($pdl)' if $#_!=0;
     my $pdl = shift; 
     croak 'Not 1D' if scalar(dims($pdl)) != 1;
     return (0..nelem($pdl)-1);
}

sub set{    # Sets a particular single value 
    croak 'Usage: set($pdl, $x, $y,.., $value)' if $#_<2;
    my $self  = shift; my $value = pop @_;
    set_c ($self, [@_], $value);
    return $self;
}

sub at{     # Return value at ($x,$y,$z...)
    croak 'Usage: at($pdl, $x, $y, ...)' if $#_<0;
    my $self = shift;
    at_c ($self, [@_]);
}

####################### Call external #########################

# Load a shareable image and call a symbol and pass PDL parameters
# to it

sub callext{
    die "Usage: callext(\$file,\$symbol, \@pdl_args)" if scalar(@_)<2;
    my($file,$symbol, @pdl_args) = @_;

    $libref = DynaLoader::dl_load_file($file);
    $err    = DynaLoader::dl_error(); croak $err unless $err eq "";
    $symref = DynaLoader::dl_find_symbol($libref, $symbol);
    $err    = DynaLoader::dl_error(); croak $err unless $err eq "";

    callext_c($symref, @pdl_args);
1;}


###################### Misc internal routines ####################


# Recursively pack an N-D array ref in format [[1,1,2],[2,2,3],[2,2,2]] etc
# package vars $level and @dims must be initialised first.

sub rpack {             
            
    my $a = shift;  my ($ret,$type);

    $ret = "";
    if (ref($a) eq "ARRAY") {

       if (defined($dims[$level])) {
           croak 'Array is not rectangular' unless $dims[$level] == scalar(@$a);
       }else{
          $dims[$level] = scalar(@$a);
       }
       $level++;

       $type = ref($$a[0]);
       for(@$a) { 
          croak 'Array is not rectangular' unless $type eq ref($_); # Equal types
          $ret .= rpack($_);
       }
       $level--;

    }elsif (ref(\$a) eq "SCALAR") { # Note $PDL_D assumed

      $ret = pack("d*",$_);
 
    }else{
        croak "Don't know how to make a PDL object from passed argument";
    }
    return $ret;
}

sub rcopyitem{        # Return a deep copy of an item - recursively
    my $x = shift; 
    my ($y, $key, $value);
    if (ref(\$x) eq "SCALAR") {
       return $x;
    }elsif (ref($x) eq "SCALAR") {
       $y = $$x; return \$y;
    }elsif (ref($x) eq "ARRAY") {
       $y = [];
       for (@$x) {
           push @$y, rcopyitem($_);
       }
       return $y;
    }elsif (ref($x) eq "HASH") {
       $y={};
       while (($key,$value) = each %$x) {
          $$y{$key} = rcopyitem($value);
       }
       return $y;
    }elsif (blessed($x)) { 
       return $x->copy;
    }else{
       croak ('Deep copy of object failed - unknown component with type '.ref($x));
    }
0;}

# N-D array stringifier

sub strND {
    my($self,$format,$level)=@_;
    $self->make_physical();
    my @dims = $self->dims;
#    print "STRND, $#dims\n";
    
    if ($#dims==1) { # Return 2D string
       return str2D($self,$format,$level);
    }
    else { # Return list of (N-1)D strings
       my $secbas = join '',map {":,"} @dims[0..$#dims-1];
       my $ret="\n"." "x$level ."["; my $j;       
       for ($j=0; $j<$dims[$#dims]; $j++) {
       	   my $sec = $secbas . "($j)";
#	   print "SLICE: $sec\n";

           $ret .= strND($self->slice($sec),$format, $level+1); 
	   chop $ret; $ret .= $sep2;
       }
       chop $ret if $PDL::use_commas;
       $ret .= "\n" ." "x$level ."]\n";
       return $ret;
    }
}
  

# String 1D array in nice format

sub str1D {
    my($self,$format)=@_;
    croak "Not 1D" if $self->getndims()!=1;
    my @x = $self->list();
    my ($ret,$dformat,$t);
    $ret = "[";
    $dformat = $PDL::floatformat  if $self->get_datatype() == $PDL_F;
    $dformat = $PDL::doubleformat if $self->get_datatype() == $PDL_D;
    for $t (@x) {
        if ($format) {
	  $t = sprintf $format,$t;
	}
	else{ # Default 
           if ($dformat && length($t)>7) { # Try smaller
             $t = sprintf $dformat,$t;
	   }
	}
       $ret .= $t.$sep;
    }
    chop $ret; $ret.="]";
    return $ret;
}

# String 2D array in nice uniform format

sub str2D{ 
    my($self,$format,$level)=@_;
#    print "STR2D:\n"; $self->printdims();
    my @dims = $self->dims();
    croak "Not 2D" if scalar(@dims)!=2;
    my @x = $self->list();
    my ($i, $f, $t, $len, $ret);

    if (!defined $format || $format eq "") { # Format not given? - 
                                             # find max length of default
       $len=0;
       for (@x) {$i = length($_); $len = $i>$len ? $i : $len };
       $format = "%".$len."s"; 
       
       if ($len>7) { # Too long? - perhaps try smaller format
          if ($self->get_datatype() == $PDL_F) {
	    $format = $PDL::floatformat  
	  } elsif ($self->get_datatype() == $PDL_D) {
	    $format = $PDL::doubleformat 
	  } else {
	     goto output; # Stick with default
	  }
       }
       else {
          goto output; # Default ok
       }
    } 

    # Find max length of strings in final format
    $len=0;
    for (@x) { 
       $i = length(sprintf $format,$_); $len = $i>$len ? $i : $len;
    }
       
    output:     # Generate output

    $ret = "\n" . " "x$level . "[\n";
    { my $level = $level+1;
      $ret .= " "x$level ."[";
      for ($i=0; $i<=$#x; $i++) { 
          $f = sprintf $format,$x[$i];
          $t = $len-length($f); $f = " "x$t .$f if $t>0;
          $ret .= $f;
	  if (($i+1)%$dims[0]) { 
	     $ret.=$sep;
          }
	  else{ # End of output line
	     $ret.="]";
	     if ($i==$#x) { # very last number
	        $ret.="\n";
	     }
	     else{
	        $ret.= $sep2."\n" . " "x$level ."[";
	     }
	  }
       }
    }
    $ret .= " "x$level."]\n";
    return $ret;
}

# Export routines with support for the 'OO' modifier and
# @EXPORT_STATIC list. Also exports all of @EXPORT_OK if no list
# specified (i.e. opposite default behaviour from builtin).

package PDL::Exporter;

use Exporter;


sub import {

   my $pkg = shift;
   my @exports = @_;
   my @revised_exports = ();
   local $^W=0;  # Supress redefining subroutines warning
   my ($e,$OO,$toeval);
   for $e (@exports) {
      $e eq "OO" ? $OO++ : push @revised_exports, $e;
   }
   @revised_exports = @{"${pkg}::EXPORT_OK"} if scalar(@revised_exports)==0;
   
   my $call = caller;

#   if ($OO) {
      Exporter::export( $pkg, $PDL::name, @revised_exports );
#   }
#   else{
      @static = (); $toeval="";
      @{"${pkg}::EXPORT_FAIL"} = @{"${pkg}::EXPORT_STATIC"}; # Call back handle
      Exporter::export( $pkg, $call, @revised_exports );

      # Redefine the @EXPORT_STATIC list

      for $e (@static) { 
         $toeval .= "sub ${call}::$e { ${pkg}::$e ( \$PDL::name, \@_ ) }; ";
      }
      eval $toeval;
#   }
}

sub export_fail {
   my $pkg = shift;
   @static = @_;    # Save static symbols list
   return ();       # Tell exporter still OK to export
}


if(0) {
package PDL;

sub TIEHASH {
	shift;
	my $p = PDL::null();
	bless $$p;
}

sub FETCH {
	my $p = shift; local $_ = shift;
}
}

;# Exit with OK status

1;
