package packages::dealii;

use strict;
use warnings;

use lib 'src';
use utilities;
use File::Path qw(rmtree);
use File::Spec;
use Cwd qw(abs_path);
use signal_handler;

our $PRIORITY = 100;

our $VERSION    = "";
our $NAME       = "dealii";
our $SOURCE_URL = "https://github.com/dealii/dealii.git";

# Set up signal handlers
signal_handler::setup_handlers();

# Read the config file
my $config_file = abs_path("summary.conf");
my $config      = Config::Tiny->read($config_file);
if ( !$config ) {
    utilities::color_print(
        "Error: Failed to read config file: " . Config::Tiny->errstr(), "bad" );
    exit 1;
}

# Grab the number of jobs from the config file
our $jobs = $config->{"General Configuration"}->{jobs};

# Determine some configuration options
$VERSION = $config->{'deal.II'}->{version};
our $conf_opts =
qq{-DDEAL_II_WITH_MPI=ON -DDEAL_II_WITH_P4EST=ON -DDEAL_II_WITH_LAPACK=ON -DDEAL_II_WITH_ZLIB=ON -DDEAL_II_WITH_VTK=ON -DDEAL_II_WITH_TBB=ON};
if ( $config->{"General Configuration"}->{dev_mode} eq "ON" ) {
    $conf_opts .= qq{ -DDEAL_II_ALLOW_AUTODETECTION=OFF};
}
$conf_opts .=
  qq{ -DDEAL_II_COMPONENT_EXAMPLES=$config->{"deal.II"}->{build_examples}};
if ( $config->{"Compile Flags"}->{native_optimizations} eq "ON" ) {
    $conf_opts .=
qq{ -DCMAKE_CXX_FLAGS="-march=native -mtune=native" -DCMAKE_CXX_FLAGS_RELEASE="-O3"};
}
$conf_opts .=
  qq{ -DDEAL_II_WITH_64BIT_INDICES=$config->{"Compile Flags"}->{"64bit"}};

sub fetch {

    # Clone the repository if it doesn't exist
    if ( !utilities::directory_exists("$NAME-$VERSION") ) {
        system("git clone $SOURCE_URL $NAME-$VERSION") == 0
          or die "$0: deal.II clone failed: $?\n";
    }

    # Checkout the version
    system(
"cd $NAME-$VERSION && git fetch --all --tags --prune && git checkout tags/v$VERSION"
    ) == 0 or die "$0: deal.II checkout failed: $?\n";
}

sub unpack {
    my $unpack_path = shift;

    # Double check that the repository was cloned
    if ( !utilities::directory_exists("$NAME-$VERSION") ) {
        utilities::color_print( "Error: Repository $NAME-$VERSION not found",
            "bad" );
        exit 1;
    }

    # Remove the old unpacked directory
    if ( utilities::directory_exists("$unpack_path/$NAME-$VERSION") ) {
        rmtree("$unpack_path/$NAME-$VERSION");
    }

    # Move the repository to the unpack path
    system("mv $NAME-$VERSION $unpack_path") == 0
      or die "$0: mv $NAME-$VERSION $unpack_path failed: $?\n";
}

sub build {
    my ( $unpack_path, $install_path ) = @_;

    # Read the summary file
    my $summary = Config::Tiny->read($config_file);
    if ( !$summary ) {
        utilities::color_print(
            "Error: Failed to read summary file: " . Config::Tiny->errstr(),
            "bad" );
        exit 1;
    }

    # Grab the install directories for the dependencies
    my $kokkos_dir = $summary->{"kokkos"}->{install_dir};
    my $p4est_dir  = $summary->{"p4est"}->{install_dir};
    my $vtk_dir    = $summary->{"vtk"}->{vtk_dir};

    # Create the build folder
    mkdir("$NAME-$VERSION");

    # Navigate to the build folder
    chdir("$NAME-$VERSION");

    # Run cmake
    system(
"cmake -G Ninja $conf_opts -DCMAKE_INSTALL_PREFIX=$install_path/$NAME-$VERSION -DKOKKOS_DIR=$kokkos_dir -DP4EST_DIR=$p4est_dir -DVTK_DIR=$vtk_dir $unpack_path/$NAME-$VERSION"
    ) == 0 or die "$0: dealii configuration failed: $?\n";

    # Build
    system("ninja -j$jobs && ninja install") == 0
      or die "$0: dealii build failed: $?\n";

}

sub register {
    my $install_path = shift;

    # Add to path
    my $new_path = "$install_path/$NAME-$VERSION";
    $ENV{PATH} = "$new_path:$ENV{PATH}";

    my $config = Config::Tiny->read($config_file);
    if ( !$config ) {
        utilities::color_print(
            "Error: Failed to read config file: " . Config::Tiny->errstr(),
            "bad" );
        exit 1;
    }

    # Add to the summary file
    $config->{"dealii"} = { install_dir => $new_path };

    # Write the summary file
    $config->write($config_file);

    # Add to a configuration file
    my $config_file = File::Spec->catfile( $install_path, 'prisms_env.sh' );
    open( my $fh, '>>', $config_file )
      or die "Cannot append to $config_file: $!";
    print $fh "export DEAL_II_DIR=$new_path\n";
    close($fh);
}

1;
