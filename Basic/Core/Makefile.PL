
# Makefile.PL for PDL::Core module

#require '../Core/Dev.pm'; 
PDL::Core::Dev->import();

use ExtUtils::MakeMaker;
WriteMakefile(
 'NAME'	        => 'PDL::Core',
 'VERSION_FROM' => 'Version.pm',
'OPTIMIZE' => '-g',
 'OBJECT'       => 'Core$(OBJ_EXT) pdlcore$(OBJ_EXT) pdlapi$(OBJ_EXT) '.
                   'pdlhash$(OBJ_EXT) pdlthread$(OBJ_EXT) pdlfamily$(OBJ_EXT) '.
                   'pdlconv$(OBJ_EXT)  pdlsections$(OBJ_EXT) '.
                   'pdlstats$(OBJ_EXT) pdlmoremaths$(OBJ_EXT)
		    pdlmagic$(OBJ_EXT)',
  'PM'           => {
  		(map {($_,'$(INST_LIBDIR)/'.$_)} (
			qw/Core.pm Basic.pm Version.pm Types.pm Dbg.pm/
		)),
  		(map {($_,'$(INST_LIBDIR)/Core/'.$_)} (
			qw/Dev.pm typemap.pdl pdl.h pdlcore.h pdlmagic.h 
				pdlthread.h/
		)),
		},
 'LIBS'        => [''],
 'clean'       => {'FILES'  => 'pdlcore$(OBJ_EXT) pdlapi$(OBJ_EXT) '.
                   'pdlhash$(OBJ_EXT) pdlbasicops$(OBJ_EXT) '.
                   'pdlconv$(OBJ_EXT) pdlsections$(OBJ_EXT) '.
                   'pdlstats$(OBJ_EXT) pdlmoremaths$(OBJ_EXT) pdlbasicops.c '.
                   'pdlconv.c pdlsections.c pdlstats.c pdlmoremaths.c'},
);

# Extra targets to build

sub MY::postamble {
PDL::Core::Dev::postamble().
'
# Bits of C code we generate from special perl scripts

pdlbasicops.c:  mkpdlbasicops.p 
	$(PERL) mkpdlbasicops.p > pdlbasicops.c

pdlconv.c:  mkpdlconv.p 
	$(PERL) mkpdlconv.p > pdlconv.c

';
}


