#!/usr/bin/env perl
use warnings;
use strict;
use Config::Tiny;
use Getopt::Long qw(GetOptions);

# Load our modules
use lib 'src';
use utilities;

#############################################################
# Start a timer
my $start_time = time;

#############################################################
# Default values
my $prefix               = "$ENV{HOME}/prisms-candi";
my $jobs                 = 1;
my $use_default_compiler = "ON";

# Parse command line inputs
GetOptions(
    'prefix=s'  => \$prefix,
    'p=s'       => \$prefix,
    'default=s' => \$use_default_compiler,
    'jobs=i'    => \$jobs,
    'j=i'       => \$jobs,
    'help|h'    => sub {
        print "PRISMS center compile and install script\n\n";
        print "Usage: $0 [options]\n";
        print "Options:\n";
        print
"  -p=<path>, --prefix=<path>  set a different prefix path (default = $prefix)\n";
        print
"  --default=<ON/OFF>          override to use default spack compiler (default = $use_default_compiler)\n";
        print
"  -j=<N>, --jobs=<N>   compile with N processes in parallel (default = $jobs)\n";
        exit 0;
    }
) or die "Invalid command line option. See -h for more information.\n";

# Replace the ~ with the home directory
$prefix =~ s|^~|$ENV{HOME}|;

# Check that inputs are valids
utilities::check_config_value( "--default", $use_default_compiler );
if ( !utilities::is_positive_integer($jobs) ) {
    utilities::color_print(
        "Error: Invalid value for --jobs: $jobs. Expected a positive number.",
        "bad" );
    exit 1;
}

# Set the other paths
my $src_path     = "$prefix/tmp/src";
my $unpack_path  = "$prefix/tmp/unpack";
my $build_path   = "$prefix/tmp/build";
my $install_path = "$prefix";

#############################################################
# Read the config file
my $config_file = "candi.conf";
if ( !utilities::file_exists($config_file) ) {
    utilities::color_print( "Error: Config file '$config_file' not found",
        "bad" );
    exit 1;
}

my $config = Config::Tiny->read($config_file);
if ( !$config ) {
    utilities::color_print(
        "Error: Failed to read config file: " . Config::Tiny->errstr(), "bad" );
    exit 1;
}

#############################################################
# Packages management
{
    # Required packages that are often pre-installed. Turning these ON
    # will install them from source.
    my @required_packages =
      ( "git", "cmake", "zlib", "boost", "openblas", "openmpi" );

    # Required packages for PRISMS-PF
    my @prisms_pf_packages =
      ( "openblas", "openmpi", "p4est", "kokkos", "vtk", "zlib" );

    # Required packages for PRISMS-PLASTICITY
    my @plasticity_packages =
      ( "openblas", "openmpi", "p4est", "kokkos", "petsc", "hdf5", "zlib" );

    # Optional packages
    my @optional_prisms_pf_packages = ( "gsl", "hdf5", "sundials", "caliper" );
}

#############################################################
# Print the time taken
my $end_time   = time;
my $time_taken = $end_time - $start_time;
utilities::color_print( "\nTime taken: $time_taken seconds\n", "good" );
