package package_manager;

use strict;
use warnings;
use lib 'src';
use utilities;

# Package installation paths
our $src_path;
our $unpack_path;
our $build_path;
our $install_path;

# Helper function to safely access package variables
sub get_package_var {
    my ( $pkg, $var_name ) = @_;
    my $package_name = "packages::$pkg";
    no strict 'refs';
    my $value = ${"${package_name}::$var_name"};
    use strict 'refs';
    return $value;
}

# Initialize the package manager with paths
sub init {
    my ( $src, $unpack, $build, $install ) = @_;
    $src_path     = $src;
    $unpack_path  = $unpack;
    $build_path   = $build;
    $install_path = $install;
}

# Fetch a package's source
sub fetch_package {
    my ($pkg) = @_;

    # Load the package module
    my $package_file = "src/packages/$pkg.pm";
    require $package_file;

    # Get package information
    my $name    = get_package_var( $pkg, 'NAME' )    || $pkg;
    my $version = get_package_var( $pkg, 'VERSION' ) || "unknown";

    utilities::color_print( "Fetching $name $version...", "info" );

    # Navigate to the src directory
    chdir($src_path);

    # Call the package's fetch function
    my $package_name = "packages::$pkg";
    no strict 'refs';
    my $fetch_func = \&{"${package_name}::fetch"};
    $fetch_func->() if defined $fetch_func;
    use strict 'refs';
}

# Unpack a package's source
sub unpack_package {
    my ($pkg) = @_;

    # Load the package module
    my $package_file = "src/packages/$pkg.pm";
    require $package_file;

    # Get package information
    my $name    = get_package_var( $pkg, 'NAME' )    || $pkg;
    my $version = get_package_var( $pkg, 'VERSION' ) || "unknown";

    utilities::color_print( "Unpacking $name $version...", "info" );

    # Navigate to the src directory
    chdir($src_path);

    # Call the package's unpack function
    my $package_name = "packages::$pkg";
    no strict 'refs';
    my $unpack_func = \&{"${package_name}::unpack"};
    $unpack_func->($unpack_path) if defined $unpack_func;
    use strict 'refs';
}

# Configure and build a package
sub build_package {
    my ($pkg) = @_;

    # Load the package module
    my $package_file = "src/packages/$pkg.pm";
    require $package_file;

    # Get package information
    my $name    = get_package_var( $pkg, 'NAME' )    || $pkg;
    my $version = get_package_var( $pkg, 'VERSION' ) || "unknown";

    utilities::color_print( "Building $name $version...", "info" );

    # Navigate to the build directory
    chdir($build_path);

    # Call the package's build function
    my $package_name = "packages::$pkg";
    no strict 'refs';
    my $build_func = \&{"${package_name}::build"};
    $build_func->( $unpack_path, $install_path ) if defined $build_func;
    use strict 'refs';
}

# Register a package
sub register_package {
    my ($pkg) = @_;

    # Load the package module
    my $package_file = "src/packages/$pkg.pm";
    require $package_file;

    # Get package information
    my $name    = get_package_var( $pkg, 'NAME' )    || $pkg;
    my $version = get_package_var( $pkg, 'VERSION' ) || "unknown";

    utilities::color_print( "Registering $name $version...", "info" );

    # Navigate to the install directory
    chdir($install_path);

    # Call the package's build function
    my $package_name = "packages::$pkg";
    no strict 'refs';
    my $register_func = \&{"${package_name}::register"};
    $register_func->($install_path) if defined $register_func;
    use strict 'refs';
}

1;

