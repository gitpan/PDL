
# Build the whole PDL distribtuion

use ExtUtils::MakeMaker;

WriteMakefile(
 'NAME' => 'PDL',
 'VERSION_FROM' => 'Basic/Core/Version.pm',
 'EXE_FILES' => ['perldl'],
 'OPTIMIZE' => '-g',              # At the moment, probably better.
				  # If you want speed, remove this
 'linkext'  => {LINKTYPE => ''},  # No linking required in this directory
 'clean' => {'FILES' => 'perldl'}
);

