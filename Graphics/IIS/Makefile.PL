
# Makefile.PL for PDL::Graphics::IIS module.

# Use this as a template for the Makefile.PL for
# any external PDL module.


#use PDL::Core::Dev;
PDL::Core::Dev->import();

use ExtUtils::MakeMaker;

# Replace this wit:e 

@pack = (["iis.pd",IIS,PDL::Graphics::IIS]);

WriteMakefile(
 pdlpp_stdargs_int(@::pack)
);

sub MY::postamble {
	pdlpp_postamble_int(@::pack);
}  # Add genpp rule
