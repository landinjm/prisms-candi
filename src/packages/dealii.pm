package packages::dealii;

use strict;
use warnings;

use lib 'src';
use utilities;
use archive_manager;
use File::Path qw(rmtree);

our $PRIORITY = 100;

our $VERSION      = "";
our $NAME         = "dealii";
our $SOURCE_URL   = "https://www.dealii.org/downloads/";
our $PACKING_TYPE = "tar.gz";
our $CHECKSUM     = "";

# Read the config file
my $config_file = "summary.conf";
my $config      = Config::Tiny->read($config_file);
if ( !$config ) {
    utilities::color_print(
        "Error: Failed to read config file: " . Config::Tiny->errstr(), "bad" );
    exit 1;
}

# Determine some configuration options
$VERSION = $config->{'deal.II'}->{version};
if ( $VERSION eq "9.6.2" ) {
    $CHECKSUM =
      "1051e332de3822488e91c2b0460681052a3c4c5ac261cdd7a6af784869a25523";
}

sub fetch {

    # Construct the archive url
    my $archive_url = "$SOURCE_URL$NAME-$VERSION.$PACKING_TYPE";

    # Download the archive
    archive_manager::download_archive( $archive_url, $CHECKSUM );
}

sub unpack {
    my $unpack_path = shift;

    # Double check that the archive was downloaded
    if ( !utilities::file_exists("$NAME-$VERSION.$PACKING_TYPE") ) {
        utilities::color_print(
            "Error: Archive $NAME-$VERSION.$PACKING_TYPE not found", "bad" );
        exit 1;
    }

    # Remove the old unpacked directory
    if ( utilities::directory_exists("$unpack_path/$NAME-$VERSION") ) {
        rmtree("$unpack_path/$NAME-$VERSION");
    }

    # Unpack the archive
    system("tar -xzf $NAME-$VERSION.$PACKING_TYPE -C $unpack_path");

}

sub build {
    my ( $unpack_path, $install_path ) = @_;

    # Create the build folder
    mkdir("$NAME-$VERSION");

    # Navigate to the build folder
    chdir("$NAME-$VERSION");

    # Run cmake
    system(
"cmake -DDEAL_II_WITH_MPI=ON -DDEAL_II_WITH_P4EST=ON -DCMAKE_INSTALL_PREFIX=$install_path/$NAME-$VERSION $unpack_path/$NAME-$VERSION"
    );

    # Build
    system("make && make install");

}

sub register {
    my $install_path = shift;

    # Add to path
    my $new_path = "$install_path/$NAME-$VERSION/bin";
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

    # Close the summary file
    $config->write($config_file);
}

1;
