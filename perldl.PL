use Config;
use File::Basename qw(&basename &dirname);

# List explicitly here the variables you want Configure to
# generate.  Metaconfig only looks for shell variables, so you
# have to mention them as if they were shell variables, not
# %Config entries.  Thus you write
#  $startperl
# to ensure Configure will look for $Config{startperl}.

# This forces PL files to create target in same directory as PL file.
# This is so that make depend always knows where to find PL derivatives.
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//;
$file =~ s/\.pl$//
        if ($^O eq 'VMS' or $^O eq 'os2');  # "case-forgiving"

unlink $file if -f $file;
open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

# In this section, perl variables will be expanded during extraction.
# You can use $Config{...} to use Configure variables.

print OUT <<"!GROK!THIS!";
$Config{'startperl'}
    eval 'exec perl -S \$0 "\$@"'
        if 0;
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

##########################################################################
# Here starts the actual script

# Simple shell for PDL 

use vars qw($VERSION $PERLDL_ESCAPE $PERLDL_PROMPT $PERLDL_PAGE 
	$PERLDL_PAGING $HOME $Modules);    

$VERSION = 1.29; print "perlDL shell v$VERSION
 PDL comes with ABSOLUTELY NO WARRANTY. For details, see the file
 'COPYING' in the PDL distribution. This is free software and you
 are welcome to redistribute it under certain conditions, see
 the same file for details.\n";

# Useful shell variables

$PERLDL_ESCAPE = '#'; # Default shell escape
$PERLDL_PROMPT = "perldl> ";
$PERLDL_PAGE = 0;
$PERLDL_PAGING = 0;
$HOME = $ENV{HOME}; # Useful in shell
$,=" "; # Default

$Modules = $Modules = "";	# pacify -w

# Parse ARGV

while(defined($_ = shift @ARGV)) {
	if($_ eq "-tk") {
		print "Using Tk";
		eval "use Tk;";
                if ($@ eq "") {
                   print " v$Tk::VERSION\n"
                      if defined $Tk::VERSION; # make -w happy
                } else {
                   print ", sorry can't load module Tk\n";
                }
		next;
	} elsif(/^-f(.*)/) {
		my $file = $1;
		if(0 == length $1) {
			$file = shift @ARGV;
		}
		print "Doing '$file'\n";
		do $file;
		if($@) {
			die "Initialization error: $@";
		}
		next;
	}
	die("Unknown argument $_");
}

eval "use Term::ReadLine"; 
my $readlines = ($@ eq "");

print "ReadLines enabled" if $readlines;

print "\n";

