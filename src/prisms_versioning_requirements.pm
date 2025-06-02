package prisms_versioning_requirements;

use strict;
use warnings;
use lib '.';
use utilities;

my @prisms_center_software = ( "prisms_pf", "prisms_plasticity" );

# Map of PRISMS-PF versions and max supported major.minor deal.II version
my @prisms_pf_versions = (
    "master" => "9.6.0",
    "2.4.1"  => "9.6.0",
    "2.4.0"  => "9.6.0",
    "2.3.0"  => "9.5.0"
);

# Map of PRISMS-Plasticity versions and max supported major.minor deal.II version
my @prisms_plasticity_versions = ( "master" => "9.6.0" );

1;
