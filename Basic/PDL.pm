# BEGIN{print "Loading PDL alpha test version...\n"}

# Main loader of PDL package

{ # Scope

package PDL;

} # Back to user namespace

# (do not) import all the packages

use PDL::Core;
use PDL::Ops;
use PDL::Primitive;
use PDL::Basic;
use PDL::Slices;
use PDL::Version;

# The following are optional to the user to save time.

#use PDL::Examples;
#use PDL::Io;
#use PDL::Graphics::PG;
#use PDL::Graphics::IIS;

# AutoLoading (in user scope)

@PDLLIB = (".",split(':',$ENV{"PDLLIB"})) if defined $ENV{"PDLLIB"}; 

sub AUTOLOAD { 
    local @INC = @INC;
    $AUTOLOAD =~ /::([^:]*)$/;
    my $func = $1;
    unshift @INC, @PDLLIB;
    eval {require "$func.pdl"};
    goto &$AUTOLOAD unless $@;
    die "PDL autoloader: Undefined subroutine $func() cannot be AutoLoaded\n";
}

;# Exit with OK status

# BEGIN{print "Finished loading PDL alpha test version. you're on your own.\n"}
1;
