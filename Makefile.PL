
# Build the whole PDL distribtuion

$::PP_VERBOSE = 0; # =1 makes PP waffle a lot

# Version test.
BEGIN{
  eval "use 5.004";
  die "PDL requires Perl v5.004 or later\n" if $@ ne "";
}

$seen_pdlconf = 0;

# Scan ARGV for config file argument
@ARGV = map {
	if(/^PDLCONF=(.*)$/) {
		$seen_pdlconf=1;
		$pdl_conf_file = $1; ();
	} else {
		$_
	}
} @ARGV;

if(!$seen_pdlconf) {
	my $defname = "$ENV{HOME}/.perldl.conf";
	if(-e $defname) {
		$pdl_conf_file = $defname;
	}
}


# First read in distribution config file 

require './perldl.conf';

%PDL_CONFIG_DIST = %PDL_CONFIG; # Save standard values


# Now read in the users config file if specified

if (-e $pdl_conf_file) {
    warn "\nINFORMATION: using file $pdl_conf_file to set configuration defaults\n\n";
    require $pdl_conf_file;
}

# Sanity checking of user supplied keys (look for ones not defined in dist)

for(keys %PDL_CONFIG) {
	if(!exists($PDL_CONFIG_DIST{$_})) {
	   die("Invalid key $_ found in user supplied $pdl_conf_file - this key appears to be no longer in use. Please review configuration options");
	}
}

# Merge in default options where not supplied in users file

for(keys %PDL_CONFIG_DIST) {
   $PDL_CONFIG{$_} = $PDL_CONFIG_DIST{$_} unless exists $PDL_CONFIG{$_};
}

use ExtUtils::MakeMaker;

WriteMakefile(

 #'PREREQ_PM' => { 'ExtUtils::F77' => 1.03 },
 'NAME' => 'PDL',
 'VERSION_FROM' => 'Basic/Core/Version.pm',
 'EXE_FILES' => ['perldl'],
				  # If you want speed, remove this
 'linkext'  => {LINKTYPE => ''},  # No linking required in this directory
 'dist'     => { COMPRESS => 'gzip', SUFFIX => 'gz'},
 'clean' => {'FILES' => 'perldl pdldoc.db tbyte.tif tmp0 tmp0.hdr tushort.tif MANIFEST.bak tmp1* tmpraw* t/tmpraw* t/tmp1*'}
);

# Extra build target to build the doc database

sub MY::postamble {
' 
doctest :: 
	@echo "Building PDL documentation database"
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) \
		Doc/scantree.pl $(INST_LIB) $(INST_LIB)/PDL/pdldoc.db 
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) \
		Doc/mkhtmldoc.pl $(INST_LIB)/PDL $(INST_LIB)/PDL/HtmlDocs

pure_site_install ::
	@echo "Installing PDL documentation database"
	-@$(CHMOD) 755  $(INSTALLSITELIB)/PDL/pdldoc.db 
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) \
	   Doc/scantree.pl $(INSTALLSITELIB) $(INSTALLSITELIB)/PDL/pdldoc.db 
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) \
	   Doc/mkhtmldoc.pl $(INSTALLSITELIB)/PDL $(INSTALLSITELIB)/PDL/HtmlDocs

pure_perl_install ::
	@echo "Installing PDL documentation database"
	-@$(CHMOD) 755  $(INSTALLPRIVLIB)/PDL/pdldoc.db 
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) \
	   Doc/scantree.pl $(INSTALLPRIVLIB) $(INSTALLPRIVLIB)/PDL/pdldoc.db 
	@$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) \
	   Doc/mkhtmldoc.pl $(INSTALLPRIVLIB)/PDL $(INSTALLPRIVLIB)/PDL/HtmlDocs

		
'
}

sub MY::test {
        package MY; # so that "SUPER" works right
        my $inherited = shift->SUPER::test(@_);
	my @lines = split "\n", $inherited;
	my @new = ();
	my $pass = 1;
	foreach (@lines) {
		if ($pass) {
			push @new, $_;
			$pass = 0 if /^test\b/;
		} else {
			if (/^\s*$/) {
				push @new, '';
				$pass = 1;
			}
		}
	}
	return join("\n", @new,"\n");
}

