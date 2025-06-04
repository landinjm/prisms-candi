package archive_manager;

use strict;
use warnings;
use lib 'src';
use utilities;

our @download_methods = utilities::check_download_tools();

# Verify an archive file
sub verify_archive {
    my ( $archive_name, $expected_checksum ) = @_;

    # Check if the archive file exists
    if ( !utilities::file_exists($archive_name) ) {
        utilities::color_print(
            "Error: Archive file $archive_name does not exist", "bad" );
        return 0;
    }

    # Check if the archive has the correct checksum
    my $checksum = utilities::get_checksum($archive_name);

    if ( $checksum ne $expected_checksum ) {
        utilities::color_print(
            "Error: Archive file $archive_name has incorrect checksum", "bad" );
        return 0;
    }

    # Otherwise the archive is valid
    return 1;
}

# Download an archive file
sub download_archive {
    my ( $archive_url, $expected_checksum ) = @_;

    # Get the archive name
    my $archive_name = $archive_url;
    $archive_name =~ s/.*\///;

    my $successful_download = 0;
    for my $downloader (@download_methods) {

        # Download the archive
        print("Downloading $archive_url with $downloader\n");
        if ( $downloader eq "curl" ) {
            system("curl -f -L -k -O $archive_url");
        }
        elsif ( $downloader eq "wget" ) {
            system("wget --no-check-certificate $archive_url -O $archive_name");
        }
        else {
            utilities::color_print( "Error: Unknown downloader: $downloader",
                "bad" );
            exit 1;
        }

        # Verify the archive
        $successful_download =
          verify_archive( $archive_name, $expected_checksum );

        # Only try one download method if successful
        if ($successful_download) {
            last;
        }
    }

    if ( !$successful_download ) {
        utilities::color_print( "Error: Failed to download $archive_url",
            "bad" );
        exit 1;
    }
}

1;
