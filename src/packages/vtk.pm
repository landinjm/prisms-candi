package packages::vtk;

use strict;
use warnings;

use lib 'src';
use utilities;
use archive_manager;
use File::Path qw(rmtree);
use File::Spec;
use Cwd qw(abs_path);

our $PRIORITY = 13;

our $VERSION      = "9.4.2";
our $NAME         = "VTK";
our $SOURCE_URL   = "https://vtk.org/files/release/9.4/";
our $PACKING_TYPE = "tar.gz";
our $CHECKSUM =
  "36c98e0da96bb12a30fe53708097aa9492e7b66d5c3b366e1c8dc251e2856a02";

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
"cmake -G Ninja -DVTK_USE_MPI=ON -DCMAKE_INSTALL_PREFIX=$install_path/$NAME-$VERSION $unpack_path/$NAME-$VERSION"
    );

    # Build
    system("ninja -j$jobs && ninja install");

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
    $config->{"vtk"} = { install_dir => $new_path };

    # Write the summary file
    $config->write($config_file);

    # Add to a configuration file
    my $config_file = File::Spec->catfile( $install_path, 'prisms_env.sh' );
    open( my $fh, '>>', $config_file )
      or die "Cannot append to $config_file: $!";
    print $fh "export VTK_DIR=$new_path\n";
    close($fh);
}

1;
