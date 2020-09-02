#!/usr/bin/env perl
use v5.32;

use warnings;
use diagnostics;
use lib 'lib';
use Utility;


package Main;

use Getopt::Long;
use Try::Catch;
use File::Slurp;

state %args;
state $fn_input;
state $fh_input;
state $fn_output;
state $fh_output;
state %file_properties;

GetOptions( \%args, "file=s", "output=s", "help!", ) or die(Utility::error_args);

try {
    my @paths = Utility::parse_args( \%args );
    $fn_input = $paths[0];

    if(!-f $fn_input) {
        Utility::error_file;
        exit(1);
    }
    elsif (!-r $fn_input) {
        Utility::error_access;
        exit(1);
    }

    if ($paths[1]) {
       $fn_output = $paths[1];
    } else {
       $fn_output = Utility::get_processed_filename(Utility::extract_filename($fn_input));
    }
    say $fn_output;
    open($fh_output, ">", $fn_output ) or die ("Can't write to file '$fn_output' [$!]\n");
    
} catch {
    warn "Caught error: $_";
    try {
        close($fh_output);
    } catch {
        warn "Caught error: $_";
        exit(1);
    }
    exit(1);
};



my $file_content = read_file($fn_input);
my $test = $file_content =~ s/\[X\]/\[ \]/gr; #substitution [X] with [ ]
# $file_properties{"no_of_questions"} = Utility::count_questions($file_content);
# say $file_properties{"no_of_questions"};

# say $file_content =~ /1. /;

# Utility::read_question(15, $file_content);

# for(1..$file_properties{"no_of_questions"}) {
#     Utility::read_question($_, $file_content);
# }

# $file_content =~ s/\[X\]/\[ \]/; #substitution [X] with [ ]

# say pos($file_content);
print $fh_output $test;


# close($fh_input);
# close($fh_output);


# system ("rm -f $fn_output");

# close($fh_input);
# close($fh_output);
