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
use Data::Dumper;

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

state @submission_filenames = split( " ", $args{"submissions"} );
process_master();
process_submissions();

# my %test;
# $test{1.25} = "jasdfksjdfk";
# say $test{1.25};

sub process_master {
    my $text = read_file( $args{"master"} );
    my @raw_questions = split /_{10,}/, $text;

    $master_file{"nr_of_questions"} = $#raw_questions - 1;

    for ( 1 .. $#raw_questions - 1 ) {
        my %question_container;
        my @false_answers;
        my @correct_answers;
        my @question_text;
        my %answers;
        my @question_split = split "\n", $raw_questions[$_];
        my $question;
        for (@question_split) {
            if ( $_ =~ /.+/ && ( $_ !~ /\[\s\]/ && $_ !~ /\[X\]/ ) ) {
                $question .= trim($_);
                $question .= " ";
            }
            elsif ( $_ =~ / \[ \s \] /x ) {
                push( @false_answers, trim($_) );
            }
            elsif ( $_ =~ / \[ X \] /x ) {
                push( @correct_answers, trim($_) );
            }
        }
        # say \@correct_answers;
        $question = trim($question);
c

        my ($question_nr) = $question =~ /(^\d{1,3})/;
        $answers{"true"}                        = \@correct_answers;
        $answers{"false"}                       = \@false_answers;
        $question_container{"question_text"}    = $question;
        $question_container{"question_answers"} = \%answers;
        $master_file{$question_nr}              = \%question_container;

    }

  # say @false_answers;
  # say Dumper($master_file{26}->{"question_answers"}->{"false"}); ACCESS Syntax
  # say $answers->{"true"}[0];
}

sub process_submissions {
    for my $submission (@submission_filenames) {

        # say $submission;
        if ( !-f $submission ) {
            Utility::error_file;
            next();
        }
        elsif ( !-r $submission ) {
            Utility::error_access;
            next();
        }
        my $count         = 0;
        my $file          = read_file($submission);
        my @raw_questions = split /_{10,}/, $file;
        $submissions{$submission}->{"nr_of_questions"} = $#raw_questions - 1;

        for ( 1 .. $#raw_questions - 1 ) {
            my %question_container;
            my @false_answers;
            my @correct_answers;
            my @question_text;
            my %answers;
            my @question_split = split "\n", $raw_questions[$_];
            my $question;

            for (@question_split) {
                if ( $_ =~ /.+/ && ( $_ !~ /\[\s\]/ && $_ !~ /\[X\]/ ) ) {
                    $question .= trim($_);
                    $question .= " ";
                }
                elsif ( $_ =~ / \[ \s \] /x ) {
                    push( @false_answers, trim($_) );
                }
                elsif ( $_ =~ / \[ X \] /x ) {
                    push( @correct_answers, trim($_) );
                }
            }

            $question = trim($question);
            if(!$question) {
                Utility::missing_question($submission, $master_file{$_}->{"question_text"});
            }
            if ($question) {
            my ($question_nr) = $question =~ /(^\d{1,3})/;

            if ( $correct_answers[0] eq
                $master_file{$question_nr}->{"question_answers"}->{"true"}[0] )
            {
                if($#correct_answers == 0) {
                     $count++;
                }
            }

            $answers{"true"}                        = \@correct_answers;
            $answers{"false"}                       = \@false_answers;
            $question_container{"question_text"}    = $question;
            $question_container{"question_answers"} = \%answers;
            $submissions{$submission}               = \%question_container;
            }

        }
        printf("%s: \t\t%d/%d\n",$submission, $count, $#raw_questions - 1);
    }
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
