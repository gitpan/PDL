
=head1 NAME

PDL::AutoLoader -  MatLab style AutoLoader for PDL

=head1 SYNOPSIS

   use PDL::AutoLoader;
   $a = func1(...);   # Load file func1.pdl
   $b = func2(...);   # Load file func2.pdl

   $PDL::AutoLoader::Rescan = 1; # Enable re-scanning

=head1 DESCRIPTION

This module implements a MatLab style AutoLoader for PDL. If a unknown
function 'func()' is called then a file 'func.pdl' is searched for and
if found is read in to define 'func()' which is then executed.

Files are seached for using the directories in seach path @PDLLIB, which
is initialised from the shell environment variable PDLLIB which is a
colon seperated list of directories.

e.g. in csh

setenv PDLLIB "/home/kgb/pdllib:/local/pdllib"

Note this is kept seperate from PERL5LIB just in case....

=head2 AUTO-SCANNING

The variable $PDL::AutoLoader::Rescan controls whether files
are automatically re-scanned for changes at the C<perldl> command
line.

If C<$PDL::AutoLoader::Rescan == 1> and the file is changed
then the new definition is reloaded auto-matically before
executing the C<perldl> command line. Which means in practice
you can edit files, save changes and have C<perldl> see the
changes automatically.

The default is '0' - i.e. to have this feature disabled.

As this feature is only pertinent to the C<perldl> shell it imposes
no overhead on PDL scripts. Yes Bob you can have your cake and
eat it too!

Note: files are only re-evaled if they are determined to have
been changed according to their date/time stamp.

No doubt this interface could be improved upon some more. :-)

=head2 Sample file:

 sub foo { # file 'foo.pdl' - define the 'foo' function
   my $x=shift;
   return sqrt($x**2 + $x**3 + 2);
 }
 1; # File returns true (i.e. loaded successfully)


=head1 AUTHOR

Copyright(C) 1997 Karl Glazebrook (kgb@aaoepp.aao.gov.au).
All rights reserved. There is no warranty. You are allowed
to redistribute this software / documentation under certain
conditions. For details, see the file COPYING in the PDL
distribution. If this file is separated from the PDL distribution,
the copyright notice should be included in the file.

=head1 BUGS

No doubt this interface could be improved upon some more. :-)

Will probably be quite slow if C<$PDL::AutoLoader::Rescan == 1>
and thousands of functions have been autoloaded.

There could be a race condition in which the file changes
while the internal autoloader code is being executed but it
should be harmless.

Probably has not been tested enough!

=cut

BEGIN{
  @PDLLIB = (".",split(':',$ENV{"PDLLIB"})) if defined $ENV{"PDLLIB"};
  $PDL::AutoLoader::Rescan=0;
  %PDL::AutoLoader::FileInfo = ();
}

# Code to reload stuff if changed

sub PDL::AutoLoader::reloader {
   return unless $PDL::AutoLoader::Rescan;

   # Now check functions and reload if changed

   my ($file, $old_t);
   for my $func (keys %PDL::AutoLoader::FileInfo) {
       ($file, $old_t) = @{ $PDL::AutoLoader::FileInfo{$func} };
       if ( (stat($file))[9]>$old_t ) { # Reload
          print "Reloading $file as file changed...\n" if $PDL::verbose;
          do $file;
	  $PDL::AutoLoader::FileInfo{$func} = [ $file, (stat($file))[9] ];
       }
   }
}

sub PDL::AutoLoader::import {

my $pkg = (caller())[0];
my $toeval = "package $pkg;";

$toeval .= <<'EOD';

push @PERLDL::AUTO, \&PDL::AutoLoader::reloader;

sub AUTOLOAD {
    local @INC = @INC;
    $AUTOLOAD =~ /::([^:]*)$/;
    my $func = $1;

    # Trap spurious calls from 'use UnknownModule'

    goto &$AUTOLOAD if ord($func)==0;

    print "Loading $func.pdl...\n" if $PDL::verbose;
    for my $dir (@PDLLIB) {
        my $file = $dir . "/" . "$func.pdl";
	if (-e $file) {
	   # Autoload
           do $file;

	   # Remember autoloaded functions and do some reasonably
	   # smart cacheing of file/directory change times

	   if ($PDL::AutoLoader::Rescan) {
	      $PDL::AutoLoader::FileInfo{$func} = [ $file, (stat($file))[9] ];
	   }

	   # Now go to the autoloaed function

	   goto &$AUTOLOAD unless $@;
	}
    }
    die "PDL autoloader: Undefined subroutine $func() cannot be AutoLoaded\n";
}

EOD

eval $toeval;

}

;# Exit with OK status

1;
