
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::GIS::Proj;

@EXPORT_OK  = qw(   fwd_transform inv_transform get_proj_info  PDL::PP _fwd_trans  fwd_trans_inplace PDL::PP _fwd_trans_inplace PDL::PP _inv_trans  inv_trans_inplace PDL::PP _inv_trans_inplace   load_projection_descriptions    load_projection_information  );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::GIS::Proj ;








=head1 NAME

PDL::GIS::Proj - PDL interface to the Proj4 projection library.

=head1 DESCRIPTION

PDL interface to the Proj4 projection library.

For more information on the proj library, see: http://www.remotesensing.org/proj/

=head1 AUTHOR

Judd Taylor, Orbital Systems, Ltd.
judd dot t at orbitalsystems dot com

=head1 DATE

18 March 2003

=head1 CHANGES

=head2 1.32 (29 March 2006) Judd Taylor

    - Getting ready to merge this into the PDL CVS. 
    
=head2 1.31 (???) Judd Taylor

    - Can't remember what was in that version

=head2 1.30 (16 September 2003) Judd Taylor

    - The get_proj_info() function actually works now.

=head2 1.20 (24 April 2003) Judd Taylor

    - Added get_proj_info().

=head2 1.10 (23 April 2003) Judd Taylor

    - Changed from using the proj_init() type API in projects.h to the
    - proj_init_plus() API in proj_api.h. The old one was not that stable...

=head2 1.00 (18 March 2003) Judd Taylor

    - Initial version

=head1 COPYRIGHT NOTICE

Copyright 2003 Judd Taylor, USF Institute for Marine Remote Sensing (judd@marine.usf.edu).

GPL Now!

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=head1 SUBROUTINES

=cut





=head2 fwd_transform($lon(pdl), $lat(pdl), $params)

Proj4 forward transformation $params is a string of the projection transformation
parameters.

Returns two pdls for x and y values respectively. The units are dependant on Proj4
behavior. They will be PDL->null if an error has occurred.

BadDoc: Ignores bad elements of $lat and $lon, and sets the corresponding elements 
of $x and $y to BAD

=cut


sub fwd_transform
{
    my ($lon, $lat, $params) = @_;
    my $x = null;
    my $y = null;

    #print "Projection transformation parameters: \'$params\'\n";

    _fwd_trans( $lon, $lat, $x, $y, $params );

    return ($x, $y);
} # End of fwd_transform()...

=head2 inv_transform($x(pdl), $y(pdl), $params)

Proj4 inverse transformation $params is a string of the projection transformation
parameters.

Returns two pdls for lat and lon values respectively. The units are dependant on Proj4
behavior. They will be PDL->null if an error has occurred.

BadDoc: Ignores bad elements of $lat and $lon, and sets the corresponding elements 
of $x and $y to BAD

=cut


sub inv_transform
{
    my ($x, $y, $params) = @_;
    my $lon = null;
    my $lat = null;

    #print "Projection transformation parameters: \'$params\'\n";

    _inv_trans( $x, $y, $lon, $lat, $params );
    return ($lon, $lat);
} # End of fwd_transform()...

=head2 get_proj_info($params_string)

Returns a string with information about what parameters proj will
actually use, this includes defaults, and +init=file stuff. It's 
the same as running 'proj -v'. It uses the proj command line, so
it might not work with all shells. I've tested it with bash.

=cut


sub get_proj_info
{
    my $params = shift;
    my @a = split(/\n/, `echo | proj -v $params`);
    pop(@a);
    return join("\n", @a);
} # End of get_proj_info()...





*_fwd_trans = \&PDL::_fwd_trans;



#
# Wrapper sub for _fwd_trans_inplace that sets a default for the quiet variable.
# 
sub fwd_trans_inplace
{
    my $lon = shift;
    my $lat = shift;
    my $params = shift;
    my $quiet = shift || 0;
    
    _fwd_trans_inplace( $lon, $lat, $params, $quiet );
} # End of fwd_trans_inplace()...





*_fwd_trans_inplace = \&PDL::_fwd_trans_inplace;





*_inv_trans = \&PDL::_inv_trans;



#
# Wrapper sub for _fwd_trans_inplace that sets a default for the quiet variable.
# 
sub inv_trans_inplace
{
    my $lon = shift;
    my $lat = shift;
    my $params = shift;
    my $quiet = shift || 0;
    
    _inv_trans_inplace( $lon, $lat, $params, $quiet );
} # End of fwd_trans_inplace()...





*_inv_trans_inplace = \&PDL::_inv_trans_inplace;




sub load_projection_information
{
    my $descriptions = PDL::GIS::Proj::load_projection_descriptions();
    
    my $info = {};
    
    foreach my $projection ( keys %$descriptions )
    {
        my $description = $descriptions->{$projection};
    
        my $hash = {};
        $hash->{CODE} = $projection;
        
        
        
        my @lines = split( /\n/, $description );
        chomp @lines;
        
        # Full name of this projection:
        $hash->{NAME} = $lines[0];
        
        # The second line is usually a list of projection types this one is:
        my $temp = $lines[1];
        $temp =~ s/no inv\.*,*//;
        $temp =~ s/or//;
        my @temp_types = split(/[,&\s]/, $temp );
        my @types = grep( /.+/, @temp_types );
        $hash->{CATEGORIES} = \@types;
        
        # If there's more than 2 lines, then it usually is a listing of parameters:
        
        # General parameters for all projections:
        $hash->{PARAMS}->{GENERAL} = 
            [ qw( x_0 y_0 lon_0 units init no_defs geoc over ) ];
        
        # Earth Figure Parameters:
        $hash->{PARAMS}->{EARTH} = 
            [ qw( ellps b f rf e es R R_A R_V R_a R_g R_h R_lat_g ) ];
        
        # Projection Specific Parameters:
        my @proj_params = ();
        if( $#lines >= 2 )
        {
            foreach my $i ( 2 .. $#lines )
            {
                my $text = $lines[$i];
                my @temp2 = split( /\s+/, $text );
                my @params = grep( /.+/, @temp2 );
                foreach my $param (@params)
                {
                    $param =~ s/=//;
                    $param =~ s/[,\[\]]//sg;
                    next if $param =~ /^and$/;
                    next if $param =~ /^or$/;
                    next if $param =~ /^Special$/;
                    next if $param =~ /^for$/;
                    next if $param =~ /^Madagascar$/;
                    next if $param =~ /^fixed$/;
                    next if $param =~ /^Earth$/;
                    next if $param =~ /^For$/;
                    next if $param =~ /^CH1903$/;
                    push(@proj_params, $param);
                }
            }    
        }
        $hash->{PARAMS}->{PROJ} = \@proj_params;
        
        # Can this projection do inverse?
        $hash->{INVERSE} = ( $description =~ /no inv/ ) ? 0 : 1;
        
        $info->{$projection} = $hash;
    }
    
    # A couple of overrides:
    #
    $info->{ob_tran}->{PARAMS}->{PROJ} = 
        [ 'o_proj', 'o_lat_p', 'o_lon_p', 'o_alpha', 'o_lon_c', 
          'o_lat_c', 'o_lon_1', 'o_lat_1', 'o_lon_2', 'o_lat_2' ];
          
    $info->{nzmg}->{CATEGORIES} = [ 'fixed Earth' ];

    return $info;
} # End of load_projection_information()...




;



# Exit with OK status

1;

		   