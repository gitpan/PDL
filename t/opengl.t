# -*-perl-*-
BEGIN{
	  # Set perl to not try to resolve all symbols at startup
	  #   The default behavior causes some problems because 
	  #    opengl.pd builds an interface for all functions
	  #    defined in gl.h and glu.h even though they might not
	  #    actually be in the opengl libraries.
	  $ENV{'PERL_DL_NONLAZY'}=0;
}

# use PDL::Graphics::OpenGL;

sub hasDISPLAY {
  return defined $ENV{DISPLAY} && $ENV{DISPLAY} !~ /^\s*$/;
}

use Test;

BEGIN { 
   use PDL::Config;
   if ( $PDL::Config{USE_POGL} ) {
      if ( hasDISPLAY ) {
         plan tests => 4;
         eval 'use OpenGL 0.58_007 qw(:all)';
         ok($@, ''); 
         eval 'use PDL::Graphics::OpenGL::Perl::OpenGL';
         ok($@, ''); 
      } else {  # no DISPLAY
         plan tests => 2;
         eval 'use OpenGL 0.58_007 qw(:all)';
         ok($@, ''); 
         eval 'use PDL::Graphics::OpenGL::Perl::OpenGL';
         ok($@, ''); 
         exit;
      }
   } else {
      if( $PDL::Config{OPENGL_LIBS} && $PDL::Config{WITH_3D} 
         # only if GL modules have actually been built
         && $PDL::Config{GL_BUILD} && hasDISPLAY()) {
         plan tests => 3; 
         eval 'use PDL::Graphics::OpenGL';
         ok($@, ''); 
      }else{
         plan tests => 1; 
         print hasDISPLAY() ? "ok 1 # Skipped: OpenGL support not compiled\n"
         : "ok 1 # Skipped: DISPLAY environment variable not set\n";
         exit;
      }
   }
}

#
# Try opening 2 GL windows
#
my $numwins = 2;
my @windows;
my $opt;
$opt->{width} = 90;
$opt->{height} = 90;

foreach(0..$numwins-1){
  $opt->{x} = ($numwins % 10) *100;
  $opt->{y} = int($numwins / 10) *100;
  my $win=new PDL::Graphics::OpenGL::OO($opt);
  ok(ref($win), 'PDL::Graphics::OpenGL::OO');
  push @windows, $win;
}
exit;
