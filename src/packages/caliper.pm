package packages::caliper;

use strict;
use warnings;

use lib 'src';
use utilities;
use archive_manager;
use File::Path qw(rmtree);

our $PRIORITY = 14;

our $VERSION      = "2.12.1";
our $NAME         = "Caliper";
our $SOURCE_URL   = "https://github.com/LLNL/Caliper/archive/refs/tags/v";
our $PACKING_TYPE = "tar.gz";
our $CHECKSUM =
  "2b5a8f98382c94dc75cc3f4517c758eaf9a3f9cea0a8dbdc7b38506060d6955c";

sub fetch {

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
"cmake -DWITH_MPI=ON -DCMAKE_INSTALL_PREFIX=$install_path/$NAME-$VERSION $unpack_path/$NAME-$VERSION"
    );

    # Build
    system("make && make install");
}

sub register {
    my $install_path = shift;

    # Add to path
    my $new_path = "$install_path/$NAME-$VERSION/bin";
    $ENV{PATH} = "$new_path:$ENV{PATH}";
}

1;
