=head1 NAME

PDL::Core - fundamental PDL functionality


=head1 DESCRIPTION

Methods and functions for type conversions, PDL creation,
type conversion, threading etc.

=head1 SYNOPSIS

use PDL::Core;             # Normal routines
use PDL::Core ':Internal'; # Hairy routines


=head1 FUNCTIONS

=cut

# Core routines for PDL module

package PDL::Core;
use PDL::Types;
use PDL::PP::Signature;

$PDL::Core::FOO_FOO_::VERSION = '1.56';

# Functions exportable in this part of the module

@EXPORT = qw( pdl null barf ); # Only stuff always exported!

@EXPORT_OK = qw( howbig threadids topdl nelem dims null byte short ushort 
   long float double convert log10 inplace zeroes ones list listindices 
   set at flows thread_define over reshape dog cat barf type diagonal
   dummy mslice);
  
%EXPORT_TAGS = (
   Func=>[qw/nelem dims null byte short ushort 
    long float double convert log10 inplace zeroes ones list listindices 
    set at flows thread_define over reshape pdl null dog cat barf type
    diagonal dummy mslice/], 
   Internal=>[qw/howbig threadids topdl/]
);

use PDL::Exporter;
use DynaLoader; 

@ISA    = qw( PDL::Exporter DynaLoader ); 

bootstrap PDL::Core;

# Important variables (place in PDL namespace)

$PDL::verbose      =	       # Eat "used only once" warning
$PDL::verbose      = 0;        # Whether or not functions waffle
$PDL::use_commas   = 0;        # Whether to insert commas when printing arrays
$PDL::floatformat  = "%7g";    # Default print format for long numbers 
$PDL::doubleformat = "%10.8g"; 

################ Exportable functions of the Core ######################

*howbig       = \&PDL::howbig;	  *log10	= \&PDL::log10;
*nelem        = \&PDL::nelem;	  *inplace	= \&PDL::inplace;
*dims	      = \&PDL::dims;	  *list 	= \&PDL::list;
*threadids    = \&PDL::threadids; *listindices  = \&PDL::listindices;
*null	      = \&PDL::null;	  *set  	= \&PDL::set;
*byte	      = \&PDL::byte;	  *at		= \&PDL::at;
*short        = \&PDL::short;	  *flows	= \&PDL::flows;
*ushort       = \&PDL::ushort;	   
*long	      = \&PDL::long;	  
*float        = \&PDL::float;	  *cutmask	 = \&PDL::cutmask;
*double       = \&PDL::double;	  *thread_define = \&PDL::thread_define;
*convert      = \&PDL::convert;   *over 	 = \&PDL::over;
*dog          = \&PDL::dog;       *cat 	         = \&PDL::cat;
*type         = \&PDL::type;
*diagonal     = \&PDL::diagonal;
*dummy        = \&PDL::dummy;
*mslice       = \&PDL::mslice;

sub barf;

=head2 pdl

=for ref

piddle constructor - creates new piddle from perl scalars/arrays

=for usage

   $a = pdl(SCALAR|ARRAY REFERENCE|ARRAY);

=for example

   $a = pdl [1..10];             # 1D array
   $a = pdl (1,2,3,4);           # Ditto
   $b = pdl [[1,2,3],[4,5,6]];   # 2D 3x2 array
   $b = pdl 42                   # 0-dimensional scalar
   $c = pdl $a;                  # Make a new copy

pdl() is a functional synonym for the 'new' constructor,
e.g.:

   $x = new PDL [1..10];

=cut

sub pdl {PDL->pdl(@_)}

=head2 null

=for ref

Returns a 'null' piddle.

=for usage

   $x = null;
   
null() has a special meaning to C<PDL::PP>. It is used to
flag a special kind of empty piddle, which can grow to
appropriate dimensions to store a result. (As opposed to
storing a result in an existing piddle).    

=for example

 perldl> sumover sequence(10,10), $ans=null;p $ans
 [45 145 245 345 445 545 645 745 845 945]

=head2 nelem

=for ref

Return the number of elements in a piddle

=for usage

 $n = nelem($piddle); $n = $piddle->nelem;  

=for example

 $mean = sum($data)/nelem($data); 

=head2 dims

=for ref

Return piddle dimensions a a perl list

=for usage

 @dims = $piddle->dims;  @dims = dims($piddle);

=for example

 perldl> p @tmp = dims zeroes 10,3,22
 10 3 22

=head2 PDL::getndims

=for ref

Returns the number of dimensions in a piddle

=for usage

   $ndims = $piddle->getndims;

=for example

  perldl> p zeroes(10,3,22)->getndims
  3


=head2 topdl

=for ref

alternate piddle constructor - ensures arg is a piddle

=for usage

   $a = topdl(SCALAR|ARRAY REFERENCE|ARRAY);
   
The difference between pdl() and topdl() is that the
latter will just 'fall through' if the argument is
already a piddle. It will return a reference and NOT
a new copy.

This is particulary useful if you are writing a function
which is doing some fiddling with internals and assumes
a piddle argument (e.g. for method calls). Using topdl()
will ensure nothing breaks if passed with '2'.

=for example

   $a = topdl 43;         # $a is piddle with value '43'
   $b = topdl $piddle;    # fall through
   $a = topdl (1,2,3,4);  # Convert 1D array
   
=head2 PDL::get_datatype

