BEGIN {
  $skip = 0;
  if ($^O =~ /win32/i) {
    warn "Win32 systems not yet supported. Will not build PDL::Graphics::OpenGL";
    open(OUT,">Makefile");
    print OUT "fred:\n";
    print OUT "\t\@echo \n";
    print OUT "\t\@echo $msg\n";
    print OUT "\t\@echo \n";
    print OUT "\nall: fred\n";
    print OUT "\ntest: fred\n";
    close(OUT);
    $skip=1;
  }
}

# Makefile.PL for PDL::Graphics::OpenGL module.

# Use this as a template for the Makefile.PL for
# any external PDL module.

goto SKIP if $skip;
use ExtUtils::MakeMaker;

# Add several possible places for -L. 

WriteMakefile(
	NAME => 'PDL::Graphics::OpenGL',
	VERSION => '0.5',
    LIBS      => $PDL_CONFIG{OPENGL_LIBS},
    DEFINE => $PDL_CONFIG{OPENGL_DEFINE},
    INC => $PDL_CONFIG{OPENGL_INC},
);

#
#      ['-L/usr/X11R6/lib -L/usr/lib/mesa/ -lGL -lGLU -lMesaGL -lMesaGLU -lXext -lX11 '],
#

SKIP: return;

