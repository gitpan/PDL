=head1 NAME

PDL::Graphics::PGPLOT - PGPLOT enhanced interface for PDL

=head1 SYNOPSIS

   perldl> $a = pdl [1..100]
   perldl> $b = sqrt($a)
   perldl> line $b      
   perldl> hold
   Graphics on HOLD
   perldl> $c = sin($a/10)*2 + 4
   perldl> line $c     

=head1 DESCRIPTION

PDL::Graphics::PGPLOT is an interface to the PGPLOT graphical libraries.

=head1 FUNCTIONS

Current display commands:

   imag         -  Display an image (uses pgimag()/pggray() as appropriate)
   ctab         -  Load an image colour table
   line         -  Plot vector as connected points
   points       -  Plot vector as points
   errb         -  Plot error bars
   cont         -  Display image as contour map
   bin          -  Plot vector as histogram ( e.g. C<bin(hist($data))> )
   hi2d         -  Plot image as 2d histogram (not very good IMHO...)
   poly         -  Draw a polygon
   vect         -  Display 2 images as a vector field

Device manipulation commands:

   hold         -  Hold current plot window range - allows overlays etc.
   release      -  Release back to autoscaling of new plot window for each command
   rel          -  short alias for 'release'
   env          -  Define a plot window, put on 'hold'
   dev          -  Explicitly set a new PGPLOT graphics device

The actual PGPLOT module is loaded only when the first of these
commands is executed.
   
Notes: $transform for image/cont etc. is used in the same way as the
TR() array in the underlying PGPLOT FORTRAN routine but is, fortunately,
zero-offset.

A more detailed listing of the functions and their usage follows.


=head2 imag

=for ref

Display an image (uses pgimag()/pggray() as appropriate)

=for usage

  Usage: imag ( $image,  [$min, $max, $transform] )

Notes: $transform for image/cont etc. is used in the same way as the
TR() array in the underlying PGPLOT FORTRAN routine but is, fortunately,
zero-offset.

=head2 ctab

=for ref

Load an image colour table

Usage:

=for usage

   ctab ( $name, [$contrast, $brightness] ) # Builtin col table
   ctab ( $ctab, [$contrast, $brightness] ) # $ctab is Nx4 array
   ctab ( $levels, $red, $green, $blue, [$contrast, $brightness] )

=head2 line

=for ref

Plot vector as connected points

=for usage

 Usage: line ( [$x,] $y )


=head2 points

=for ref

Plot vector as points

=for usage

 Usage: points ( [$x,] $y, [$symbol(s)] )


=head2 errb

=for ref

Plot error bars (using pgerrb())

Usage:

=for usage

   errb ( $y, $yerrors )
   errb ( $x, $y, $yerrors )
   errb ( $x, $y, $xerrors, $yerrors )
   errb ( $x, $y, $xloerr, $xhierr, $yloerr, $yhierr)


=head2 cont

=for ref

Display image as contour map

=for usage

 Usage: cont ( $image,  [$contours, $transform, $misval] )

Notes: $transform for image/cont etc. is used in the same way as the
TR() array in the underlying PGPLOT FORTRAN routine but is, fortunately,
zero-offset.


=head2 bin

=for ref

Plot vector as histogram ( e.g. C<bin(hist($data))> )

=for usage

   Usage: bin ( [$x,] $data )


=head2 hi2d

=for ref

Plot image as 2d histogram (not very good IMHO...)

=for usage

   Usage: hi2d ( $image, [$x, $ioff, $bias] )


=head2 poly

=for ref

Draw a polygon

=for usage

Usage: poly ( $x, $y )


=head2 vect

=for ref

Display 2 images as a vector field

=for usage

   Usage: vect ( $a, $b, [$scale, $pos, $transform, $misval] )

Notes: $transform for image/cont etc. is used in the same way as the
TR() array in the underlying PGPLOT FORTRAN routine but is, fortunately,
zero-offset.


=head1 AUTHOR

Karl Glazebrook [kgb@aaoepp.aao.gov.au], docs mangled by Tuomas J. Lukka
(lukka@fas.harvard.edu) and Christian Soeller (csoelle@sghms.ac.uk).

All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL 
distribution. If this file is separated from the PDL distribution, 
the copyright notice should be included in the file.


=cut


# Graphics functions for the PDL module, this module
# requires the PGPLOT module be previously installed.
# PGPLOT functions are also made available to the caller.