=for ref

Internal: Return the numeric value identifying the piddle datatype

=for usage

  $x = $piddle->get_datatype; 

Mainly used for internal routines. 

NOTE: get_datatype returns 'just a number' not any special
type  object. 


=head2 howbig

=for ref

Returns the size of a piddle datatype in bytes.

=for usage

 $size = howbig($piddle->get_datatype);
 
Mainly used for internal routines. 
 
NOTE: NOT a method! This is because get_datatype returns
'just a number' not any special object.

=for example

 perldl> p howbig(ushort([1..10])->get_datatype)
 2

=cut

sub topdl {PDL->topdl(@_)}


####################### Overloaded operators #######################

{ package PDL;
  use UNIVERSAL 'isa'; # need that later in info function

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
		      return $args[1]->info("%C (%A): %T %D %S %M")
			if !ref $args[0] && $args[0] eq '';
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

sub PDL::log10{ my $x = shift; my $y = log $x; $y /= log(10); return $y };

##################### Data type/conversion stuff ########################


=head2 dims

=for ref

Returns the dimensions of a piddle as a perl list

=for usage

  ($m,$n) = dims $piddle;

=cut

# XXX Optimize!

sub PDL::dims {  # Return dimensions as @list
   my $pdl = PDL->topdl (shift);
   my @dims = ();
   for(0..$pdl->getndims()-1) {push @dims,($pdl->getdim($_))}
   return @dims;
}

sub PDL::howbig {
	my $t = shift;
	if("PDL::Type" eq ref $t) {$t = $t->[0]}
	PDL::howbig_c($t);
}

=head2 threadids

=for ref

Returns the piddle thread IDs as a perl list

=for usage

  @ids = threadids $piddle;

=cut

sub PDL::threadids {  # Return dimensions as @list
   my $pdl = PDL->topdl (shift);
   my @dims = ();
   for(0..$pdl->getnthreadids()) {push @dims,($pdl->getthreadid($_))}
   return @dims;
}

################# Creation/copying functions #######################


sub PDL::pdl { my $x = shift; return $x->new(@_) }

=head2 doflow

=for ref

Turn on/off dataflow

=for usage

   $x->doflow;  doflow($x);

=cut

sub PDL::doflow {
	my $this = shift;
	$this->set_dataflow_f(1);
	$this->set_dataflow_b(1);
}
  
=head2 flows

=for ref

Whether or not a piddle is indulging in dataflow

=for usage

   something if $x->flows; $hmm = flows($x);

=cut

sub PDL::flows {
 	my $this = shift;
         return ($this->fflows || $this->bflows);
}

=head2 PDL::new

=for ref

new piddle constructor method 

=for usage

  $x = PDL->new(SCALAR|ARRAY|ARRAY REF); 

=for example

  $x = PDL->new(42);
  $y = new PDL [1..10];
  
  Constructs piddle from perl numbers and lists.	

=cut


sub PDL::new {         
   my $this = shift;
   return $this->copy if ref($this);
   my $type = ref($_[0]) eq 'PDL::Type' ? ${shift @_}[0]  : $PDL_D;
   my $new = $this->initialize();
   $new->set_datatype($type);
   my $value = (scalar(@_)>1 ? [@_] : shift);  # ref thyself
   $value = 0 if !defined($value);
   if (ref(\$value) eq "SCALAR") { 
       $new->setdims([]);
       ${$new->get_dataref}     = pack( $pack[$new->get_datatype], $value ); 
       $new->upd_data();
   }
   elsif (ref($value) eq "ARRAY") { 
       $level = 0; @dims = (); # package vars
       my $str = rpack($pack[$new->get_datatype], $value); 
       $new->setdims([reverse @dims]);
       ${$new->get_dataref()} = $str;
       $new->upd_data();
   }
   elsif (blessed($value)) { # Object 
       $new = $value->copy;
   }
   else {
       barf("Can not interpret argument $value of type ".ref($value) );
   }
   return $new;
}

sub PDL::initialize { bless &PDL::null(), (ref $_[0] ? ref $_[0]: $_[0]) }

=head2 PDL::copy

=for ref

Make a physical copy of a piddle

=for usage

   $new = $old->copy;


Since C<$new = $old> just makes a new reference, the
C<copy> method is provided to allow real independent
copies to be made.
  

=cut

# Inheritable copy method
#
# XXX Must be fixed
# Inplace is handled by the op currently.

sub PDL::copy { 
    my $value = shift;
    barf("Argument is an ".ref($value)." not an object") unless blessed($value);
    my $option  = shift;
    $option = "" if !defined $option;
    if ($value->is_inplace) {   # Copy protection
       $value->set_inplace(0);
       return $value;
    }
    # threadI(-1,[]) is just an identity vafftrans with threadId copying ;)
    my $new = $value->threadI(-1,[])->sever;
    return $new;
}

=head2 PDL::unwind

=for ref

Return a piddle which is the same as the argument except
that all threadids have been removed.

=for usage

 $y = $x->unwind;  

=cut

=head2 PDL::make_physical

=for ref

Make sure the data portion of a piddle can be accessed from XS code.

=for example

   $a->make_physical;
   $a->call_my_xs_method;

Ensures that a piddle gets its own allocated copy of data. This obviously
implies that there are certain piddles which do not have their own data.
These are so called I<virtual> piddles that make use of the I<vaffine>
optimisation (see L<pdlindexing>). They do not have their own copy of
data but instead store only access information to some (or all) of another
piddle's data.

Note: this function should not be used unless absolutely neccessary
since otherwise memory requirements might be severly increased. Instead
of writing your own XS code with the need to call make_physical you
might want to consider using the PDL preprocessor (see L<PDL::PP>)
which can be used to transparently access virtual piddles without the 
need to physicalise them (though there are exceptions).


=cut

sub PDL::unwind {
	my $value = shift;
	my $foo = PDL::null();
	$foo .= $value->unthread();
	return $foo;
}

=head2 dummy

=for ref

Insert a 'dummy dimension' of given length (defaults to 1)

No relation to the 'Dungeon Dimensions' in Discworld!

=for usage

 $y = $x->dummy($position[,$dimsize]);   

=for example

  perldl> p sequence(3)->dummy(0,3) 
  [
   [0 0 0]
   [1 1 1]
   [2 2 2]
  ]

=cut


sub PDL::dummy($$;$) {
   barf ("too high/low dimension in call to dummy, allowed min/max=0/"
 	 . $_[0]->getndims)
     if $_[1]>$_[0]->getndims || $_[1] < 0;
         $_[2] = 1 if ($#_ < 2);
         $_[0]->slice((','x$_[1])."*$_[2]");
}


=head2 thread_define

=for ref

define functions that support threading at the perl level

=for example

   thread_define 'tline(a(n);b(n))', over {
    line $_[0], $_[1]; # make line compliant with threading
   };


C<thread_define> provides some support for threading (see
L<pdlindexing>) at the perl level. It allows you to do things for
which you normally would have resorted to PDL::PP (see L<PDL::PP>);
however, it is most useful to wrap existing perl functions so that the
new routine supports PDL threading.

C<thread_define> is used to define new I<threading aware>
functions. Its first argument is a symbolic repesentation of the new
function to be defined. The string is composed of the name of the new
function followed by its signature (see L<pdlindexing> and L<PDL::PP>)
in parentheses. The second argument is a subroutine that will be
called with the slices of the actual runtime arguments as specified by
its signature. Correct dimension sizes and minimal number of
dimensions for all arguments will be checked (assuming the rules of
PDL threading, see L<pdlindexing>).

The actual work is done by the C<signature> class which parses the signature
string, does runtime dimension checks and the routine C<threadover> that
generates the loop over all appropriate slices of pdl arguments and creates
pdls as needed.

Similar to C<pp_def> and its C<OtherPars> option it is possible to
define the new function so that it accepts normal perl args as well as
piddles. You do this by using the C<NOtherPars> parameter in the
signature. The number of C<NOtherPars> specified will be passed
unaltered into the subroutine given as the second argument of
C<thread_define>. Let's illustrate this with an example:

   PDL::thread_define 'triangles(inda();indb();indc()), NOtherPars => 2',
    PDL::over {
      ${$_[3]} .= $_[4].join(',',map {$_->at} @_[0..2]).",-1,\n";
    };

This defines a function C<triangles> that takes 3 piddles as input
plus 2 arguments which are passed into the routine unaltered. This routine
is used to collect lists of indices into a perl scalar that is passed by
reference. Each line is preceded by a prefix passed as C<$_[4]>. Here is
typical usage:

   $txt = '';
   triangles(pdl(1,2,3),pdl(1),pdl(0),\$txt," "x10);
   print $txt;

resulting in the following output

          1,1,0,-1,
          2,1,0,-1,
          3,1,0,-1,

which is used in PDL::VRML to generate VRML output.

Currently, this is probably not much more than a POP (proof of principle)
but is hoped to be useful enough for some real life work.

Check L<PDL::PP> for the format of the signature. Currently, the
C<[t]> qualifier and all type qualifiers are ignored.

=cut

sub PDL::over (&) { $_[0] }
sub PDL::thread_define ($$) {
  my ($str,$sub) = @_;
  my $others = 0;
  if ($str =~ s/[,]*\s*NOtherPars\s*=>\s*([0-9]+)\s*[,]*//) {$others = $1}
  barf "invalid string $str" unless $str =~ /\s*([^(]+)\((.+)\)\s*$/x;
  my ($name,$sigstr) = ($1,$2);
  print "defining '$name' with signature '$sigstr' and $others extra args\n"
						  if $PDL::verbose;
  my $sig = new PDL::PP::Signature($sigstr);
  # TODO: $sig->dimcheck(@_) + proper creating generation
  my $def = '$sig->checkdims(@_);
	     PDL::threadover($others,@_,$sig->realdims,$sig->creating,$sub)';
  my $package = caller;
  local $^W = 0; # supress the 'not shared' warnings
  eval ("package $package; sub $name { $def }");
}

=head2 PDL::thread

=for ref

Use explicit threading over specified dimensions (see also L<PDL::Indexing>)

=for usage

   $b = $a->thread($dim,[$dim1,...])

=for example

  $a = zeroes 3,4,5;
  $b = $a->thread(2,0);

Same as C<PDL::thread1>, i.e. uses thread id 1.

=cut


sub PDL::thread {
	my $var = shift;
	$var->threadI(1,\@_);
}

=head2 diagonal

=for ref

Returns the multidimensional diagonal over the specified dimensions.

=for usage

   $d = $x->diagonal(dim1, dim2,...)

=for example

   perldl> $a = zeroes(3,3,3);
   perldl> ($b = $a->diagonal(0,1))++;
   perldl> p $a
   [
    [
     [1 0 0]
     [0 1 0]
     [0 0 1]
    ]
    [
     [1 0 0]
     [0 1 0]
     [0 0 1]
    ]
    [
     [1 0 0]
     [0 1 0]
     [0 0 1]
    ]
   ]

=cut

sub PDL::diagonal {
	my $var = shift;
	$var->diagonalI(\@_);
}

=head2 PDL::thread1

=for ref

Explicit threading over specified dims using thread id 1.

=for usage

   $xx = $x->thread1(3,1)

=for example

  Wibble

Convenience function interfacing to threadI (see L<PDL::Slices>).

=cut

sub PDL::thread1 {
	my $var = shift;
	$var->threadI(1,\@_);
}

=head2 PDL::thread2

=for ref

Explicit threading over specified dims using thread id 2.

=for usage

   $xx = $x->thread2(3,1)

=for example

  Wibble

Convenience function interfacing to threadI (see L<PDL::Slices>).

=cut

sub PDL::thread2 {
	my $var = shift;
	$var->threadI(2,\@_);
}

=head2 PDL::thread3

=for ref

Explicit threading over specified dims using thread id 3.

=for usage

   $xx = $x->thread3(3,1)

=for example

  Wibble

Convenience function interfacing to threadI (see L<PDL::Slices>).

=cut

sub PDL::thread3 {
	my $var = shift;
	$var->threadI(3,\@_);
}

my %info = (
	    D => {
		  Name => 'Dimension',
		  Sub => \&PDL::Core::dimstr,
		 },
	    T => {
		  Name => 'Type',
		  Sub => sub {$_ = $PDL::Types::typehash{
		    $PDL::Types::names[$_[0]->get_datatype]}->{'ctype'};
			    s/PDL_//; $_},
		 },
	    S => {
		  Name => 'State',
		  Sub => sub { my $state = '';
			       $state .= 'P' if $_[0]->allocated;
			       $state .= 'V' if $_[0]->vaffine &&
				 !$_[0]->allocated; # apparently can be both?
			       $state .= '-' if $state eq '';   # lazy eval
			       $state .= 'C' if $_[0]->anychgd;
			       $state;
			     },
		 },
	    F => {
		  Name => 'Flow',
		  Sub => sub { my $flows = '';
			       $flows = ($_[0]->bflows ? 'b':'') .
				 '~' . ($_[0]->fflows ? 'f':'')
				   if ($_[0]->flows);
			       $flows;
			     },
		 },
	    M => {
		  Name => 'Mem',
		  Sub => sub { my ($size,$unit) = ($_[0]->allocated ? 
						   $_[0]->nelem*
                      PDL::howbig($_[0]->get_datatype)/1024 : 0, 'Kb');
			       if ($size > 0.01*1024) { $size /= 1024;
							$unit = 'Mb' };
			       return sprintf "%6.2f%s",$size,$unit;
			     },
		 },
	    C => {
		  Name => 'Class',
		  Sub => sub { ref $_[0] }
		 },
	    A => {
		  Name => 'Address',
		  Sub => sub { sprintf "%d", $_[0]->address }
		 },
	   );

my $allowed = join '',keys %info;

# print the dimension information about a pdl in some appropriate form
sub dimstr {
  my $this = shift;

  my @dims = $this->dims;
  my @ids  = $this->threadids;
  my ($nids,$i) = ($#ids - 1,0);
  my $dstr = 'D ['. join(',',@dims[0..($ids[0]-1)]) .']';
  if ($nids > 0) {
    for $i (1..$nids) {
      $dstr .= " T$i [". join(',',@dims[$ids[$i]..$ids[$i+1]-1]) .']';
    }
  }
  return $dstr;
}

=head2 PDL::info

=for ref

Return formatted information about a piddle.

=for usage

   $x->info($format_string);

=for example

   print $x->info("Type: %T Dim: %-15D State: %S");

Returns a string with info about a piddle. Takes an optional
argument to specify the format of information a la sprintf.
Format specifiers are in the form C<%E<lt>widthE<gt>E<lt>letterE<gt>>
where the width is optional and the letter is one of

=over 7

=item T

Type

=item D

Formatted Dimensions

=item F

Dataflow status

=item S

Some internal flags (P=physical,V=Vaffine,C=changed)

=item C

Class of this piddle, i.e. C<ref $pdl>

=item A

Address of the piddle struct as a unique identifier

=item M

Calculated memory consumption of this piddle's data area

=back

=cut

sub PDL::info {
  my ($this,$str) = @_;
  $str = "%C: %T %D" unless defined $str;
  return ref($this)."->null" if PDL::Core::dimstr($this)
    =~ /D \[0\]/;
  my @hash = split /(%[-,0-9]*[.]?[0-9]*\w)/, $str;
  my @args = ();
  my $nstr = '';
  for my $form (@hash) {
    if ($form =~ s/^%([-,0-9]*[.]?[0-9]*)(\w)$/%$1s/)
      { barf "unknown format specifier $2" unless defined $info{$2};
	push @args, &{$info{$2}->{Sub}}($this) }
    $nstr .= $form;
  }
  return sprintf $nstr, @args;
}

=head2 mslice

=for ref

Convenience interface to C<slice>, allowing easier inclusion
of dimensions in perl code.

=for usage

  $a = $x->mslice(...); 

=for example

  $a = $x->mslice([5,7],X,[3,4,2]); # eq: $x->slice("5:7,:,3:4:2")

=cut

sub PDL::mslice {
        my($pdl) = shift;
        return $pdl->slice(join ',',(map {
                        $_ eq "X" ? ":" :
                        ref $_ eq "ARRAY" ? join ':',@$_ :
                        !ref $_ ? $_ : 
                        die "INVALID SLICE DEF $_"
                } @_));
}

# Utility to determine if argument is blessed object

sub blessed { 
    my $ref = ref(shift);
    return $ref =~ /^(REF|SCALAR|ARRAY|HASH|CODE|GLOB||)$/ ? 0 : 1;
} 
       
# Convert numbers to PDL if not already

sub PDL::topdl {      
    return $_[1] if blessed($_[1]); # Fall through
    return $_[0]->new($_[1]) if ref(\$_[1]) eq "SCALAR";
    barf("Can not convert a ".ref($_[1])." to a ".$_[0]);
0;}

# Convert everything to PDL if not blessed

sub alltopdl {    
    return $_[1] if blessed($_[1]); # Fall through
    return $_[0]->new($_[1]);
0;}

=head2 inplace

=for ref

Flag a piddle so that the next operation is done 'in place'

=for usage

  somefunc($x->inplace); somefunc(inplace $x); 
  
In most cases one likes to use the syntax C<$y = f($x)>, however
in many case the operation C<f()> can be done correctly
'in place', i.e. without making a new copy of the data for 
output. To make it easy to use this, we write C<f()> in such
a way that it operates in-place, and use C<inplace> to hint
that a new copy should be disabled. This also makes for
clear syntax.

Obviously this will not work for all functions, and if in
doubt see the function's documentation. However one 
can assume this is
true for all elemental functions (i.e. those which just
operate array element by array element like C<log10>).

=for example


 perldl> $x = xvals zeroes 10;
 perldl> log10(inplace $x)
 perldl> p $x
 [      -Inf 0    0.30103 0.47712125 0.60205999    0.69897 
 0.77815125 0.84509804 0.90308999 0.95424251]

=cut

# Flag pdl for in-place operations

sub PDL::inplace {
    my $pdl = PDL->topdl(shift); $pdl->set_inplace(1); return $pdl;
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
*PDL::new_or_inplace = \&new_or_inplace;

# Allow specifications like zeroes(10,10) or zeroes($x)
# or zeroes(inplace $x) or zeroes(float,4,3)

=head2 PDL::new_from_specification

=for ref

Internal method: create piddle by specification

This is the argument processing method called by C<zeroes> (q.v.) 
and some other functions
which constructs piddles from argument listss of the form:

   [type], $nx, $ny, $nz,...

=cut

sub PDL::new_from_specification{
    my $class = shift;
    my $type = ref($_[0]) eq 'PDL::Type' ? ${shift @_}[0]  : $PDL_D;
    my $nelems = 1; my @dims;
    for (@_) { 
       barf "Trying to use piddle as dimensions?" if ref $_;
       barf "Dimensions must be positive" if $_<=0;
       $nelems *= $_; push @dims, $_ 
    }
    my $pdl = $class->initialize();
    $pdl->set_datatype($type);
    $pdl->setdims([@dims]);
    print "Dims: ",(join ',',@dims)," DLen: ",(length $ {$pdl->get_dataref}),"\n" if $PDL::verbose;
    return $pdl;
}    

=head2 zeroes

=for ref

construct a zero filled piddle from dimension list or template piddle. 

Various forms of usage,

(i) by specification or (ii) by template piddle:

=for usage

    # usage type (i):
    $a = zeroes([type], $nx, $ny, $nz,...);
    $a = PDL->zeroes([type], $nx, $ny, $nz,...);
    $a = $pdl->zeroes([type], $nx, $ny, $nz,...);
    # usage type (ii):
    $a = zeroes $b;
    $a = $b->zeroes
    zeroes inplace $a;     # Equivalent to   $a .= 0;
    $a->inplace->zeroes;   #  ""
 
=for example

 perldl> $z = zeroes 4,3  
 perldl> p $z
 [
  [0 0 0 0]
  [0 0 0 0]
  [0 0 0 0]
 ]
 perldl> $z = zeroes ushort, 3,2 # Create ushort array

 [ushort() etc. with no arg returns a PDL::Types token]

=cut
 


sub zeroes { ref($_[0]) && ref($_[0]) ne 'PDL::Type' ? $_[0]->zeroes : PDL->zeroes(@_) }
sub PDL::zeroes {
    my $class = shift;
    my $pdl = scalar(@_)? $class->new_from_specification(@_) : $class->new_or_inplace;
    $pdl.=0;
    return $pdl;
}



=head2 ones

=for ref

construct a one filled piddle

=for usage

   $a = ones([type], $nx, $ny, $nz,...);
   etc. (see 'zeroes')
   

=for example

 see zeroes() and add one

=cut

sub ones { ref($_[0]) && ref($_[0]) ne 'PDL::Type' ? $_[0]->ones : PDL->ones(@_) }
sub PDL::ones {
    my $class = shift;
    my $pdl = scalar(@_)? $class->new_from_specification(@_) : $class->new_or_inplace;
    $pdl.=1;
    return $pdl;
}

=head2 reshape

=for ref

Change the shape (i.e. dimensions) of a piddle, preserving contents.

=for usage

 $x->reshape(NEWDIMS); reshape($x, NEWDIMS);
 
The data elements are preserved, obviously they will wrap
differently and get truncated if the new array is shorter.
If the new array is longer it will be zero-padded.   

=for example

  perldl> $x = sequence(10)
  perldl> reshape $x,3,4; p $x
  [
   [0 1 2]
   [3 4 5]
   [6 7 8]
   [9 0 0]
  ]
  perldl> reshape $x,5; p $x        
  [0 1 2 3 4]

=cut


*reshape = \&PDL::reshape;
sub PDL::reshape{
  my $pdl = shift;
  my $nelem = $pdl->nelem;
  $pdl->setdims([@_]);
  $pdl->upd_data;
  if ($pdl->nelem > $nelem) {
     my $tmp=$pdl->clump(-1)->slice("$nelem:-1");
     $tmp .= 0;
  }
  return $pdl;
}
                      
=head2 convert

=for ref

Generic datatype conversion function

=for usage

 $y = convert($x, $newtype);  

=for example

 $y = convert $x, long
 $y = convert $x, ushort 

C<$newtype> is a type number, for convenience they are
returned by long() etc when called without arguments.

=cut


# type to type conversion functions (with automatic conversion to pdl vars)

sub PDL::convert {
  # we don't allow inplace conversion at the moment
  # (not sure what needs to be changed)
  barf 'Usage: $y = convert($x, $newtype)'."\n" if $#_!=1;
  my ($pdl,$type)= @_;
  $pdl = pdl($pdl) unless ref $pdl; # Allow normal numbers
  $type = $type->[0] if ref($type) eq 'PDL::Type';
  return $pdl if $pdl->get_datatype == $type;
  my $conv = $pdl->flowconvert($type)->sever;
  return $conv;
}

=head2 Datatype_conversions

=for ref

byte|short|ushort|long|float|double convert shorthands

=for usage

  $y = double $x; $y = ushort [1..10];
  
  (all of byte|short|ushort|long|float|double behave similarly)
  
When called with a piddle argument, they convert to the specific
datatype.
	
When called with a numeric or list ref argument they construct
a new piddle. This is a convenience to avoid having to be
long-winded and say <$x = long(pdl(42))>
	
When called with no arguments return a special type token.
This allows syntactical sugar like:

  $x = ones byte, 1000,1000; 
  
This example creates a large piddle directly as byte datatype in 
order to save memory.

=for example

 perldl> p $x=sqrt float [1..10]
 [1 1.41421 1.73205 2 2.23607 2.44949 2.64575 2.82843 3 3.16228]
 perldl> p byte $x
 [1 1 1 2 2 2 2 2 3 3]

=head2 byte

=for ref

Convert to byte datatype - see 'Datatype_conversions'

=head2 short

=for ref

Convert to short datatype - see 'Datatype_conversions'

=cut

=head2 ushort

=for ref

Convert to ushort datatype - see 'Datatype_conversions'

=cut

=head2 long

=for ref

Convert to long datatype - see 'Datatype_conversions'

=cut

=head2 float

=for ref

Convert to float datatype - see 'Datatype_conversions'

=cut

=head2 double

=for ref

Convert to double datatype - see 'Datatype_conversions'

=cut

for(
	["byte",'$PDL_B'],
	["short",'$PDL_S'],
	["ushort",'$PDL_US'],
	["long",'$PDL_L'],
	["float",'$PDL_F'],
	["double",'$PDL_D']
) {
	eval ('sub PDL::'.$_->[0]." { ".
		'return bless ['.$_->[1].'], PDL::Type unless @_;
		 convert(alltopdl(\'PDL\',shift),'.$_->[1].') 
		}');
}

{package PDL::Type;
 sub new {my($type,$val) = @_;
	  if("PDL::Type" eq ref $val) {return bless [@$val],$type}
	  if(ref $val and $val->isa(PDL)) {
		if($val->getndims != 0) {
		  PDL::Core::barf("Can't make a type out of non-scalar piddle $val!");
		} 
		$val = $val->at;
	  }
	  PDL::Core::barf("Can't make a type out of non-scalar $val!".(ref $val)."!") if ref $val;
          bless [$val],$type
	  }
}


=head2 type

=for ref

return the type of a piddle as a blessed type object

A convenience function for use with the piddle constructors, e.g.

=for example

   $b = PDL->zeroes($a->type,$a->dims,3);

=cut

sub PDL::type {
  return PDL::Type->new($_[0]->get_datatype);
}

##################### Printing ####################

# New string routine

$PDL::_STRINGIZING = 0;

sub string { 
    my($self,$format)=@_;
    if($PDL::_STRINGIZING) {
    	return "ALREADY_STRINGIZING_NO_LOOPS";
    }
    local $PDL::_STRINGIZING = 1;
    my $ndims = $self->getndims;
    if($self->nelem > 10000) {
    	return "TOO LONG TO PRINT";
    }
    if ($ndims==0) {
       my @x = $self->at();
       return ($format ? sprintf($format, $x[0]) : "$x[0]");
    }
    return "Null" if $ndims==1 && $self->getdim(0)==0; # Null token
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

=head2 list

=for ref

Convert piddle to perl list 

=for usage

   @tmp = list $x;

Obviously this is grossly inefficient for the large datasets PDL is designed to
handle. This was provided as a get out while PDL matured. It  should now be mostly
superseded by superior constructs, such as PP/threading. However it is still
occasionally useful and is provied for backwards compatibility.    

=for example

  for (list $x) {
    # Do something on each value...
  }
  

=cut

# No threading, just the ordinary dims.
sub PDL::list{ # pdl -> @list
     barf 'Usage: list($pdl)' if $#_!=0;
     my $pdl = PDL->topdl(shift);
     @{listref_c($pdl)};
}

=head2 listindices

=for ref

Convert piddle indices to perl list 

=for usage

   @tmp = listindices $x;
   
C<@tmp> now contains the values 0..nelem($x).   
   
Obviously this is grossly inefficient for the large datasets PDL is designed to
handle. This was provided as a get out while PDL matured. It  should now be mostly
superseded by superior constructs, such as PP/threading. However it is still
occasionally useful and is provied for backwards compatibility.    

=for example

  for $i (listindices $x) {
    # Do something on each value...
  }

=cut

sub PDL::listindices{ # Return list of index values for 1D pdl
     barf 'Usage: list($pdl)' if $#_!=0;
     my $pdl = shift; 
     barf 'Not 1D' if scalar(dims($pdl)) != 1;
     return (0..nelem($pdl)-1);
}

=head2 set

=for ref

Set a single value inside a piddle

=for usage

 set $piddle, @position, $value
   
C<@position> is a coordinate list, of size equal to the
number of dimensions in the piddle. Occasionally useful,
mainly provided for backwards compatibility as superseded
by use of C<slice> and assigment operator C<.=>.

=for example

 perldl> $x = sequence 3,4
 perldl> set $x, 2,1,99   
 perldl> p $x             
 [
  [ 0  1  2]
  [ 3  4 99]
  [ 6  7  8]
  [ 9 10 11]
 ]

=cut

sub PDL::set{    # Sets a particular single value 
    barf 'Usage: set($pdl, $x, $y,.., $value)' if $#_<2;
    my $self  = shift; my $value = pop @_;
    set_c ($self, [@_], $value);
    return $self;
}

=head2 at

=for ref

Returns a single value inside a piddle as perl scalar.

=for usage

  $z = at($piddle, @position); $z=$piddle->at(@position);

C<@position> is a coordinate list, of size equal to the
number of dimensions in the piddle. Occasionally useful
in a general context, quite useful too inside PDL internals.

=for example

 perldl> $x = sequence 3,4
 perldl> p $x->at(1,2)
 7 

=cut

sub PDL::at {     # Return value at ($x,$y,$z...)
    barf 'Usage: at($pdl, $x, $y, ...)' if $#_<0;
    my $self = shift;
    at_c ($self, [@_]);
}

=head2 cat

=for ref

concatentate piddles to N+1 dimensional piddle

Takes a list of N piddles of same shape as argument,
returns a single piddle of dimension N+1

=for example

 perldl> $x = cat ones(3,3),zeroes(3,3),rvals(3,3); p $x

 [
  [
   [1 1 1]
   [1 1 1]
   [1 1 1]
  ]
  [
   [0 0 0]
   [0 0 0]
   [0 0 0]
  ]
  [
   [1 1 1]
   [1 0 1]
   [1 1 1]
  ]
 ]

=cut

sub PDL::cat {
  my $res = $_[0]->initialize; $res->set_datatype($_[0]->get_datatype);
  $res->setdims([$_[0]->dims,scalar(@_)]);
  my ($i,$t); my $s = ":,"x$_[0]->getndims;
  for (@_) { $t = $res->slice($s."(".$i++.")"); $t .= $_}
  return $res;
}

=head2 dog

=for ref

Opposite of 'cat' :). Split N dim piddle to list of N-1 dim piddles

Takes a single N-dimensional piddle and splits it into a list of N-1 dimensional
piddles. The breakup is done along the last dimension.
Note the dataflown connection is still preserved by default,
e.g.:

=for example

	perldl> $p = ones 3,3,3
	perldl> ($a,$b,$c) = dog $p
	perldl> $b++; p $p

	[
	 [
	  [1 1 1]
	  [1 1 1]
	  [1 1 1]
	 ]
	 [
	  [2 2 2]
	  [2 2 2]
	  [2 2 2]
	 ]
	 [
	  [1 1 1]
	  [1 1 1]
	  [1 1 1]
	 ]
	]

=for options

   Break => 1   Break dataflow connection (new copy)

=cut

sub PDL::dog {
  my $opt = pop @_ if ref($_[-1]) eq 'HASH';
  my $p = shift;
  my @res; my $s = ":,"x($p->getndims-1);
  for my $i (0..$p->getdim($p->getndims-1)-1) {
     $res[$i] = $p->slice($s."(".$i.")"); 
     $res[$i] = $res[$i]->copy if $$opt{Break};
     $i++;
  }
  return @res;
}

# New error handling routine

=head2 barf

=for ref

Standard error reporting routine for PDL.

barf() is the routine PDL modules should call to report errors. This
is because barf() will report the error as coming from the correct
line in the module user's script rather than in the PDL module.

It does this magic by unwinding the stack frames until it reaches
a package NOT beginning with "PDL::". If you DO want it to report
errors in some module PDL::Foo (e.g. when debugging PDL::Foo) then
set the variable C<$PDL::Foo::Debugging=1>.  

Additionally if you set the variable C<$PDL::Debugging=1> you will
get a COMPLETE stack trace back up to the top level package.

Finally barf() will try and report usage information from the 
PDL documentation database if the error message is of the 
form 'Usage: func'.

Remember barf() is your friend. *Use* it!

=for example

At the perl level:

   barf("User has too low an IQ!");

In C or XS code:

  barf("You have made %d errors", count);    
  
Note: this is one of the few functions ALWAYS exported
by PDL::Core

=cut

sub barf { die barf_msg(@_) };

# This sub is called by Perl barf() and pdl_barf in pdlcore.c

sub barf_msg {
  my ($err) = @_;
  my $i = 0;
  my($pack,$file,$line);
  my $msg="";
  $msg .= "PDL barfed: $err\nStack trace:\n" if $PDL::Debugging;
  while(1) { # Unwind the stack
    ($pack,$file,$line) = caller($i);
    last unless $pack;
    $msg .= " Level $i: file $file, line $line, pkg $pack\n" if $PDL::Debugging;
    last if !$PDL::Debugging and ($pack !~ /^PDL::|^PDL$/ or eval '$'.$pack."::Debugging");
    $i++;
  }  
     
  if ($err =~ /^Usage: (PDL.*::)_(\w+)_int/ or $err =~ /^Usage: (PDL.*::)?\s*(\w+)/) {
     local $match = $2;
     eval << "EOD";
     \$msg .= "PDL barfed: incorrect usage of function '$match()'\nFile $file, line $line, pkg $pack\n" if \$pack;
     \$msg .= "Usage information from PDL docs database:\n";
     use PDL::Doc::Perldl; 
     \$msg .= PDL::Doc::Perldl::usage_string ('$match');
EOD
  }
  else{
     $msg .= "PDL barfed: $err\nCaught at file $file, line $line, pkg $pack\n" if $pack;
  }
  $msg .= "\n" if substr($msg,-1,1) ne "\n";
  return $msg;
}

###################### Misc internal routines ####################


# Recursively pack an N-D array ref in format [[1,1,2],[2,2,3],[2,2,2]] etc
# package vars $level and @dims must be initialised first.

sub rpack {             
            
    my ($ptype,$a) = @_;  my ($ret,$type);

    $ret = "";
    if (ref($a) eq "ARRAY") {

       if (defined($dims[$level])) {
           barf 'Array is not rectangular' unless $dims[$level] == scalar(@$a);
       }else{
          $dims[$level] = scalar(@$a);
       }
       $level++;

       $type = ref($$a[0]);
       for(@$a) { 
          barf 'Array is not rectangular' unless $type eq ref($_); # Equal types
          $ret .= rpack($ptype,$_);
       }
       $level--;

    }elsif (ref(\$a) eq "SCALAR") { # Note $PDL_D assumed

      $ret = pack($ptype,$_);
 
    }else{
        barf "Don't know how to make a PDL object from passed argument";
    }
    return $ret;
}

sub rcopyitem {        # Return a deep copy of an item - recursively
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
       barf ('Deep copy of object failed - unknown component with type '.ref($x));
    }
0;}

# N-D array stringifier

sub strND {
    my($self,$format,$level)=@_;
#    $self->make_physical();
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
    barf "Not 1D" if $self->getndims()!=1;
    my $x = listref_c($self);
    my ($ret,$dformat,$t);
    $ret = "[";
    $dformat = $PDL::floatformat  if $self->get_datatype() == $PDL_F;
    $dformat = $PDL::doubleformat if $self->get_datatype() == $PDL_D;
    for $t (@$x) {
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
    barf "Not 2D" if scalar(@dims)!=2;
    my $x = listref_c($self);
    my ($i, $f, $t, $len, $ret);

    if (!defined $format || $format eq "") { # Format not given? - 
                                             # find max length of default
       $len=0;
       for (@$x) {$i = length($_); $len = $i>$len ? $i : $len };
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
    for (@$x) { 
       $i = length(sprintf $format,$_); $len = $i>$len ? $i : $len;
    }
       
    output:     # Generate output

    $ret = "\n" . " "x$level . "[\n";
    { my $level = $level+1;
      $ret .= " "x$level ."[";
      for ($i=0; $i<=$#$x; $i++) { 
          $f = sprintf $format,$$x[$i];
          $t = $len-length($f); $f = " "x$t .$f if $t>0;
          $ret .= $f;
	  if (($i+1)%$dims[0]) { 
	     $ret.=$sep;
          }
	  else{ # End of output line
	     $ret.="]";
	     if ($i==$#$x) { # very last number
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


1;# Exit with OK status

=head1 AUTHOR

Copyright (C) Karl Glazebrook (kgb@aaoepp.aao.gov.au),
Tuomas J. Lukka, (lukka@husc.harvard.edu) and Christian
Soeller (csoelle@sghms.ac.uk) 1997. Reproducing 
documentation from the pdl distribution in any way that does not
include a statement telling who the original authors are is
forbidden.  Reproducing and/or distributing the documentation 
in any  form that  alters the text is forbidden.

=cut


1;
