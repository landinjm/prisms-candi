package utilities;

use strict;
use warnings;

#############################################################
# Color printing function
#   Example usage:
#     color_print("This is red text", "red");
#     color_print("This is green text", "green");
#     color_print("This is yellow text", "yellow");
sub color_print {
    my ( $text, $color ) = @_;
    my %colors = (
        'red'     => "\e[31m",
        'green'   => "\e[32m",
        'yellow'  => "\e[33m",
        'blue'    => "\e[34m",
        'magenta' => "\e[35m",
        'cyan'    => "\e[36m",
        'white'   => "\e[37m",
        'reset'   => "\e[0m"
    );

    print $colors{$color} . $text . $colors{'reset'} . "\n";
}

1;
