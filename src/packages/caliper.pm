package packages::caliper;

use strict;
use warnings;

use lib 'src';
use utilities;
use archive_manager;
use File::Path qw(rmtree);
use File::Spec;
use Cwd qw(abs_path);
use signal_handler;

our $PRIORITY = 14;

our $VERSION      = "2.12.1";
our $NAME         = "Caliper";
our $SOURCE_URL   = "https://github.com/LLNL/Caliper/archive/refs/tags/v";
our $PACKING_TYPE = "tar.gz";
our $CHECKSUM =
  "2b5a8f98382c94dc75cc3f4517c758eaf9a3f9cea0a8dbdc7b38506060d6955c";

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

sub fetch {

    # Since we rename the file we have to have a separate check
    # to see if we've already downloaded the archive.
    if ( utilities::file_exists("$NAME-$VERSION.$PACKING_TYPE") ) {
        utilities::color_print(
"Archive $NAME-$VERSION.$PACKING_TYPE already exists, skipping download",
            "info"
        );
        return 0;

    }

    # Construct the archive url
    my $archive_url = "$SOURCE_URL$VERSION.$PACKING_TYPE";

    # Download the archive
    archive_manager::download_archive( $archive_url, $CHECKSUM );

    # Rename the archive
    rename( "v$VERSION.$PACKING_TYPE", "$NAME-$VERSION.$PACKING_TYPE" );

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
    system("tar -xzf $NAME-$VERSION.$PACKING_TYPE -C $unpack_path") == 0
      or die
      "$0: tar -xzf $NAME-$VERSION.$PACKING_TYPE -C $unpack_path failed: $?\n";
}

sub build {
    my ( $unpack_path, $install_path ) = @_;

    # Create the build folder
    mkdir("$NAME-$VERSION");

    # Navigate to the build folder
    chdir("$NAME-$VERSION");

    # Run cmake
    system(
"cmake -G Ninja -DWITH_MPI=ON -DCMAKE_INSTALL_PREFIX=$install_path/$NAME-$VERSION $unpack_path/$NAME-$VERSION"
    ) == 0 or die "$0: caliper configuration failed: $?\n";

    # Build
    system("ninja -j$jobs && ninja install") == 0
      or die "$0: caliper build failed: $?\n";
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
    $config->{"caliper"} = { install_dir => $new_path };

    # Write the summary file
    $config->write($config_file);

    # Add to a configuration file
    my $config_file = File::Spec->catfile( $install_path, 'prisms_env.sh' );
    open( my $fh, '>>', $config_file )
      or die "Cannot append to $config_file: $!";
    print $fh "export CALIPER_DIR=$new_path\n";
    close($fh);
}

1;
