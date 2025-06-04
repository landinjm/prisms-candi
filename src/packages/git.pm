package packages::git;

use strict;
use warnings;

use lib 'src';
use utilities;
use archive_manager;

our $PRIORITY = 1;

our $VERSION      = "2.9.5";
our $NAME         = "git";
our $SOURCE_URL   = "https://www.kernel.org/pub/software/scm/git/";
our $PACKING_TYPE = "tar.gz";
our $CHECKSUM =
  "8fa575338137d6d850b52d207cf7155cd1f4003ebd698f0fb75f65efb862ef7f";

sub fetch {

    # Construct the archive url
    my $archive_url = "$SOURCE_URL$NAME-$VERSION.$PACKING_TYPE";

    # Download the archive
    archive_manager::download_archive( $archive_url, $CHECKSUM );
}

sub unpack { }

sub configure { }

sub build { }

1;
