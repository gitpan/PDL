# Copyright (C) 1998 Tuomas J. Lukka.
# All rights reserved, except redistribution
# with PDL under the PDL License permitted.

package PDL::Demos::TriDGallery;

use PDL;
use PDL::Graphics::TriD;
use PDL::Graphics::TriD::Image;

PDL::Demos::Routines->import();
sub comment($);
sub act($);
sub actnw($);
sub output;

sub run {


comment q|
	Welcome to the TriD Gallery

	The following selection of scripts demonstrates that you
	can generate  interesting images with PDL (and the TriD
	modules) with just a few lines of code.

	These are the rules for scripts to be accepted for this
	category:


        1) Must be legal Perl with a recent PDL version - may come with
           a patch to PDL if the patch is general enough to be included
           in the next release and usable outside the demo (e.g.
           $x=mandelbrot($c) is NOT), i.e. you can introduce new
           commands

        2) The code must fit in 4 lines, 72 columns.

        3) It must create an interesting image when fed to perl.

        If you have an interesting new TriD M4LS (Maximal-4-lines-script)
        submit it to the PDL mailing list (perldl@jach.hawaii.edu)
        and there is a good chance it will soon be included in the gallery

	Press 'q' in the graphics window for the next screen.
	Rotate the image by pressing mouse button one and 
	dragging in the graphics window.
	Zoom in/out by pressing MB3 and drag up/down.
|;

actnw q|
# B/W Mandelbrot... [Tjl]

use PDL; use PDL::Graphics::TriD;
$s=150;$a=zeroes $s,$s;$r=$a->xlinvals(-1.5,0.5);$i=$a->ylinvals(-1,1);
$t=$r;$u=$i;for(0..12){$q=$r**2-$i**2+$t;$h=2*$r*$i+$u;($r,$i)=map{$_->
clip(-5,5)}($q,$h);}imagrgb[($r**2+$i**2)>2.0];

# [press 'q' in the graphics window when done]
|;

if(0) {
actnw q|
# Greyscale Mandelbrot [Tjl]

use PDL; use PDL::Graphics::TriD;$a=zeroes 300,300;$r=$a->xlinvals(-1.5,
0.5);$i=$a->ylinvals(-1,1);$t=$r;$u=$i;for(1..30){$q=$r**2-$i**2+$t;$h=2
*$r*$i+$u;$d=$r**2+$i**2;$a=lclip($a,$_*($d>2.0)*($a==0));($r,$i)=map{$_
->clip(-5,5)}($q,$h);}imagrgb[$a/30];

# [press 'q' in the graphics window when done]
|;

actnw q|
# Color Mandelbrot anim (nokeeptwiddling3d removed -> fits) [Tjl]

use PDL; use PDL::Graphics::TriD;
nokeeptwiddling3d();
$a=zeroes 300,300;$r=$a->xlinvals(-1.5,
0.5);$i=$a->ylinvals(-1,1);$t=$r;$u=$i;for(1..30){$q=$r**2-$i**2+$t;$h=2
*$r*$i+$u;$d=$r**2+$i**2;$a=lclip($a,$_*($d>2.0)*($a==0));($r,$i)=map{$_
->clip(-5,5)}$q,$h;imagrgb[($a==0)*($r/2+0.75),($a==0)*($i+1)/2,$a/30]}

# [press 'q' in the graphics window when done]
|;
}


actnw q|
# Torus... (barrel) [Tjl]

use PDL; use PDL::Graphics::TriD;
$s=40;$a=zeroes $s,$s;$t=$a->xlinvals(0,6.284);
$u=$a->ylinvals(0,6.284);$o=5;$i=1;$v=$o+$i*sin$u;
imag3d([$v*sin$t,$v*cos$t,$i*cos$u]);
|;

actnw q|
# Ripply torus [Tjl]

use PDL; use PDL::Graphics::TriD;
$s=40;$a=zeroes 2*$s,$s/2;$t=$a->xlinvals(0,6.284);
$u=$a->ylinvals(0,6.284); $o=5;$i=1;$v=$o+$i*sin$u;
imag3d([$v*sin$t,$v*cos$t,$i*cos($u)+$o*sin(3*$t)]);
|;

actnw q|
# Ripply torus distorted [Tjl]

use PDL; use PDL::Graphics::TriD;
$s=40;$a=zeroes 2*$s,$s/2;$t=$a->xlinvals(0,6.284);$u=$a->ylinvals(0,
6.284); $o=5;$i=1;$v=$o-$o/2*sin(3*$t)+$i*sin$u;
imag3d([$v*sin$t,$v*cos$t,$i*cos($u)+$o*sin(3*$t)]);
|;

actnw q%
# Game of life [Robin Williams (edited by Tjl)]

use PDL; use PDL::Image2D; use PDL::Graphics::TriD;nokeeptwiddling3d;
$d=byte(random(zeroes(40,40))>0.85);$k=byte [[1,1,1],[1,0,1],[1,1,1]];
$s=null; do{ imagrgb [$d]; $s=conv2d($d,$k);
$d&=($s<4);$d&=($s>1);$d|=($s==3);} while (!twiddle3d);
%;

comment q|
	We hope you did like that and got a feeling of
        the power of PDL.

        Now it's up to you to submit even better TriD M4LSs.

|;

}

# Neat, but too big variation of color mandelbrot
if(0) {

use PDL; use PDL::Graphics::TriD;
nokeeptwiddling3d();
sub f {return abs(sin($_[0]*30))}
$a=zeroes 300,300;$r=$a->xlinvals(-1.5,
0.5);$i=$a->ylinvals(-1,1);$t=$r;$u=$i;for(1..30){$q=$r**2-$i**2+$t;$h=2
*$r*$i+$u;$d=$r**2+$i**2;$a=lclip($a,$_*($d>2.0)*($a==0));($r,$i)=map{$_
->clip(-5,5)}$q,$h;imagrgb[f(($a==0)*($r/2+0.75)),f(($a==0)*($i+1)/2),$a/30]}

}

1;
