use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME' => 'PDL::Lib',
	VERSION_FROM => '../Basic/Core/Version.pm',
	Dir => [qw/Opt PCARout Slatec/]
);

