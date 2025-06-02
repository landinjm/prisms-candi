package prisms_versioning_requirements;

use strict;
use warnings;
use lib '.';
use utilities;

my @prisms_center_software = ( "prisms_pf", "prisms_plasticity" );

# Map of PRISMS-PF versions and max supported major.minor deal.II version
my %prisms_pf_versions = (
    "master" => "9.6.0",
    "2.4.1"  => "9.6.0",
    "2.4.0"  => "9.6.0",
    "2.3.0"  => "9.5.0"
);

# Map of PRISMS-Plasticity versions and max supported major.minor deal.II version
my %prisms_plasticity_versions = ( "master" => "9.5.0" );

# Check if a deal.II version is supported by a PRISMS-PF or PRISMS-Plasticity version
#   Example usage:
#     if ( dealii_version_is_supported( $dealii_version, $prisms_center_software, $prisms_center_software_version ) ) {
#       print "Deal.II version is supported\n";
#     }
sub dealii_version_is_supported {
    my ( $dealii_version, $prisms_center_software,
        $prisms_center_software_version )
      = @_;

# Check that prisms_center_software is a valid PRISMS-PF or PRISMS-Plasticity version
    my $max_dealii_version;
    if ( $prisms_center_software eq "prisms_pf" ) {
        if ( !exists $prisms_pf_versions{$prisms_center_software_version} ) {
            utilities::color_print(
"PRISMS-PF $prisms_center_software_version is not supported or does not exist.\n",
                "bad"
            );
            return 0;
        }
        $max_dealii_version =
          $prisms_pf_versions{$prisms_center_software_version};
    }
    elsif ( $prisms_center_software eq "prisms_plasticity" ) {
        if (
            !exists $prisms_plasticity_versions{$prisms_center_software_version}
          )
        {
            utilities::color_print(
"PRISMS-Plasticity $prisms_center_software_version is not supported or does not exist.\n",
                "bad"
            );
            return 0;
        }
        $max_dealii_version =
          $prisms_plasticity_versions{$prisms_center_software_version};
    }
    else {
        utilities::color_print(
            "Invalid PRISMS center software: $prisms_center_software\n",
            "bad" );
        return 0;
    }

    return utilities::version_minor_less_than( $dealii_version,
        $max_dealii_version );
}

1;