package PDL::Graphics::PGPLOT;

# Just a plain function exporting package

@EXPORT = qw( dev hold release rel env bin cont errb line points
                 imag image ctab hi2d poly vect
);

use PDL::Core qw/:Func :Internal/;    # Grab the Core names
use PDL::Basic;
use PDL::Primitive;
use PDL::Types;
use SelfLoader;
use Exporter;

use vars qw($AXISCOLOUR $SYMBOL $ERRTERM $HARD_LW $HARD_CH $HARD_FONT);

@ISA = qw( Exporter SelfLoader ); 

*rel = *release; # Alias
*image = *imag;

############################################################################

# Global variables for customisation, defaults are:

$AXISCOLOUR = 3;   # Axis colour
$SYMBOL     = 17;  # Plot symbol for points
$ERRTERM    = 1;   # Size of error bar terminators
$HARD_LW    = 4;   # Line width for hardcopy devices
$HARD_CH    = 1.4; # Character height for hardcopy devices
$HARD_FONT  = 2;   # Font for hardcopy devices

# Standard colour tables (args to ctab())

%CTAB = ();
$CTAB{Grey}    = [ pdl([0,1],[0,1],[0,1],[0,1]) ];
$CTAB{Igrey}   = [ pdl([0,1],[1,0],[1,0],[1,0]) ];
$CTAB{Fire}    = [ pdl([0,0.33,0.66,1],[0,1,1,1],[0,0,1,1],[0,0,0,1]) ];
$CTAB{Gray}    = $CTAB{Grey};  # Alias
$CTAB{Igray}   = $CTAB{Igrey}; # Alias
$DEV  = $ENV{"PGPLOT_DEV"} if defined $ENV{"PGPLOT_DEV"};
$DEV  = "?" if !defined($DEV) || $DEV eq ""; # Safe default


BEGIN { $pgplot_loaded = 0 }

END { # Destructor to close plot when perl exits
     if ($pgplot_loaded) {
        my ($state,$len);
        pgqinf('STATE',$state,$len);
        pgend() if $state eq "OPEN";
     }
}

# Load PGPLOT only on demand

local $^W=0;  # Do it this way to suppress spurious warnings
eval << 'EOD';
sub AUTOLOAD {
   eval << 'EOC' unless $pgplot_loaded;
   use PGPLOT; $pgplot_loaded=1;   # For me
   my $i=0; my $pkg;
   do { $pkg = (caller($i++))[0]; } until $pkg ne "PDL::Graphics::PGPLOT";
   eval "{ package $pkg; use PGPLOT; }";  # For caller
   print "Loaded PGPLOT\n" if $PDL::verbose;
EOC
   barf "Need PGPLOT v2.0 or higher" if $PGPLOT::VERSION<2; 
   $SelfLoader::AUTOLOAD = $AUTOLOAD;
   goto &SelfLoader::AUTOLOAD;
}
EOD

1;# Exit with OK status


__DATA__

# SelfLoaded functions

############ Local functions #################

sub checkarg {  # Check/alter arguments utility
    my ($arg,$dims,$type) = @_;
    $type = $PDL_F unless defined $type;
    $arg = topdl($arg); # Make into a pdl
    $arg = convert($arg,$type) if $arg->get_datatype != $type;
    barf "Data is >".$dims."D" if $arg->getndims > $dims;
    $_[0] = $arg; # Alter
1;}

sub pgdefaults{    # Set up defaults
    local($hcopy, $len);
    pgask(0);
    pgqinf("HARDCOPY",$hcopy,$len);  
    if ($hcopy eq "YES") {  
       pgslw($HARD_LW); pgsch($HARD_CH);     
       pgscf($HARD_FONT); 
    }
    pgsci(5); pgask(0);
}

sub initdev{  # Ensure a device is open
     local ($state,$len); 
     pgqinf('STATE',$state,$len); 
     dev() if ($state eq "CLOSED");
1;}

sub initenv{ # Default box
    my ($col); initdev(); pgqci($col); pgsci($AXISCOLOUR); 
    pgenv(@_,0,0); pgsci($col);
    @last = (@_,0,0); 
1;} 

sub redraw_axes {
    pgqci($col); pgsci($AXISCOLOUR);
    pgbox('BCNST',0,0,'BCNST',0,0) unless $hold;
    pgsci($col); 
}


