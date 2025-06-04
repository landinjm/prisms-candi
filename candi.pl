#!/usr/bin/env perl
use warnings;
use strict;
use Config::Tiny;
use Getopt::Long qw(GetOptions);
use File::Path   qw( make_path rmtree );

# Load our modules
use lib 'src';
use utilities;
use prisms_versioning_requirements;
use package_manager;

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
my $candi_path   = 'pwd';
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
# Some checks for the config file

# Check that certain configs are ON or OFF
utilities::check_config_value( "prisms_pf",
    $config->{prisms_center_software}->{prisms_pf} );
utilities::check_config_value( "prisms_plasticity",
    $config->{prisms_center_software}->{prisms_plasticity} );
utilities::check_config_value( "clean_build",
    $config->{prisms_center_software}->{clean_build} );
utilities::check_config_value( "git",   $config->{required_packages}->{git} );
utilities::check_config_value( "cmake", $config->{required_packages}->{cmake} );
utilities::check_config_value( "zlib",  $config->{required_packages}->{zlib} );
utilities::check_config_value( "boost", $config->{required_packages}->{boost} );
utilities::check_config_value( "openblas",
    $config->{required_packages}->{openblas} );
utilities::check_config_value( "openmpi",
    $config->{required_packages}->{openmpi} );
utilities::check_config_value( "gsl",  $config->{optional_packages}->{gsl} );
utilities::check_config_value( "hdf5", $config->{optional_packages}->{hdf5} );
utilities::check_config_value( "sundials",
    $config->{optional_packages}->{sundials} );
utilities::check_config_value( "caliper",
    $config->{optional_packages}->{caliper} );
utilities::check_config_value( "spack", $config->{spack}->{full} );
utilities::check_config_value( "spack", $config->{spack}->{partial} );
utilities::check_config_value( "build_examples",
    $config->{'deal.II'}->{build_examples} );
utilities::check_config_value( "build_cuda", $config->{cuda}->{build_cuda} );
utilities::check_config_value( "enable_native_optimizations",
    $config->{misc_configs}->{enable_native_optimizations} );
utilities::check_config_value( "enable_64bit_indices",
    $config->{misc_configs}->{enable_64bit_indices} );

# TODO sanitize the other inputs

# Versioning checks
if (
    !prisms_versioning_requirements::dealii_version_is_supported(
        $config->{'deal.II'}->{version}, "prisms_pf",
        $config->{prisms_center_software}->{prisms_pf_version}
    )
    && $config->{prisms_center_software}->{prisms_pf} eq "ON"
  )
{
    utilities::color_print(
"deal.II v$config->{'deal.II'}->{version} is not supported by PRISMS-PF $config->{prisms_center_software}->{prisms_pf_version}.",
        "bad"
    );
    exit 1;
}
if (
    !prisms_versioning_requirements::dealii_version_is_supported(
        $config->{'deal.II'}->{version},
        "prisms_plasticity",
        $config->{prisms_center_software}->{prisms_plasticity_version}
    )
    && $config->{prisms_center_software}->{prisms_plasticity} eq "ON"
  )
{
    utilities::color_print(
"deal.II v$config->{'deal.II'}->{version} is not supported by PRISMS-Plasticity $config->{prisms_center_software}->{prisms_plasticity_version}.",
        "bad"
    );
    exit 1;
}

#############################################################
# Some brief setup based on the system and environment

# Get the os
my $os = utilities::guess_os();
utilities::color_print( "OS: $os", "info" );
if ( $os eq "unknown" ) {
    utilities::color_print(
"Error: Unknown OS. Please report this issue to the PRISMS-candi developers.",
        "bad"
    );
    exit 1;
}

# Get the architecture
my $architecture = utilities::guess_architecture();
utilities::color_print( "Architecture: $architecture", "info" );
if ( $architecture eq "unknown" ) {
    utilities::color_print(
"Error: Unknown architecture. Please report this issue to the PRISMS-candi developers.",
        "bad"
    );
    exit 1;
}

#############################################################
# Package management
my @packages_to_install = ();
{
    # Required packages that are often pre-installed. Turning these ON
    # will install them from source.
    my @required_packages =
      ( "git", "cmake", "zlib", "boost", "openblas", "openmpi" );

    # Other required packages for PRISMS-PF
    my @prisms_pf_packages = ( "p4est", "kokkos", "vtk", "dealii" );

    # Other required packages for PRISMS-PLASTICITY
    my @prisms_plasticity_packages =
      ( "p4est", "kokkos", "petsc", "hdf5", "dealii" );

    # Optional packages
    my @optional_prisms_pf_packages = ( "gsl", "hdf5", "sundials", "caliper" );

# Look through each of these packages and add it to the package list if it is on.
    my %seen_packages;
    foreach my $pkg (@required_packages) {
        if ( $config->{required_packages}->{$pkg} eq "ON" ) {
            push @packages_to_install, $pkg unless $seen_packages{$pkg}++;
        }
    }
    foreach my $pkg (@prisms_pf_packages) {
        if ( $config->{prisms_center_software}->{prisms_pf} eq "ON" ) {
            push @packages_to_install, $pkg unless $seen_packages{$pkg}++;
        }
    }
    foreach my $pkg (@prisms_plasticity_packages) {
        if ( $config->{prisms_center_software}->{prisms_plasticity} eq "ON" ) {
            push @packages_to_install, $pkg unless $seen_packages{$pkg}++;
        }
    }
    foreach my $pkg (@optional_prisms_pf_packages) {
        if ( $config->{optional_packages}->{$pkg} eq "ON" ) {
            push @packages_to_install, $pkg unless $seen_packages{$pkg}++;
        }
    }

}

