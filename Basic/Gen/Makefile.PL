use ExtUtils::MakeMaker;
WriteMakefile(NAME => "PDL::PP",
	PM => {
	 map {($_ => '$(INST_LIBDIR)/'.$_)}
	 	<*.pm>, <PP/*.pm>, 'PP/Dump.pm'
	},
	clean => {FILES => "PP/Dump.pm PP/Dump.pm.tmp"}
);

sub MY::postamble {
'PP/Dump.pm: PP/dump.pp
	\$(PERL) PP/dump.pp > PP/Dump.pm.tmp
	mv PP/Dump.pm.tmp PP/Dump.pm
'
}