my($term);
if ( $readlines ){
    $term = new Term::ReadLine 'perlDL', \*STDIN, \*STDOUT ;
    if(defined &Tk::DoOneEvent) {
    	# Attempt to use with Tk
        if(${$term->Features}{tkRunning}) {
		print "Using Tk event loop\n";
		$term->tkRunning(1);
	} else {
		warn("Sorry, cannot use Tk with this version of ReadLine\n");
	}
    }
    if ( ( -e "$HOME/.perldl_hist" ) 
	&& ( open HIST, "<$HOME/.perldl_hist" ) ) {
	my @allhist = <HIST>;
	close HIST;
	map s/\n//g , @allhist ;
	foreach (@allhist) {
	    $term->addhistory($_);
	}
    }
    eval <<'EOEND';
sub END {

    # Save History in $ENV{'HOME'}/.perldl_hist
    # GetHistory doesn't work on all versions...
    my @a= $term->GetHistory() if $term->can('GetHistory');

    $#a-- if $a[-1] =~ /^(q$|x$|\s*exit\b)/; # chop off the exit command
    @a= @a[($#a-50)..($#a)] if $#a > 50 ;
    if( open HIST, ">$HOME/.perldl_hist" ) { 
	print HIST join("\n",@a);
	close HIST;
    } else {
	print " Unable to open \"~/.perldl_hist\"\n";
    }
}
EOEND
}

sub l { 
  if ($readlines) {
    my $n = $#_ > -1 ? shift : 20;
    my @h = $term->GetHistory();
    my $min = $#h < $n-1 ? 0 : $#h-$n+1; 
    map {print "$_: $h[$_]\n"} ($min..$#h);
  } 
}

sub page {
  $PERLDL_PAGE = (defined $_[0] ? $_[0] : 1);
}
sub nopage {
  page(0);
}
sub startpage {
  if ($PERLDL_PAGE) {
    open(SAVEOUT, '>&STDOUT');
    open(STDOUT, "| more");
    $PERLDL_PAGING = 1;
  }
}
sub endpage {
  if ($PERLDL_PAGING) {
    close(STDOUT);
    open(STDOUT, '>&SAVEOUT');
    $PERLDL_PAGING = 0;
  }
}

# Global and local startup

my $startup_file = -e "$HOME/.perldlrc" ? "$HOME/.perldlrc" : "PDL/default.perldlrc";

print "Reading $startup_file...\n";
   
eval 'require "'.$startup_file.'"';
my $PDL_OK = ($@ eq "");
 
if ($PDL_OK) {
   require PDL::Version if not defined $PDL::Version::VERSION;
   print "Type 'demo' for online demos\n";
   print "Loaded PDL v$PDL::Version::VERSION\n";
}else{
   warn "WARNING: Error loading PDL: '$@' - trying blib. \n";
   eval "use blib";
   eval 'require "'.$startup_file.'"';
   $PDL_OK = ($@ eq "");
   if ($PDL_OK) {
      require PDL::Version if not defined $PDL::Version::VERSION;
      print "Loaded PDL v$PDL::Version::VERSION\n";
   }else{
      warn "WARNING: PDL startup not found only plain perl available\n";
   }
}

if (-e 'local.perldlrc') {
    print "Reading local.perldlrc ...\n";
    require 'local.perldlrc' ;
}

$SIG{'INT'} = sub {print "Ctrl-C detected\n"; goto restart}; # Ctrl-C handler
  
$|=1; my ($sep,$code,$mess);
while(1) {

restart:

     $sep = $,; $,=""; # Save

     if ($readlines) {
         $_ = $term->readline($PERLDL_PROMPT);
     }else{
         print $PERLDL_PROMPT; $_ = <>;
     }
     $,=$sep; #Restore 

     if(!defined $_ || lc $_ eq 'q' || lc $_ eq 'x') {exit};
     next if /^\s*$/; # Blank line - do nothing
     
     s/^\s*\?\?\s*/apropos /; # Make '??' = 'apropos'
     s/^\s*\?\s*/help /; # Make lone '?' = 'help'
	     
     if (/^\s*(help|usage|apropos|sig|demo)\s+/) { # Allow help foo (no quotes)
        @t = split;
        foreach (@t) { s/^["']+//; s/['"]+$//; };
	$t[1] = "'".$t[1]."'" if ($#t == 1 && !($t[1] =~ /^\$/));
	$_ = join(' ',@t);
     }	   

     if (substr($_,0,1) eq substr($PERLDL_ESCAPE,0,1)) { 
        system(substr($_,1)); # Shell escape
        next;
     }else{
	startpage;
        if ($PDL_OK) {
            $code = eval <<"EOD";  # Create code ref
sub {
   $_;
}
EOD
	    %@ = (); # Workaround to prevent spurious loss of $@
            PDL::Core::myeval( $code ); # Do command with $@ keeping
        }else{
            eval $_;
        }
	endpage;
     }
     if ($@) {
         $mess = $@; 

         # Remove surplus parts

         $mess =~ s/^\s*\(in cleanup\)\s+//;   # 'cleanup ...' from Usage:...
         $mess =~ s/\n\s*\(in cleanup\).*$//;  # 'cleanup...'s at end
         $mess =~ s/\s+at \(eval \d+\) line \d+\.?$//; # at eval ?? line ??.

         warn $mess;  # Report error
     }else{
         print "\n";
     }
}


# Short hand for some stuff

sub p { local $^W=0; print(@_); }  # suppress possible undefined var message (dirty)

sub demo {
	local $_ = lc $_[0] ;
	require PDL::Demos::Screen; # Get the routines for screen demos.
	if(/^$/) {
		print <<EOD;
Use:
	demo pdl	# general demo
	demo 3d		# 3d demo (requires TriD compiled with OpenGL or Mesa)
			# as well as an X display properly set up. 
	demo 3d2	# 3d demo, second part. This is very memory-heavy, make
			# your window fairly small.
	demo 3dgal      # the 3D gallery: generate interesting images with
	                # *very* concise PDL scripts
EOD
	} elsif(/^pdl$/) {
		require PDL::Demos::General;
		PDL::Demos::General::run();
	} elsif(/^3d$/) {
		require PDL::Demos::TriD1;
		PDL::Demos::TriD1::run();
	} elsif(/^3d2$/) {
		require PDL::Demos::TriD2;
		PDL::Demos::TriD2::run();
	} elsif(/^3dgal$/) {
		require PDL::Demos::TriDGallery;
		PDL::Demos::TriDGallery::run();
	} else {
		print "No such demo!\n";
	}	
}

__END__

=head1 NAME

perldl - Simple shell for PDL

=head1 SYNOPSIS

	%> perldl
	perldl> $a=sequence(10) # or any other PDL command

=head1 DESCRIPTION

The program B<perldl> is a simple shell (written in perl) for
interactive use of PDL.  perl/PDL commands can simply be typed in - and
edited if you have appropriate version of the ReadLines and ReadKeys
modules installed. In that case B<perldl> also supports a history
mechanism where the last 50 commands are always stored in the file
F<.perldl_hist> in your home directory between sessions. The command 
C<l [number]> shows you the last C<number> commands you typed where
C<number> defaults to 20.

e.g.:

   % perldl
   ReadLines enabled
   perldl> $a = rfits "foo.fits"
   BITPIX =  -32  size = 88504 pixels 
   Reading  354016 bytes
   BSCALE =  &&  BZERO = 
   
   perldl> imag log($a+400)
   Displaying 299 x 296 image from 4.6939525604248 to 9.67116928100586 ...


Miscellaneous shell features:

=over 4

=item 1. 

The shell aliases C<p> to be a convenient short form of C<print>, e.g.

   perldl> p ones 5,3
    
   [
    [1 1 1 1 1]
    [1 1 1 1 1]
    [1 1 1 1 1]
   ]
   
'q' and 'x' are short-hand for quit.

'l' lists the history buffer

'?' is an alias for help

'help', 'apropos', 'usage' and 'sig': all words after these commands are
used verbatim and not evaluated by perl. So you can write, e.g.,

    help help

instead of

    help 'help'


=item 2. 

If the file F<~/.perldlrc> is found it is sourced at start-up to load default
modules, set shell variables, etc. If it is NOT found the distribution file 
F<PDL/default.perldlrc> is read instead. This loads various modules
considered useful by default, and which ensure compatibility with
v1.11. If you don't like this and want a more streamlined set of your
own favourite modules simple create your own F<~/.perldlrc>

To set even more local defaults the file  F<local.perldlrc> (in the current
directory) is sourced if found. This lets you load modules and define
subroutines for the project in the current directory.

The name is chosen specfically because it was found hidden files were 
NOT wanted in this circumstances.

=item 3. 

Shell variables: (if you don't like the defaults change them in F<~/.perldlrc>

$PERLDL_ESCAPE  - default value '#'

Any line starting with this character is treated as a shell
escape. The default value is chosen because it escapes the
code from the standard perl interpreter.

$PERLDL_PROMPT - default value 'perldl> '

Enough said

$HOME

The users home directory

=item 4.

A useful idiom for developing perldl scripts or editing functions
on-line is

      perldl> # emacs script &
		      -- add perldl code to script and save the file
      perldl> do 'script'

-- substitute your favourite window-based editor for 'emacs' (you may
also need to change the '&' on non-Unix systems).  

Running "do 'script'" again updates any variables and function
definitions from the current version of 'script'.

=back

=head2 Command-line options

=over 4

=item -tk

Load Tk when starting the shell (the perl Tk module, which is
available from CPAN must be installed). This enables readline
event loop processing.

=item -f file

Loads the file before processing any user input. Any errors
during the execution of the file are fatal.

=cut

!NO!SUBS!

close OUT;
chmod 0555, $file;
