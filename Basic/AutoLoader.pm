
=head1 NAME

PDL::AutoLoader -  MatLab style AutoLoader for PDL

=head1 SYNOPSIS

   use PDL::AutoLoader;
   $a = func1(...);   # Load file func1.pdl
   $b = func2(...);   # Load file func2.pdl

=head1 DESCRIPTION

This module implements a MatLab style AutoLoader for PDL. If a unknown
function 'func()' is called then a file 'func.pdl' is searched for and
if found is read in to define 'func()' which is then executed.

Files are seached for using the directories in seach path @PDLLIB, which
is initialised from the shell environment variable PDLLIB which is a
colon seperated list of directories.

e.g. in csh

setenv PDLLIB "/home/kgb/pdllib:/local/pdllib"

Sample file:


=head1 AUTHOR

Copyright(C) 1997 Karl Glazebrook (kgb@aaoepp.aao.gov.au). 
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL 
distribution. If this file is separated from the PDL distribution, 
the copyright notice should be included in the file.


=cut


BEGIN{ @PDLLIB = (".",split(':',$ENV{"PDLLIB"})) if defined $ENV{"PDLLIB"} } 

sub PDL::AutoLoader::import {

my $pkg = (caller())[0];
my $toeval = "package $pkg;";

$toeval .= <<'EOD';

sub AUTOLOAD { 
    local @INC = @INC;
    $AUTOLOAD =~ /::([^:]*)$/;
    my $func = $1;
    
    # Trap spurious calls from 'use UnknownModule'
    
    goto &$AUTOLOAD if ord($func)==0; 
    
    unshift @INC, @PDLLIB;
    print "Loading $func.pdl...\n" if $PDL::verbose;
    eval {require "$func.pdl"};
    goto &$AUTOLOAD unless $@;
    die "PDL autoloader: Undefined subroutine $func() cannot be AutoLoaded\n";
}

EOD

eval $toeval;

}

;# Exit with OK status

1;
