=head1 NAME

PDL::LiteF - minimum PDL module function loader

=head1 DESCRIPTION

Loads the smallest possible set of modules for
PDL to work, making the functions available in
the current namespace. If you want something even
smaller see the C<PDL::Lite> module.

=head1 SYNOPSIS

 use PDL::LiteF; # Is equivalent to the following:

   use PDL::Core;
   use PDL::Ops;
   use PDL::Primitive;
   use PDL::Basic;
   use PDL::Slices;
   use PDL::Version;

=cut

# Load the fundamental PDL packages, with imports

sub PDL::LiteF::import {

my $pkg = (caller())[0];
eval <<EOD;

package $pkg;

use PDL::Core;
use PDL::Ops;
use PDL::Primitive;
use PDL::Basic;
use PDL::Slices;
use PDL::Version;

EOD

die $@ if $@;

}

;# Exit with OK status

1;