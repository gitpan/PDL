use ExtUtils::MakeMaker;

WriteMakefile(
 'NAME'	        => 'PDL',
  MAN3PODS => {
      "PDL.pod" => "\$(INST_MAN3DIR)/PDL.\$(MAN3EXT)",
      map {/^([a-zA-Z]+)\.pod$/ or die "Couldn't parse $_\n";
           my $var = $1;
      	   $var eq "PP" and  ()
		or 
	    ("$var.pod" => "\$(INST_MAN3DIR)/PDL::$var.\$(MAN3EXT)")} 
	   <*.pod>
      },
);
