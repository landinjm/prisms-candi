#!/usr/bin/env perl
use warnings;
use strict;
use Config::Tiny;

# Load our modules
use lib 'src';
use utilities;

#############################################################
# Start a timer
my $start_time = time;

#############################################################
# Read the config file
my $config = Config::Tiny->read("candi.conf");

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
utilities::color_print( "Time taken: $time_taken seconds", "green" );
