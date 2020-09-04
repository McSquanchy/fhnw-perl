#!/usr/bin/env perl
use v5.32;

package Scores;

use warnings;
use diagnostics;
use experimental 'signatures';

use lib 'lib/';
use Utility;
use Getopt::Long;
use Try::Catch;
use String::Util "trim";
use File::Slurp;

####################################################################################################
#
# 1b) Get student scores
#
# Usage:
#    ./scoring.pl <master-file> <submission1>, <submission2>, ...
#
# Basic Task:
#    Compare each <submission#> against <master-file> and return
#    the fraction (correct answers)/(number of raw_questions)
# Rules:
#    only one answer per question, otherwise 0 points
#    no answer -> 0 points
#  Output:
#    exam1/student_000001.txt...........15/20
#    exam1/student_000042.txt...........18/20
#    exam1/student_Beeblebrox.txt........3/07
#    exam1/student_extra.txt............11/12
#
#####################################################################################################

state %args;
state %submissions;
state %master_file;
state %results;

# Task 1 - Get Arguments
GetOptions( \%args, "master=s", "submissions=s", "help!", )
  or die(Utility::error_args);

my @paths    = parse_args( \%args );
my $fn_input = $paths[0];

if ( !-f $fn_input ) {
    Utility::error_file;
    exit(1);
}
elsif ( !-r $fn_input ) {
    Utility::error_access;
    exit(1);
}

state @submissions = split( " ", $args{"submissions"} );

process_master();

# my %test;
# $test{1.25} = "jasdfksjdfk";
# say $test{1.25}; 

sub process_master {
    my $text = read_file( $args{"master"} );
    my @raw_questions = split /_{10,}/, $text;
    # $master_file{"nr_of_questions"} = $#raw_questions - 1;
    my %answers;
    my @question_texts;
    my @false_answers;
    my @correct_answers;
    for ( 1 .. $#raw_questions-1) {
        my @question_split = split "\n", $raw_questions[$_];
        my $question;
        for (@question_split) {
            if ( $_ =~ /.+/ && ( $_ !~ /\[\s\]/ && $_ !~ /\[X\]/ ) ) {
                $question .= trim($_);
                $question .= " ";
            }
            elsif ( $_ =~ / \[ \s \] /x ) {
                push(@false_answers, trim($_));
            }
            elsif ( $_ =~ / \[ X \] /x ) {
                push(@correct_answers, trim($_));
            }
        }
        $question = trim($question);

        my ($question_nr) = $question =~ /(^\d{1,3})/;
        push( @question_texts, $question );
    }
    # say @false_answers;

    $master_file{"question_texts"} = \@question_texts;
}

sub parse_args($args) {
    my $argc  = keys %{$args};
    my @paths = ();
    if ( $argc > 2 ) {
        warn "\nToo many arguments. See --help for more information.\n\n";
        die("too_many_args");
    }
    elsif ( $argc == 0 ) {
        warn "\nToo few arguments. See --help for more information.\n\n";
        die("too_few_args");
    }
    elsif ( $argc == 2 && $args->{"help"} ) {
        warn "\nWrong usage. See --help for more information.\n\n";
        die("wrong_args");
    }
    elsif ( $argc == 1 && $args->{"help"} ) {
        _usage();
        exit(0);
    }
    elsif ( $argc != 2 && !( $args->{"master"} && $args->{"submissions"} ) ) {
        error_args();
        die("error_args");
    }
    else {
        @paths[0] = $args->{"master"};
        @paths[1] = $args->{"submissions"};
    }
    return @paths;
}
