use blib;
use Carp;

$SIG{__DIE__} = sub {die Carp::longmess(@_);};

use PDL;
use PDL::OO;
use PDL::TriD;
use PDL::TriD::GL; # Choose which display you want.

# Calculate some random function

print "START\n";

# $f = zeroes(10,10);

# $foo = cos(xvals($f)/1.5) * cos(yvals($f)/1.5)/2;
$t = 0.1 * xvals zeroes 300;

$x = sin($t * 0.1);
$y = cos($t * 0.27);
$z = cos($t * 0.56);

line3d($x,$y,$z);

 $f = zeroes(3,3);
$foo = ((xvals $f) - 2) ** 2 + ((yvals $f) -2) ** 2;

print $foo;

print "TOIMAG\n";
		
PDL::TriD::imag3d($foo);	# Use default values to make a 3D plot.
		# Stops here for rotating until user presses 'q'.


