use PDL;
use PDL::Dbg;
use PDL::Types;
use Testit;

$PDL::Debug = 1;  # make px spit out some info

sub myvarinfo {
  my $pdl = shift;
  my $dimstr = '['. join(',',$pdl->dims) .']';
  return "null" if $dimstr eq '[0]';
  my $type = $typehash{$pdl->get_datatype}->{'ctype'};
  $type =~ s/^PDL_//;

  return "$type\t$dimstr";
}


# no pdls yet
vars;

$a = pdl (1,2,3);

$b = ones(4,7,2,3,5)->float;

$c = null;

# now with some pdls
vars;

print "some output from px:\n";
$c = $b->slice(',(1),')->px->mv(0,2)->px->thread(2)->px->thread2(0,1)->px;
print $c;

# now check the 'flows' etc. access functions
$b->doflow;
$a->doflow;

print "original output:\n";
vars;


# install own handler
($ssave,$cpattern) = 
  PDL::Dbg::set_varinfo_handler(\&myvarinfo);

print "customised output (current pattern = $cpattern):\n";
vars;

# restore original handler
set_varinfo_handler($ssave);

# and test it in another package ('vars' is called in Testit::tfunc)
print "in another package:\n";
Testit::tfunc($a);

# change $b using dummy
$b = $a->slice('*5,:');
vars;

# demonstrate use with own (pdl derived) objects
print "with own objects:\n";
$d = {};
bless $d, 'MYPDL';
$$d{'PDL'} = $c;
vars('class' => '(^PDL$)|(^MYPDL$)',
     'sub' => sub { my $obj = shift;
		    if (ref($obj) =~ /MYPDL/)
		      {return 'PDL => ' . & $ssave($$obj{'PDL'});}
		    return & $ssave($obj);
		  });

# show that calling vars with arguments doesn't change any of the settings
# permanently
print "original output again:\n";
vars;

