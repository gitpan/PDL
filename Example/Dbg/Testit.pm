package Testit;
use PDL;
use PDL::Dbg;

sub tfunc {
  $pdlin = shift;
  my $pdl = $pdlin;
  $pdltmp = $pdlin->dummy(0,5)->float;

  vars;
}
1;
