# Copyright (C) 1998 Tuomas J. Lukka.
# All rights reserved, except redistribution
# with PDL under the PDL License permitted.

package PDL::Demos::General;
use PDL;

PDL::Demos::Routines->import();
sub comment($);
sub act($);
sub output;

sub run {

comment q|
	Welcome to a short tour of PDL's capabilities.

	This tour shows some of the main selling points 
	of PDL. However, because we want this script to
	run everywhere, some modules which require external
	modules for use are explicitly excluded, namely
	 - Graphics::TriD (3D Graphics) [*]
	 - Graphics::PG (PGPLOT graphics) 
	 - IO::FlexRaw (flexible raw input/output)
 	[*]: this module has its separate demos in a subdirectory.

	Note that the script must start with

		use PDL; 

	to work.  Also, the command "output" is aliased to
	either "print" or whatever command is appropriate in the 
	environment you are running this demo in.
|;

act q|
	$a = zeroes 5,5; # 5x5 matrix
	output $a;
|;

act q|
	# Now, don't think that the number of dimensions is limited
	# to two:
	$m = zeroes(3,2,2); # 2x2x2 cube
	output $m;
|;

act q|
	$a ++;      # Operators like increment work..
	output $a;
|;

act q|
	# xvals and yvals (yes, there is also zvals...)
	# give you piddles which give the coordinate value.
	$b = xvals $a;
	output $b;
|;

act q|
	# So you can do things like
	$b = $a + 0.1 * xvals($a) + 0.01 * yvals($a);
	output $b;
|;

act q|
	# Arithmetic operations work:
	$x = xvals(20) / 10;
	output ((sin $x),"\n");
|;

act q|
	# You can also take slices:
	output $b;
	output $b->slice(":,2:3");
|;
act q|
	output $b->slice("2:3,:");
|;

act q|
	output $b;
	output $b->diagonal(0,1),"\n"; # 0 and 1 are the dimensions
|;

act q|
	# One of the really nifty features is that the 
	# slices are actually references back to the original
	# piddle:
	$diag = $b->diagonal(0,1);
	output $b;
	output $diag,"\n";
	$diag+=100;
	output "AFTER:\n";
	output $diag,"\n";
	output "Now, guess what \$b looks like?\n";
|;

act q|
	# Yes, it has changed:
	output $b;
|;

act q|
	# Another example:
	$t = $b->slice("0:4:2"); $t += 50;
	output $b;
|;

act q|
	# There are lots of useful functions in e.g. PDL::Primitive
	# and PDL::Slices - we can't show you all but here are some
	# examples:

	output $b; 
	output $b->sum, "\n";
	output $b->sumover,"\n"; # Only over first dim.
|;

act q|
	output $b->xchg(0,1);
	output $b->minimum,"\n"; # over first dim.
	output $b->min,"\n";
|;

act q|
	output $b->random;
|;

act q|
	# Here are some more advanced tricks for selecting
	# parts of 1-D vectors:
	$a = (xvals 12)/3;
	$i = where(sin($a) > 0.5);   # Indices of those sines > 0.5
	output $a,"\n";
	output $i,"\n";
	output $a->index($i),"\n";
	output sin($a->index($i)),"\n";

|;

}

1;
