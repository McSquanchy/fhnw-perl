#!/usr/bin/env perl

use v5.32;

use warnings;
use diagnostics;
use experimental 'signatures';

# EXERCISE 5 - Generating statistics
# ----------------------------
#
# Reading numbers from STDIN into a list and
# printing avg, median, modes.
#
# ----------------------------

my @list = ();
while ( readline() ) {
    chomp($_);
    last if ( $_ eq ' ' );
    push( @list, $_ );
}

@list = sort { $a <=> $b } @list;

my $median = $list[ $#list / 2 ];

my $sum = 0;
for my $val (@list) {
    $sum += $val;
}
my $max_occurence   = 0;
my $current_element = $list[0];

for my $var (@list) {
    if ( $var == $current_element ) {
        $max_occurence += 1;
    }
    else {
        $current_element = $var;
    }
}

my $avg = $sum / ( $#list + 1 );

for ( 0 .. $#list ) {
    $list[ $_ % ( $#list + 1 ) ] += ( $#list + 1 );
}
our $max = $list[0];
my $max_index = 0;

for ( 0 .. $#list ) {
    if ( abs( $list[$_] ) > $max ) {
        $max       = abs( $list[$_] );
        $max_index = $_;
    }
}

for ( 0 .. $#list ) {
    $list[$_] = $list[$_] % $#list;
}

say qq(Range: \t\t$list[0] / $list[-1]);
say qq(Average: \t$avg);
say qq(Median: \t$median);
say qq(Mode: \t$list[$max_index]);
