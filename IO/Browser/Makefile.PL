if ($^O =~ /win32/i) {
  warn "Win32 systems not yet supported. Will not build PDL::IO::Browser";
  open(OUT,">Makefile");
  print OUT "fred:\n";
  print OUT "\t\@echo \n";
  print OUT "\t\@echo $msg\n";
  print OUT "\t\@echo \n";
  print OUT "\nall: fred\n";
  print OUT "\ntest: fred\n";
  close(OUT);
  return;
}
 
# Makefile.PL for PDL::IO module.
 
# Use this as a template for the Makefile.PL for
# any external PDL module.
 
use ExtUtils::MakeMaker;
 
PDL::Core::Dev->import();
 
@pack = (["browser.pd",Browser,PDL::IO::Browser]);
 
%hash = pdlpp_stdargs_int(@::pack);
push @{$hash{LIBS}} , '-lcurses';
$hash{'OBJECT'} .= ' browse$(OBJ_EXT)';
$hash{'clean'}{FILES} .= ' browse$(OBJ_EXT)';
unshift @{$hash{LIBS}} , '-lncurses'; # For some systems

WriteMakefile(%hash);
 
# Add genpp rule
sub MY::postamble { pdlpp_postamble_int(@::pack); }  
 
 
