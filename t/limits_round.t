no warnings qw(misc);

use Test::More;

BEGIN {
  eval "use PDL::Slatec;";
  if ( !$@ ) {
    eval "use PDL::Graphics::Limits;";
    plan tests => 37;
  } else {
    plan skip_all => 'PDL::Slatec not available';
  }
};

*round_pow = \&PDL::Graphics::Limits::round_pow;

@round_tests =
 ( 
  [ -100, -200, -50 ],
  [ -11, -20, -10 ],
  [ -10, -20, -5 ],
  [ -6, -10, -5 ],
  [ -5, -10, -2 ],
  [ -3, -5, -2 ],
  [ -2, -5, -1 ],
  [ -1   ,  -2   , -0.5   ],
  [ -0.6 ,  -1   , -0.5   ],
  [ -0.5 ,  -1   , -0.2   ],
  [ -0.3 ,  -0.5 , -0.2   ],
  [ -0.2 ,  -0.5 , -0.1   ],
  [ -0.1 ,  -0.2 , -0.05  ],
  [ -0.06,  -0.1 , -0.05  ],
  [ -0.05,  -0.1 , -0.02  ],
  [ -0.03,  -0.05, -0.02  ],
  [ -0.02,  -0.05, -0.01  ],
  [ -0.01,  -0.02, -0.005 ],

  [ 0, 0, 0 ],
  [ 0.01, 0.005, 0.02 ],
  [ 0.02, 0.01, 0.05 ],
  [ 0.03, 0.02, 0.05 ],
  [ 0.05, 0.02, 0.1 ],
  [ 0.06, 0.05, 0.1 ],
  [ 0.1, 0.05, 0.2 ],
  [ 0.2, 0.1, 0.5 ],
  [ 0.3, 0.2, 0.5 ],
  [ 0.5, 0.2, 1 ],
  [ 0.6, 0.5, 1 ],
  [ 1, 0.5, 2 ],
  [ 2, 1, 5 ],
  [ 3, 2, 5 ],
  [ 5, 2, 10 ],
  [ 6, 5, 10 ],
  [ 10, 5, 20 ],
  [ 11, 10, 20 ],
  [ 100, 50, 200 ],
 );

for my $test ( @round_tests )
{
  my $down = round_pow( down => $test->[0] );
  my $up   = round_pow( up   => $test->[0] );

  ok( $test->[1] == $down && $test->[2] == $up, 
      'round_pow(' . $test->[0] . ')' );
}



