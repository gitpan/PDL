use ExtUtils::MakeMaker;
WriteMakefile(NAME => "PDL::PP",
	PM => {
	 map {($_ => '$(INST_LIBDIR)/'.$_)}
	 	<*.pm>, <PP/*.pm>
	}
);
