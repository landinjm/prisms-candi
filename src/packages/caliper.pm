package packages::caliper;

use strict;
use warnings;

use lib 'src';
use utilities;

our $PRIORITY = 14;

sub fetch { }

sub unpack {
    my $unpack_path = shift;
}

sub build {
    my ( $unpack_path, $install_path ) = @_;
}

sub register {
    my $install_path = shift;
}

1;
