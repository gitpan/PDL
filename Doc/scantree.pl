use PDL::Doc;
use Getopt::Std;
use Config;
use Cwd;

$opt_v = 0;

getopts('v');
$dir = shift @ARGV;
$outdb  = shift @ARGV;

$currdir = getcwd;

chdir $dir or die "can't change to $dir";
$dir = getcwd;

unlink $outdb if -e $outdb;
$onldc = new PDL::Doc ($outdb);
$onldc->scantree($dir."/PDL",$opt_v);
$onldc->scan($dir."/PDL.pm",$opt_v);

chdir $currdir;

$onldc->savedb();
