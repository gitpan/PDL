package PDL::Demos::PGPLOT_demo;
use PDL;

PDL::Demos::Routines->import();
sub comment($);
sub act($);
sub output;

sub run {

$ENV{PGPLOT_XW_WIDTH}=0.3;
$ENV{PGPLOT_DEV}="/XSERVE";

comment q|
    Welcome to this tour of the PDL's PGPLOT interface.

    This tour will introduce the PDL's PGPLOT plotting module and show
    what this powerful package can provide in terms of plotting. It is
    not designed to give a full tour of PGPLOT, you are advised to see
    the routines provided with pgperl for that.

    The PGPLOT module is included by default when you use PDL. However
    if you want even better control of your plots you might want to
    include the PGPLOT module specifically:

       use PGPLOT;

    One aspect of PGPLOT that requires mention is the use of devices:
    Normally PGPLOT will inquire you about what device you want to use,
    with the prompt:

        Graphics device/type (? to see list, default /NULL):


|;

act q|
    # The size of the window can be specified
    $ENV{PGPLOT_XW_WIDTH}=0.3;
    # You can set your device explicitly
    dev('/XSERVE');
|;

act q|
    # First we define some variables to use for the rest of the demo.
    $x=sequence(10);
    $y=2*$x**2;

    # Now a simple plot with points
    points $x, $y;
|;

act q|
    # Here is the same with lines
    line $x, $y;
|;

act q|
    # If you want to overlay one plot you can use the command
    # 'hold' to put the graphics on hold and 'release' to
    # revert the effect

    points $x, $y, {SYMBOL=>4};  # The last argument sets symboltype
    hold;
    # Now draw lines between the points
    line $x, $y;
    # Plot errorbars over the points
    $yerr=sqrt($y);
    errb $x, $y, $yerr;

    # To revert to old behaviour, use release
    release;
|;

act q|
    bin $x, $y;

    # This plots a binned histogram of the data and as you can
    # see it made a new plot.
|;

act q|
    # 2D data can also easily be accomodated:

    # First make a simple image
    $gradient=sequence(40,40);

    # Then display it.
    imag $gradient;

    # And overlay a contour plot over it:
    hold;
    cont $gradient;
    release;
|;

act q|
    # To change plot specifics you can either use the specific PGPLOT
    # commands - recommended if you need lots of control over your
    # plot.
    #
    # Or you can use the new option specifications:

    # To plot our first graph again with blue color, dashed line
    # and a thickness of 10 we can do:

    line $x, $y, {COLOR=>5, LINESTYLE=>'dashed', LINEWIDTH=>10};

|;

act q|

  # Now for a more complicated example.
  # First create some data
  $a=sequence(360)*3.1415/180.;
  $b=sin($a)*transpose(cos($a));

  # Make a piddle with the wanted contours
  $contours=pdl [0.1,0.5,1.0];
  # And an array (reference to an array) with labels
  $labels=['A', 'B', 'C'];
  # Create a contour map of the data - note that we can set the colour of
  # the labels.
  cont($b, {CONTOURS=>$contours, linest=>'DASHED',
	    LINEWIDTH=>3, COLOR=>2, LABELCOL=>4});
  hold;

  pgqlw($linewidth);

  points $a->slice('0:-1:4')*180./3.1415;
  release;
|;

act q|
  #
  # We can also create vector maps of data
  # This requires one array for the horizontal component and
  # one for the vertical component
  #
  $horizontal=sequence(10,10);
  $vertical=transpose($horizontal)+random(10,10)*$horizontal/10.;

  $arrow={ARROW=> {FS=>1, ANGLE=>25, VENT=>0.7, SIZE=>3}};
  vect $horizontal, $vertical, {ARROW=>$arrow, COLOR=>RED};
  hold;
  cont $vertical-$horizontal, {COLOR=>YELLOW};
  release;

|;

act q|
  #
  # To draw [filled] polygons, the command poly is handy:
  #

  $x=sequence(10)/5;
  poly $x, $x**2, {FILL=>HATCHED, COLOR=>BLUE};

|;

}

1;