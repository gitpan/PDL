
# Build the whole PDL distribtuion

use ExtUtils::MakeMaker;

WriteMakefile(
 'NAME' => 'PDL',
 'VERSION' => '1.04',
 'EXE_FILES' => ['perldl'],
 'linkext'  => {LINKTYPE => ''},  # No linking required in this directory
);

