package packages::petsc;

use strict;
use warnings;

use lib 'src';
use utilities;
use archive_manager;
use File::Path   qw(rmtree);
use Getopt::Long qw(GetOptions);

our $PRIORITY = 7;

our $VERSION = "3.23.3";
our $NAME    = "petsc";
our $SOURCE_URL =
  "https://web.cels.anl.gov/projects/petsc/download/release-snapshots/";
our $PACKING_TYPE = "tar.gz";
our $CHECKSUM =
  "bb51e8cbaa3782afce38c6f0bdd64d20ed090695992b7d49817518aa7e909139";

# Read the config file
my $config_file = "summary.conf";
my $config = Config::Tiny->read($config_file);
if ( !$config ) {
    utilities::color_print(
        "Error: Failed to read config file: " . Config::Tiny->errstr(), "bad" );
    exit 1;
}

# Determine configuration options for petsc
our $opt_flags = qq{"-g -O"};
if ( $config->{"Compile Flags"}->{native_optimizations} eq "ON" ) {
    $opt_flags = qq{"-O3 -march=native -mtune=native"};
}
our $conf_opts =
  "--with-deubgging=0 --with-shared-libraries=1 --with-mpi=1 --with-x=0";
if ( $config->{"Compile Flags"}->{"64bit"} eq "ON" ) {
    $conf_opts .= " --with-64-bit-indicies=1";
}
$conf_opts .= " CC=$config->{"Compilers"}->{CC}";
$conf_opts .= " CXX=$config->{"Compilers"}->{CXX}";
$conf_opts .= " FC=$config->{"Compilers"}->{FC}";

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
    system(
"./configure --prefix=$install_path/$NAME-$VERSION $conf_opts COPTFLAGS=$opt_flags CXXOPTFLAGS=$opt_flags FOPTFLAGS=$opt_flags"
    );

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
