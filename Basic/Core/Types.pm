package PDL::Types;
require Exporter;


@EXPORT = qw( $PDL_B $PDL_S $PDL_US $PDL_L $PDL_F $PDL_D @pack %typehash );
@ISA    = qw( Exporter ); 


# Data types/sizes (bytes) [must be in order of complexity] 

# Enum
( $PDL_B, $PDL_S, $PDL_US, $PDL_L, $PDL_F, $PDL_D ) = (0..5); 

# Corresponding pack types
@PDL::Types::pack=("C*", "s*", "S*", "l*", "f*", "d*"); 


# should be usable in a couple of places, e.g. Dev.pm (how to locate
# during compilation?) and PDL::PP::PDLCode, also used in PDL::Dbg
%PDL::Types::typehash = ();
map {$key = $_; $PDL::Types::typehash{$key->[0]} = {'sym' => $key->[1],
						    'ctype' => $key->[2],
						    'ppsym' => $key->[3]} }
    ([$PDL_B,'PDL_B','PDL_Byte','B'],
     [$PDL_S,'PDL_S','PDL_Short','S'],
     [$PDL_US,'PDL_US','PDL_Ushort','U'],
     [$PDL_L,'PDL_L','PDL_Long','L'],
     [$PDL_F,'PDL_F','PDL_Float','F'],
     [$PDL_D,'PDL_D','PDL_Double','D']);
1;
