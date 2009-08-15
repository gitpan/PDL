# -*- cperl -*-

#use strict;
use Test::More;

BEGIN { 
  eval 'use Storable 1.03';
  unless ($@) {
    plan tests => 7;
  } else {
    plan skip_all => "Storable >= 1.03 not installed\n";
  }
  use Storable qw/freeze thaw/;
}

BEGIN { 
   use PDL::LiteF;
   use PDL::Dbg;
   use_ok('PDL::IO::Storable');
}


$a = sequence(2,2);
# $a->dump;

$serialized = freeze $a;

$olda = thaw $serialized;
# $olda->dump;

ok(sum(abs($a-$olda))==0, 'PDL freeze/thaw');

# $oldb = thaw $serialized;
# $oldc = thaw $serialized;
# 
# $PDL::Dbg::Infostr = "%T %D %S %A";
# PDL->px;
# 
# undef $oldb;
# print $oldc;

undef $a;

$data = {
   key1 => 1,
   key2 => sequence(3),
   key3 => 'hallo',
};

$dfreeze = freeze $data;
$dthaw = thaw $dfreeze;

isa_ok($dthaw, 'HASH'); # we got a HASH back

ok(all($data->{key2} == $dthaw->{key2}), 'PDL in structure');

$phash = bless {PDL => sequence 3}, 'PDL';
can_ok($phash, 'freeze');

$pfreeze = $phash->freeze;
$phthaw = thaw $pfreeze;

ok(all($phthaw == $phash), 'PDL has-a works with freeze/thaw');
ok(UNIVERSAL::isa($phthaw,'HASH'), 'PDL is a hash');
