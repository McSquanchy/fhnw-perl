#!/usr/bin/env perl

use v5.32;

use warnings;
use diagnostics;
use experimental 'signatures';

# EXERCISE 4 - Declaring variables
# ----------------------------
#
# a. testing scopes / reassignment of different types.
#
# ----------------------------

package a;
{
    my @loc_cars = qw( Nissan Toyota Porsche Hyundai );
    our @glob_cars = qw( Audi BMW Ferrari Lamborghini );
    say qq(@loc_cars);
    say qq(@glob_cars);
}

package b;

say qq (@a::glob_cars);

# say qq (@a::loc_cars);

my $number = 235.30;

say $number;

$number = "Hello";

say $number;
