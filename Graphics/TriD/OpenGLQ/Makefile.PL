BEGIN {
  $skip = 0;
  if ($^O =~ /win32/i) {
    warn "Win32 systems not yet supported. Will not build PDL::Graphics::OpenGLQ";
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

goto SKIP if $skip;
use ExtUtils::MakeMaker;

 PDL::Core::Dev->import();

@pack = (["openglq.pd",OpenGLQ,PDL::Graphics::OpenGLQ]);
%hash = pdlpp_stdargs_int(@::pack);
foreach (@{$hash{LIBS}}) {
	$_ .= ' '.$PDL_CONFIG{OPENGL_LIBS};
}
$hash{DEFINE} .= ' '.$PDL_CONFIG{OPENGL_DEFINE};
$hash{INC} .= ' '.$PDL_CONFIG{OPENGL_INC};
WriteMakefile(%hash);

sub MY::postamble {
	pdlpp_postamble_int(@::pack);
}  # Add genpp rule

SKIP: return;
