package packages::openblas;

use strict;
use warnings;

use lib 'src';
use utilities;

our $PRIORITY = 3;

# Read the config file
my $config_file = "summary.conf";
my $config      = Config::Tiny->read($config_file);
if ( !$config ) {
    utilities::color_print(
        "Error: Failed to read config file: " . Config::Tiny->errstr(), "bad" );
    exit 1;
}

# Grab the number of jobs from the config file
my $jobs = $config->{"General Configuration"}->{jobs};

sub fetch { }

sub unpack {
    my $unpack_path = shift;
}

sub build {
    my ( $unpack_path, $install_path ) = @_;
}

sub register {
    my $install_path = shift;
}

1;
