
# Makefile.PL for PDL::Examples module.

# Use this as a template for the Makefile.PL for
# any external PDL module.
BEGIN {

  $karmabase = "/usr/local/karma";
  $karmabase = $ENV{KARMABASE} if -d $ENV{KARMABASE};
  $karmabase = $PDL_CONFIG{WHERE_KARMA} if defined $PDL_CONFIG{WHERE_KARMA};

  if (defined $PDL_CONFIG{WITH_KARMA}) {
     $withkarma = $PDL_CONFIG{WITH_KARMA};
  }
  else { # Build Karma if can find it
     if (-d $karmabase) {
        $withkarma = 1; print "\n         Seen $karmabase\n";
     }
  }

  if ($withkarma) {
  
     print "\n         Building Karma extension.  Turn off WITH_KARMA if there are problem\n\n";
  }
  else{
    print "\n      Not building PDL::Graphics::Karma, turn on WITH_KARMA if this is incorrect\n\n";
    open(OUT,">Makefile");
    print OUT "fred:\n";
    print OUT "\t\@echo \n";
    print OUT "\t\@echo \"      \" Not building PDL::Graphics::Karma, turn on WITH_KARMA if this is incorrect\n";
    print OUT "\t\@echo \n";
    print OUT "\nall: fred\n";
    print OUT "\ntest: fred\n";
    print OUT "\nclean: fred
	-mv Makefile Makefile.old

realclean :
	rm -rf Makefile Makefile.old
\n";
    close(OUT);
  }
  
  
}

return if not $withkarma;


use ExtUtils::MakeMaker;
#use PDL::Core::Dev;
PDL::Core::Dev->import();

@pack = (["karma.pd",Karma,PDL::Graphics::Karma]);

%hash = pdlpp_stdargs(@::pack);
$hash{INC}         .= " -I$karmabase/include";
$hash{LIBS}[0]     .=' -L'. $karmabase."/lib" .' -lkarma';
# change here approriately for other platforms !
if ($^O =~ 'irix' or $^O eq 'dec_osf') { $rflag = '-rpath ' } else { $rflag = '-R' }
$hash{dynamic_lib} = { OTHERLDFLAGS => $rflag.'/usr/local/karma/lib'};
$hash{'dist'}      = { COMPRESS => 'gzip', SUFFIX => 'gz'};
WriteMakefile(%hash);

# Add genpp rule
sub MY::postamble { pdlpp_postamble(@::pack); }  

