package packages::git;

use strict;
use warnings;

use lib 'src';
use utilities;
use archive_manager;
use File::Path qw(rmtree);

our $PRIORITY = 1;

our $VERSION      = "2.9.5";
our $NAME         = "git";
our $SOURCE_URL   = "https://www.kernel.org/pub/software/scm/git/";
our $PACKING_TYPE = "tar.gz";
our $CHECKSUM =
  "8fa575338137d6d850b52d207cf7155cd1f4003ebd698f0fb75f65efb862ef7f";

# Read the config file
my $config_file = "summary.conf";
my $config      = Config::Tiny->read($config_file);
if ( !$config ) {
    utilities::color_print(
        "Error: Failed to read config file: " . Config::Tiny->errstr(), "bad" );
    exit 1;
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

    # Copy the unpacked folder to the build path
    system("cp -rf $unpack_path/$NAME-$VERSION .");

    # Navigate to the build folder
    chdir("$NAME-$VERSION");

    # Configure the package
    system("./configure --prefix=$install_path/$NAME-$VERSION");

    # Build the package
    system("make install");
}

sub register {
    my $install_path = shift;

    # Add to path
    my $new_path = "$install_path/$NAME-$VERSION/bin";
    $ENV{PATH} = "$new_path:$ENV{PATH}";
}

1;
