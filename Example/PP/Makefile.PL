
# Makefile.PL for PDL::Primitive module.

# Use this as a template for the Makefile.PL for
# any external PDL module.

use ExtUtils::MakeMaker;

# Use this line when using this outside Core PDL.
# require 'PDL/Core/Dev.pm'; PDL::Core::Dev->import();

PDL::Core::Dev->import();

@pack = (["primitive.pd",Primitive,PDL::Primitive]);

WriteMakefile(
 pdlpp_stdargs_int(@::pack)
);

sub MY::postamble {
	pdlpp_postamble_int(@::pack);
}  # Add genpp rule

__DATA__


WriteMakefile(
 'NAME'  	=> 'PDL::Primitive',
# 'VERSION_FROM'	=> 'PP.pm',
     'VERSION_FROM' => '../Core/Version.pm',
 'TYPEMAPS'     => [PDL_TYPEMAP], 
 'OBJECT'       => 'Primitive$(OBJ_EXT)',           
 PM 	=> {'Primitive.pm' => '$(INST_LIBDIR)/Primitive.pm'},
 'INC'          => PDL_INCLUDE,
 'LIBS'         => [''],
 'clean'        => {'FILES'  => 'Primitive.xs Primitive.pm'},
);

sub MY::postamble {
q|
Primitive.xs Primitive.pm: primitive.pd ../Core/PP.pm
	$(PERL) '-Mlib qw(../../blib/arch ../../blib/lib)' primitive.pd 
|
}  # Add genpp rule