# Sort the packages
my %package_priorities;
foreach my $pkg (@packages_to_install) {
    my $package_file = "src/packages/$pkg.pm";
    if ( !utilities::file_exists($package_file) ) {
        utilities::color_print( "Error: No package file found for $pkg",
            "bad" );
        exit 1;
    }

    # Load the package module to get its priority
    require $package_file;
    my $package_name = "packages::$pkg";
    no strict 'refs';

    # Default to low priority if not specified
    $package_priorities{$pkg} = ${"${package_name}::PRIORITY"} || 999;
    use strict 'refs';
}

# Sort packages by priority (lower number = higher priority)
@packages_to_install =
  sort { $package_priorities{$a} <=> $package_priorities{$b} }
  @packages_to_install;

my $packages = join( ", ", @packages_to_install );
utilities::color_print( "Preparing to install $packages", "info" );

#############################################################
# Check the compiler
utilities::color_print( "\nChecking the compiler", "info" );

# Check and set CC if not defined
if ( !defined $ENV{CC} ) {
    my $mpicc = `which mpicc 2>/dev/null`;
    chomp($mpicc);
    if ($mpicc) {
        utilities::color_print( "CC variable not set, but default mpicc found.",
            "warn" );
        $ENV{CC} = 'mpicc';
    }
}

# Check and set CXX if not defined
if ( !defined $ENV{CXX} ) {
    my $mpicxx = `which mpicxx 2>/dev/null`;
    chomp($mpicxx);
    if ($mpicxx) {
        utilities::color_print(
            "CXX variable not set, but default mpicxx found.", "warn" );
        $ENV{CXX} = 'mpicxx';
    }
}

# Check and set FC if not defined
if ( !defined $ENV{FC} ) {
    my $mpif90 = `which mpif90 2>/dev/null`;
    chomp($mpif90);
    if ($mpif90) {
        utilities::color_print(
            "FC variable not set, but default mpif90 found.", "warn" );
        $ENV{FC} = 'mpif90';
    }
}

# Check and set FF if not defined
if ( !defined $ENV{FF} ) {
    my $mpif77 = `which mpif77 2>/dev/null`;
    chomp($mpif77);
    if ($mpif77) {
        utilities::color_print(
            "FF variable not set, but default mpif77 found.", "warn" );
        $ENV{FF} = 'mpif77';
    }
}

# Check that we have all compilers
my @compilers = ( "CC", "CXX", "FC", "FF" );
foreach my $compiler (@compilers) {
    if ( !defined $ENV{$compiler} ) {
        utilities::color_print( "Error: $compiler is not set.", "bad" );
        exit 1;
    }
}

# Get the compiler paths
$ENV{CC_PATH}  = `which $ENV{CC} 2>/dev/null`;
$ENV{CXX_PATH} = `which $ENV{CXX} 2>/dev/null`;
$ENV{FC_PATH}  = `which $ENV{FC} 2>/dev/null`;
$ENV{FF_PATH}  = `which $ENV{FF} 2>/dev/null`;

# Remove the trailing newline
chomp( $ENV{CC_PATH} );
chomp( $ENV{CXX_PATH} );
chomp( $ENV{FC_PATH} );
chomp( $ENV{FF_PATH} );

# Print compiler information
utilities::color_print( "CC: $ENV{CC} at $ENV{CC_PATH}",    "info" );
utilities::color_print( "CXX: $ENV{CXX} at $ENV{CXX_PATH}", "info" );
utilities::color_print( "FC: $ENV{FC} at $ENV{FC_PATH}",    "info" );
utilities::color_print( "FF: $ENV{FF} at $ENV{FF_PATH}",    "info" );

#############################################################
# Clean up the old installation
if ( $config->{prisms_center_software}->{clean_build} eq "ON" ) {
    utilities::color_print( "Cleaning up the old installation\n", "info" );
    rmtree("$prefix/tmp");
}

# Create the necessary directories
make_path("$install_path");
make_path("$prefix/tmp");
make_path("$src_path");
make_path("$unpack_path");
make_path("$build_path");

#############################################################
# Begin installing the packages

# Initialize the package manager
package_manager::init( $src_path, $unpack_path, $build_path, $install_path );
for my $pkg (@packages_to_install) {

    # Navigate back to directory where we started
    chdir($candi_path);

    # Fetch the package
    package_manager::fetch_package($pkg);

    # Unpack the package
    package_manager::unpack_package($pkg);

    # Configure the package
    package_manager::configure_package($pkg);

    # Build the package
    package_manager::build_package($pkg);
}

#############################################################
# Print the time taken
my $end_time   = time;
my $time_taken = $end_time - $start_time;
utilities::color_print( "\nTime taken: $time_taken seconds\n", "good" );
