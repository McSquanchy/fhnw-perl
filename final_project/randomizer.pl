#!/usr/bin/env perl
use v5.32;

package Randomizer;

use warnings;
use diagnostics;
use lib 'lib/';
use Utility;
use Getopt::Long;
use Try::Catch;
use File::Slurp;
use List::Util 'shuffle';
use experimental 'signatures';

state %args;
state $fn_input;
state $fh_input;
state $fn_output;
state $fh_output;
state %file_properties;

GetOptions( \%args, "file=s", "output=s", "help!", )
  or die(Utility::error_args);

try {
    my @paths = parse_args( \%args );
    $fn_input = $paths[0];

    if ( !-f $fn_input ) {
        Utility::error_file;
        exit(1);
    }
    elsif ( !-r $fn_input ) {
        Utility::error_access;
        exit(1);
    }

    if ( $paths[1] ) {
        $fn_output = $paths[1];
    }
    else {
        $fn_output =
          Utility::get_processed_filename(
            Utility::extract_filename($fn_input) );
    }
    open( $fh_output, ">", $fn_output )
      or die("Can't write to file '$fn_output' [$!]\n");

}
catch {
    warn "Caught error: $_";
    try {
        close($fh_output);
    }
    catch {
        warn "Caught error: $_";
        exit(1);
    }
    exit(1);
};

my $raw_content = read_file($fn_input);
my $replaced_content =
  $raw_content =~ s/\[X\]/\[ \]/gr;    #substitution [X] with [ ]

Utility::write_to_file( $fh_output, $replaced_content );

try {
    close($fh_output);
}
catch {
    warn "Caught error: $_";

}
finally {
    Utility::process_questions($fn_output);
};

sub parse_args($args) {
    my $argc  = keys %{ $args };
    my @paths = ();
    if ( $argc > 2 ) {
        warn "\nToo many arguments. See --help for more information.\n\n";
        die("too_many_args");
    }
    elsif ( $argc == 0 ) {
        warn "\nToo few arguments. See --help for more information.\n\n";
        die("too_few_args");
    }
    elsif ( $argc == 2 &&  $args->{"help"} ) {
        warn "\nWrong usage. See --help for more information.\n\n";
        die("wrong_args");
    }
    elsif ( $argc == 1 && $args->{"help"} ) {
        _usage();
        exit(0);
    }
    elsif ( $argc == 1 && !$args->{"file"} ) {
        error_args();
        die("error_args");
    }
    elsif ( $argc == 1 ) {
        @paths[0] = $args->{"file"};
    }
    else {
        @paths[0] = $args->{"file"};
        @paths[1] = $args->{"output"};
    }
    return @paths;
}