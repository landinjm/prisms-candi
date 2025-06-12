package signal_handler;

use strict;
use warnings;

# Set up signal handlers
sub setup_handlers {

    # Store the original signal handlers
    my $original_int  = $SIG{INT};
    my $original_term = $SIG{TERM};
    my $original_quit = $SIG{QUIT};

    # Set up our signal handlers
    $SIG{INT} = sub {
        print "\nReceived interrupt signal. Cleaning up and exiting...\n";

        # Kill all child processes in the same process group
        kill 'INT', -$$;

        # Restore original handler and re-raise the signal
        $SIG{INT} = $original_int;
        kill 'INT', $$;
    };

    $SIG{TERM} = sub {
        print "\nReceived termination signal. Cleaning up and exiting...\n";
        kill 'TERM', -$$;
        $SIG{TERM} = $original_term;
        kill 'TERM', $$;
    };

    $SIG{QUIT} = sub {
        print "\nReceived quit signal. Cleaning up and exiting...\n";
        kill 'QUIT', -$$;
        $SIG{QUIT} = $original_quit;
        kill 'QUIT', $$;
    };
}

1;
