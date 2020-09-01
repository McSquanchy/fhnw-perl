#!/usr/bin/env perl

use v5.32;

use warnings;
use diagnostics;

use Getopt::Long;

my %args;

GetOptions( \%args, "f=s", "help!", ) or die("Invalid Arguments!\n");

if($args{"help"}) {
  print ("Supply a master file using -f <filename>\n");
  exit 0;
}

die "Missing -f" unless $args{"f"};

say qq($args{"f"});
