
# Makefile.PL for PDL::Ops module.

# Use this as a template for the Makefile.PL for
# any external PDL module.

use ExtUtils::MakeMaker;

PDL::Core::Dev->import();

@pack = (["pcarout.pd",PCARout,PDL::Lib::PCARout]);

WriteMakefile(
	pdlpp_stdargs_int(@::pack)
	);

sub MY::postamble {
	pdlpp_postamble_int(@::pack);
}
