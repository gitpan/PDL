#!/usr/bin/perl
#
# This tests an Inline::Pdlpp wrapper around the GSL
# linear algebra SVD routines.  The hard part is the
# conversion between piddles and the GSL vector and
# matrix datatypes.
#

## use Inline C => Config => LIBS => '-lghttp';
## use Inline C => "code ...", LIBS => '-L/your/lib/path -lyourlib';
## use Inline C => "code ...", LIBS => '-lghttp', INC => '-I/your/inc/path';
## use Inline C => DATA => LIBS => '-luser32';

use PDL; # must be called before (!) 'use Inline Pdlpp' calls
use Inline Pdlpp; # the actual code is in the __Pdlpp__ block below

$a = pdl([[1,2,1],[2,3,1],[1,0,0]]);
$v = zeros(3,3);
$s = zeros(3);

print "\$a is $a\n";
print "\$v is $v\n";
print "\$s is $s\n";

__DATA__

## __Pdlpp__
## 
## pp_def('inc',
##    Pars => 'i();[o] o()',
##    Code => '$o() = $i() + 1;',
## );
## 
## pp_def('tcumul',
##    Pars => 'in(n);[o] mul()',
##    Code => '$mul() = 1;
##    loop(n) %{
##    $mul() *= $in();
##    %}',
## );
## # end example script
## use PDL; # this must be called before (!) 'use Inline Pdlpp' calls
## 
## use Inline Pdlpp => Config =>
## INC => "-I$ENV{HOME}/include",
## LIBS => "-L$ENV{HOME}/lib -lnr -lm",
## # code to be included in the generated XS
## AUTO_INCLUDE => <<'EOINC',
##           #include <math.h>
##           #include "nr.h"    /* for poidev */
##           #include "nrutil.h"  /* for err_handler */
## 
##           static void nr_barf(char *err_txt)
##           {
##             fprintf(stderr,"Now calling croak...\n");
##             croak("NR runtime error: %s",err_txt);
##           }
##           EOINC
##           # install our error handler when loading the Inline::Pdlpp code
##           BOOT => 'set_nr_err_handler(nr_barf);';
## 
##           use Inline Pdlpp; # the actual code is in the __Pdlpp__ block below
## 
##           $a = zeroes(10) + 30;;
##           print $a->poidev(5),"\n";
## 
##           __DATA__
## 
##           __Pdlpp__
## 
##           pp_def('poidev',
##                   Pars => 'xm(); [o] pd()',
##                   GenericTypes => [L,F,D],
##                   OtherPars => 'long idum',
##                   Code => '$pd() = poidev((float) $xm(), &$COMP(idum));',
##           );
## 
