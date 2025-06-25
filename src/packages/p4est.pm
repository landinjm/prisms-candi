package packages::p4est;

use strict;
use warnings;

use lib 'src';
use utilities;
use archive_manager;
use File::Path qw(rmtree);
use File::Spec;
use Cwd qw(abs_path);
use signal_handler;

our $PRIORITY = 11;

our $VERSION      = "2.8.7";
our $NAME         = "p4est";
our $SOURCE_URL   = "https://p4est.github.io/release/";
our $PACKING_TYPE = "tar.gz";
our $CHECKSUM =
  "0a1e912f3529999ca6d62fee335d51f24b5650b586e95a03ef39ebf73936d7f4";

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
    system("tar -xzf $NAME-$VERSION.$PACKING_TYPE -C $unpack_path") == 0
      or die
      "$0: tar -xzf $NAME-$VERSION.$PACKING_TYPE -C $unpack_path failed: $?\n";
}

sub build {
    my ( $unpack_path, $install_path ) = @_;

    # Copy the unpacked folder to the build path
    system("cp -rf $unpack_path/$NAME-$VERSION .") == 0
      or die "$0: cp -rf $unpack_path/$NAME-$VERSION . failed: $?\n";

    # Navigate to the build folder
    chdir("$NAME-$VERSION");

    # Configure the package
    system(
"./configure --enable-mpi --enable-shared --prefix=$install_path/$NAME-$VERSION"
    ) == 0 or die "$0: p4est configuration failed: $?\n";

    # Build the package
    system("make -C sc -j$jobs && make -j$jobs && make install") == 0
      or die "$0: p4est build failed: $?\n";

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
    $config->{"p4est"} = { install_dir => $new_path };

    # Write the summary file
    $config->write($config_file);

    # Add to a configuration file
    my $config_file = File::Spec->catfile( $install_path, 'prisms_env.sh' );
    open( my $fh, '>>', $config_file )
      or die "Cannot append to $config_file: $!";
    print $fh "export P4EST_DIR=$new_path/bin\n";
    close($fh);
}

1;
