
# Makefile.PL for PDL::Primitive module.

# Use this as a template for the Makefile.PL for
# any external PDL module.

use ExtUtils::MakeMaker;

PDL::Core::Dev->import();

@pack = (["slatec.pd",Slatec,PDL::Slatec]);
@slatecfiles = map {s/^slatec\///; s/\.f$//; $_} <slatec/*.f>;

%hash = pdlpp_stdargs_int(@::pack);

$hash{OBJECT} .= join '', map {" slatec/$_.o "} @slatecfiles;

$hash{LIBS}[0] .= "-lf2c -lm -L/usr/lib/gcc-lib/i486-linux/2.7.2.1 -lgcc";

WriteMakefile(
 %hash,
 VERSION => "0.10_0",
);

sub MY::postamble {
	my $orig = pdlpp_postamble_int(@::pack);
	$orig =~ s/:\s*slatec\.pd/: slatec.pd SlatecProtos.h/;
	$orig .
'

SlatecProtos.h: '.(join ' ',map {"slatec/$_.P"} @slatecfiles).'
	cat '.(join ' ',map {"slatec/$_.P"} @slatecfiles).' > SlatecProtos.h

'.join "\n",map {
"

slatec/$_.c slatec/$_.P: slatec/$_.f
	f2c -A -P -dslatec slatec/$_.f

slatec/$_.o: slatec/$_.c
	cc -g -c -o slatec/$_.o -Wall slatec/$_.c

"} @slatecfiles;
 
}
