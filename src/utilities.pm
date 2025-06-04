package utilities;

use strict;
use warnings;

# Color printing function
#   Example usage:
#     color_print("This is bad text", "bad");
#     color_print("This is good text", "good");
#     color_print("This is warn text", "warn");
#     color_print("This is info text", "info");
#     color_print("This is bold text", "bold");
#     color_print("This is reset text", "reset");
sub color_print {
    my ( $text, $color ) = @_;
    my %colors = (
        'bad'   => "\033[1;31m",    # Bold Red
        'good'  => "\033[1;32m",    # Bold Green
        'warn'  => "\033[1;35m",    # Bold Magenta
        'info'  => "\033[1;34m",    # Bold Blue
        'bold'  => "\033[1m",       # Bold
        'reset' => "\033[0m"        # Reset
    );

    print $colors{$color} . $text . $colors{'reset'} . "\n";
}

# Decompose version string into major, minor, and patch numbers
sub decompose_version {
    my $version = shift;
    my ( $major, $minor, $patch ) = split /\./, $version;
    return ( $major, $minor, $patch );
}

# Check if a version is greater than or equal to another version
#   Example usage:
#     if ( version_greater_equal( $version1, $version2 ) ) {
#       print "Version 1 is greater than or equal to version 2\n";
#     }
sub version_greater_equal {
    my ( $version1, $version2 ) = @_;
    my ( $major1, $minor1, $patch1 ) = decompose_version($version1);
    my ( $major2, $minor2, $patch2 ) = decompose_version($version2);

    if ( $major1 < $major2 ) {
        return 0;
    }
    elsif ( $major1 == $major2 && $minor1 < $minor2 ) {
        return 0;
    }
    elsif ( $major1 == $major2 && $minor1 == $minor2 && $patch1 < $patch2 ) {
        return 0;
    }
    else {
        return 1;
    }
}

# Check if a minor version is less than another version
#   Example usage:
#     if ( version_minor_less_than( $version1, $version2 ) ) {
#       print "Version 1 is less than version 2\n";
#     }
sub version_minor_less_than {
    my ( $version1, $version2 ) = @_;
    my ( $major1, $minor1, $patch1 ) = decompose_version($version1);
    my ( $major2, $minor2, $patch2 ) = decompose_version($version2);

    if ( $major1 < $major2 ) {
        return 1;
    }
    elsif ( $major1 == $major2 && $minor1 <= $minor2 ) {
        return 1;
    }
    else {
        return 0;
    }
}

# Shorten directory with ~
sub shorten_dir {
    my $dir = shift;
    $dir =~ s|^$ENV{HOME}/|~|;
    return $dir;
}

# Check if variable is ON or OFF
sub check_config_value {
    my ( $var_name, $var_value ) = @_;
    if ( $var_value ne "ON" && $var_value ne "OFF" ) {
        color_print(
            "Invalid value for $var_name=$var_value. Expected ON or OFF.",
            "bad" );
        exit 1;
    }
}

# Check if a file exists
sub file_exists {
    my $file = shift;
    return -e $file;
}

# Check if a value is a positive integer
sub is_positive_integer {
    my $value = shift;
    return $value =~ /^\d+$/ && $value > 0;
}

# Check if wget and curl are installed
sub check_download_tools {
    my @download_tools = ();
    my $curl_path      = `which curl`;
    chomp $curl_path;
    if ( $curl_path ne "" ) {
        push @download_tools, "curl";
    }
    my $wget_path = `which wget`;
    chomp $wget_path;
    if ( $wget_path ne "" ) {
        push @download_tools, "wget";
    }
    if ( @download_tools == 0 ) {
        color_print(
            "Error: No download tool found. Please install curl or wget.",
            "bad" );
        exit 1;
    }
    return @download_tools;
}

# Try and guess the OS
sub guess_os {
    my $os = "unknown";
    if ( file_exists("/usr/bin/cygwin1.dll") ) {
        $os = "cygwin";
    }
    elsif ( file_exists("/usr/bin/sw_vers") ) {
        $os = "macos";
    }
    elsif ( file_exists("/etc/os-release") ) {
        $os = "linux";
    }
    return $os;
}

# Try and guess the architecture
sub guess_architecture {
    my $architecture = "unknown";
    if ( file_exists("/usr/bin/uname") ) {
        return `uname -m`;
    }
}

# Get the checksum of a file
sub get_checksum {
    my $file     = shift;
    my $checksum = `sha256sum $file` || "null";
    chomp $checksum;
    $checksum =~ s/^(\S+).*$/$1/;    # Extract everything before the first space
    return $checksum;
}

1;
