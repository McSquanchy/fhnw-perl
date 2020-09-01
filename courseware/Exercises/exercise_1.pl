#!/usr/bin/env perl

use v5.32;

use warnings;
use diagnostics;
use experimental 'signatures';

# EXERCISE 3 - Messing about with some Perl code
# ----------------------------
#
# a. Add (sub)planet Eris.
# b. If you remove "sort", then the order will be random.
# c. Without "sort keys", the prints will still be random.
# d. 'strict' will not be active.
# e. You get an error because %worlds has not been initialized in this scope.
# f. Variables will not be expanded.
# g. You get an error (using strict) because the variable hasn't been initialized.
# h. You get an error because $planet is used within the loop. You'd need to use $_.
# i. Then the keys are not printed because the access $worlds{$planet} is not valid. 
#
# ----------------------------

my %worlds = (
    Mercury => "Fleet in the heat",
    Venus   => "Beauty veiled in mystery",
    Earth   => "Cradle of life",
    Mars    => "Bringer of war",
    Jupiter => "Lord of the system",
    Saturn  => "Ringéd wonder",
    Neptune => "The not-particularly interesting",
    Uranus  => "Bringer of rude puns",
    Pluto   => "...is no longer a planet!",
    Eris    => "isn't a planet either!"
);

for my $planet ( sort keys %worlds ) {
    say "Hello, $planet:\t$worlds{$planet}";
}