sub CtoF77coords{  # convert a transform array from zero-offset to unit-offset images
    my $tr = pdl(shift); # Copy
    set($tr, 0, at($tr,0)-at($tr,1)-at($tr,2));
    set($tr, 3, at($tr,3)-at($tr,4)-at($tr,5));
    return $tr;
}

############ Exported functions #################

# Open/reopen the graphics device

sub dev {
    local ($dev,$nx,$ny) = @_;
    $dev = $DEV if !defined $dev || $dev eq "";
    $nx = 1 unless defined $nx;
    $ny = 1 unless defined $ny;
    local ($state,$len);
    pgqinf('STATE',$state,$len);
    pgend() if ($state eq "OPEN");
    pgbegin(0,$dev,$nx,$ny);
    pgdefaults();
1;}

# hold/release functions for overlays

$hold = 0; 
sub hold    { $hold=1; print "Graphics on HOLD\n" if $PDL::verbose;}; 
sub release { $hold=0; print "Graphics RELEASED\n" if $PDL::verbose;};

# set the envelope for plots and put auto-axes on hold

sub env {
    barf 'Usage: env ( $xmin, $xmax, $ymin, $ymax, [$just, $axis] )' 
       if ($#_==-1 && !defined(@last)) || ($#_>=0 && $#_<=2) || $#_>5;
    my(@args);
    @args = $#_==-1 ? @last : @_;         # No args - use previous
    $args[4] = 0 unless defined $args[4]; # $just 
    $args[5] = 0 unless defined $args[5]; # $axis 
    initdev();
    pgqci($col); pgsci($AXISCOLOUR);
    pgenv(@args);
    @last = @args;
    pgsci($col); 
    hold;
1;}


# Plot a histogram with pgbin()

sub bin {
    barf 'Usage: bin ( [$x,] $data )' if $#_<0 || $#_>1;
    my($x,$data) = @_;
    checkarg($x,1);

    my $n = nelem($x);
    if ($#_==1) {
       checkarg($data,1); barf '$x and $data must be same size' if $n!=nelem($data);
    }else{
       $data = $x; $x = float(sequence($n));
    }

    initenv( min($x), max($x), 0, max($data) ) unless $hold;
    pgbin($n, $x->get_dataref, $data->get_dataref, 1);
1;}

# display a contour map of an image using pgconb()

sub cont {
    barf 'Usage: cont ( $image,  [$contours, $transform, $misval] )' if $#_<0 || $#_>3;
    my ($image, $contours, $tr, $misval) = @_;
    checkarg($image,2); 
    my($nx,$ny) = $image->dims;

    $contours = min($image) + sequence(9)*(max($image)-min($image))/8  # Auto
                unless defined $contours;
    checkarg($contours,1);

    if (defined($tr)) {
       checkarg($tr,1);
       barf '$transform incorrect' if nelem($tr)!=6;
    }else{
       $tr = float [0,1,0, 0,0,1];
    }
    $tr = CtoF77coords($tr);
        
    initenv( 0,$nx-1, 0, $ny-1 ) unless $hold;
    print "Contouring $nx x $ny image from ",min($contours), " to ",
           max($contours), " in ",nelem($contours)," steps\n" if $PDL::verbose;
    
    if (defined($misval)) {
       pgconb( $image->get_dataref, $nx,$ny,1,$nx,1,$ny, $contours->get_dataref, 
                         nelem($contours), $tr->get_dataref, $misval);
    }else{
       pgcons( $image->get_dataref, $nx,$ny,1,$nx,1,$ny, $contours->get_dataref, 
                         nelem($contours), $tr->get_dataref);
    }
1;}

# Plot errors with pgerrb()

sub errb {
    barf <<'EOD' if $#_<1 || $#_==4 || $#_>5;
Usage: errb ( $y, $yerrors )
       errb ( $x, $y, $yerrors )
       errb ( $x, $y, $xerrors, $yerrors )
       errb ( $x, $y, $xloerr, $xhierr, $yloerr, $yhierr)
EOD
    my @t = @_; my $i=0; my $n;
    for (@t) {
        checkarg($_, 1); 
        $n = nelem($_) if $i++ == 0;
        barf "Args must have same size" if nelem($_)!=$n;
    }
    my $x = $#t==1 ? float(sequence($n)) : $t[0];
    my $y = $#t==1 ? $t[0] : $t[1];
    initenv( min($x), max($x), min($y), max($y) ) unless $hold;
    pgerrb(6,$n,$x->get_dataref,$y->get_dataref,$t[1]->get_dataref,$ERRTERM) if $#t==1;
    pgerrb(6,$n,$x->get_dataref,$y->get_dataref,$t[2]->get_dataref,$ERRTERM) if $#t==2;
    pgerrb(5,$n,$x->get_dataref,$y->get_dataref,$t[2]->get_dataref,$ERRTERM) if $#t==3;
    pgerrb(6,$n,$x->get_dataref,$y->get_dataref,$t[3]->get_dataref,$ERRTERM) if $#t==3;
    if ($#t==5) {
       pgerrb(1,$n,$x->get_dataref,$y->get_dataref,$t[3]->get_dataref,$ERRTERM);
       pgerrb(2,$n,$x->get_dataref,$y->get_dataref,$t[5]->get_dataref,$ERRTERM);
       pgerrb(3,$n,$x->get_dataref,$y->get_dataref,$t[2]->get_dataref,$ERRTERM);
       pgerrb(4,$n,$x->get_dataref,$y->get_dataref,$t[4]->get_dataref,$ERRTERM);
    }
1;}

# Plot a line with pgline()

sub line {
    barf 'Usage: line ( [$x,] $y )' if $#_<0 || $#_>1;
    my($x,$y) = @_;
    checkarg($x,1);

    my $n = nelem($x);
    if ($#_==1) {
       checkarg($y,1); barf '$x and $y must be same size' if $n!=nelem($y);
    }else{
       $y = $x; $x = float(sequence($n));
    }

    initenv( min($x), max($x), min($y), max($y) ) unless $hold;
    pgline($n, $x->get_dataref, $y->get_dataref);
1;}

# Plot points with pgpnts()

sub points {
    barf 'Usage: points ( [$x,] $y, [$symbol(s)] )' if $#_<0 || $#_>2;
    my($x,$y,$sym) = @_;
    checkarg($x,1);

    my $n = nelem($x);
    if ($#_>=1) {
       checkarg($y,1); barf '$x and $y must be same size' if $n!=nelem($y);
    }else{
       $y = $x; $x = float(sequence($n));
    }
    $sym = $SYMBOL if $#_ != 2;
    checkarg($sym,1); my $ns = nelem($sym); $sym = long($sym); 

    initenv( min($x), max($x), min($y), max($y) ) unless $hold;
    pgpnts($n, $x->get_dataref, $y->get_dataref, $sym->get_dataref, $ns);
1;}

# display an image using pgimag()/pggray() as appropriate

sub imag {
    barf 'Usage: imag ( $image,  [$min, $max, $transform] )' if $#_<0 || $#_>2;
    my ($image,$min,$max,$tr) = @_;
    checkarg($image,2);
    my($nx,$ny) = $image->dims;

    $min = min($image) unless defined $min;
    $max = max($image) unless defined $max;
    if (defined($tr)) {
       checkarg($tr,1);
       barf '$transform incorrect' if nelem($tr)!=6;
    }else{
       $tr = float [0,1,0, 0,0,1];
    }
    $tr = CtoF77coords($tr);

    initenv( -0.5,$nx-0.5, -0.5, $ny-0.5  ) unless $hold;
    print "Displaying $nx x $ny image from $min to $max ...\n" if $PDL::verbose;

    pgqcir($i1, $i2);          # Colour range - if too small use pggray dither algorithm
    pgqinf('TYPE',$dev,$len);  # Device (/ps buggy - force pggray)
    if ($i2-$i1<16 || $dev =~ /^v?ps$/i) {
       pggray( $image->get_dataref, $nx,$ny,1,$nx,1,$ny, $min, $max, $tr->get_dataref);
    }
    else{
       ctab(Grey) unless $CTAB; # Start with grey
       pgimag( $image->get_dataref, $nx,$ny,1,$nx,1,$ny, $min, $max, $tr->get_dataref);
    }
    redraw_axes unless $hold; # Redraw box
1;}

# Load a colour table using pgctab()

sub ctab {

    # First indirect arg list through %CTAB

    my(@arg) = @_;
    if ($#arg>=0 && !ref($arg[0])) { # First arg is a name not an object
       my $name = ucfirst(lc(shift @arg)); # My convention is $CTAB{Grey} etc...
       barf "$name is not a standard colour table" unless defined $CTAB{$name};
       unshift @arg, @{$CTAB{$name}};
    }
    if ($#arg<0 || $#arg>5) {
       my @std = keys %CTAB;
       barf <<"EOD";
Usage: ctab ( \$name, [\$contrast, $\brightness] ) # Builtin col table
            [Builtins: @std]
       ctab ( \$ctab, [\$contrast, \$brightness] ) # $ctab is Nx4 array
       ctab ( \$levels, \$red, \$green, \$blue, [\$contrast, \$brightness] )
EOD
    }

    my($ctab, $levels, $red, $green, $blue, $contrast, $brightness, @t, $n);

    if ($#arg<3) { 
       ($ctab, $contrast, $brightness) = @arg;
       @t = $ctab->dims; barf 'Must be a Nx4 array' if $#t != 1 || $t[1] != 4;
       $n = $t[0];
       $ctab   = float($ctab) if $ctab->get_datatype != $PDL_F;
       my $nn = $n-1;
       $levels = $ctab->slice("0:$nn,0:0");
       $red    = $ctab->slice("0:$nn,1:1");
       $green  = $ctab->slice("0:$nn,2:2");
       $blue   = $ctab->slice("0:$nn,3:3");
    }
    else {
       ($levels, $red, $green, $blue, $contrast, $brightness) = @arg;
       checkarg($levels,1);  $n = nelem($levels);
       for($red,$green,$blue) {
          checkarg($_,1); barf 'Arguments must have same size' unless nelem($_) == $n;
       } 
    }
          
    # Now load it

    $contrast   = 1   unless defined $contrast;
    $brightness = 0.5 unless defined $brightness;
    initdev();
    pgctab( $levels->get_dataref, $red->get_dataref, $green->get_dataref, $blue->get_dataref,
                      $n, $contrast, $brightness );
    $CTAB = 1; # Loaded
1;}

# display an image using pghi2d()

sub hi2d {
    barf 'Usage: hi2d ( $image, [$x, $ioff, $bias] )' if $#_<0 || $#_>3;
    my ($image, $x, $ioff, $bias) = @_;
    checkarg($image,2);
    my($nx,$ny) = $image->dims;

    if (defined($x)) {
       checkarg($x,1);
       barf '$x incorrect' if nelem($x)!=$nx;
    }else{
       $x = float(sequence($nx));
    }
    $ioff = 1 unless defined $ioff;
    $bias = 5*max($image)/$ny unless defined $bias;
    $work = float(zeroes($nx));
        
    initenv( 0 ,2*($nx-1), 0, 10*max($image)  ) unless $hold;
    pghi2d($image->get_dataref, $nx, $ny, 1,$nx,1,$ny, $x->get_dataref, $ioff, 
                     $bias, 1, $work->get_dataref);
1;}


# Plot a polygon with pgpoly()

sub poly {
    barf 'Usage: poly ( $x, $y )' if $#_<0 || $#_>1;
    my($x,$y) = @_;
    checkarg($x,1);
    checkarg($y,1);
    my $n = nelem($x);
    initenv( min($x), max($x), min($y), max($y) ) unless $hold;
    pgpoly($n, $x->get_dataref, $y->get_dataref);
1;}


# display a vector map of 2 images using pgvect()

sub vect {
    barf 'Usage: vect ( $a, $b, [$scale, $pos, $transform, $misval] )' if $#_<1 || $#_>5;
    my ($a, $b, $scale, $pos, $tr, $misval) = @_;
    checkarg($a,2); checkarg($b,2); 
    my($nx,$ny) = $a->dims;
    my($n1,$n2) = $b->dims;
    barf 'Dimensions of $a and $b must be the same' unless $n1==$nx && $n2==$ny;

    $scale = 0 unless defined $scale;
    $pos   = 0 unless defined $pos;

    if (defined($tr)) {
       checkarg($tr,1);
       barf '$transform incorrect' if nelem($tr)!=6;
    }else{
       $tr = float [0,1,0, 0,0,1];
    }
    $tr = CtoF77coords($tr);
        
    initenv( 0, $nx-1, 0, $ny-1  ) unless $hold;
    print "Vectoring $nx x $ny images ...\n" if $PDL::verbose;
    
    pgvect( $a->get_dataref, $b->get_dataref, $nx,$ny,1,$nx,1,$ny, $scale, $pos, 
                        $tr->get_dataref, $misval);
1;}

1;# Exit with OK status


