use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'PDL',
	VERSION_FROM => '../Basic/Core/Version.pm',
	Dir => [qw/PG TriD/]
);
