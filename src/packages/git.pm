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

sub fetch { }

sub unpack { }

sub configure { }

sub build { }

1;
