=head1 NAME

PDL - Main loader of PDL default modules

=head1 DESCRIPTION

Loads the default set of modules associated
with PDL, making the functions available in
the current namespace. See also 
L<PDL::Lite|PDL::Lite> or L<PDL::LiteF|PDL::LiteF> 
if start-up time becomes an issue.

=head1 SYNOPSIS

 use PDL; # Is equivalent to the following:

   use PDL::Core;
   use PDL::Ops;
   use PDL::Primitive;
   use PDL::Ufunc;
   use PDL::Basic;
   use PDL::Slices;
   use PDL::Bad;
   use PDL::Version;
   use PDL::IO::Misc;
   use PDL::Lvalue;

=cut


# set the version: 
$PDL::VERSION = '2.3.2'; # delete 'cvs' bit for release !

# Main loader of standard PDL package

sub PDL::import {

my $pkg = (caller())[0];
eval <<"EOD";

package $pkg;

# Load the fundamental packages

use PDL::Core;
use PDL::Ops;
use PDL::Primitive;
use PDL::Ufunc;
use PDL::Basic;
use PDL::Slices;
use PDL::Bad;
use PDL::Lvalue;

# Load these for TPJ compatibility

use PDL::IO::Misc;          # Misc IO (Ascii/FITS)

EOD

die $@ if $@;

}


# Dummy Package PDL Statement. This is only needed so CPAN
# properly recognizes the PDL package.
package PDL;


;# Exit with OK status

1;
