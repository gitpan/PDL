
# Makefile.PL for PDL::Io module.

# Use this as a template for the Makefile.PL for
# any external PDL module.

use ExtUtils::MakeMaker;

# Replace this wit:e 
PDL::Core::Dev->import();

@pack = (["io.pd",Misc,PDL::Io::Misc]);

WriteMakefile(
 pdlpp_stdargs_int(@::pack)
);

sub MY::postamble {
	pdlpp_postamble_int(@::pack);
}  # Add genpp rule
