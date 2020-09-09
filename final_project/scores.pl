#!/usr/bin/env perl
use v5.32;

package Scores;

use warnings;
use diagnostics;
use experimental 'signatures';
use experimental 'smartmatch';

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

# Basic idea
#      master <- read_file(master)
#      create a master hash with the structure:
#           %master = [
#                        $"nr_of questions": int,
#                        %"questions":  [
#                            "1" : [
#                                $"true_answer": string,
#                                @"false_answers": string
#                            ]
#                        ]
# ]
#       split submission-string by \s
#       create submissions hash with the structure:
#            %submssions = [
#                $"nr_of_submissions" = int
#                %"submission1": [
#                    "nr_of_questions": int,
#                    "true_answer": int,
#                    "total_answers": int
#                    "questions": [
#                        "1": [
#                            "true_answer": string,
#                            "false_answers": string
#                        ]
#                    ],
#                    @"missing_questions": string,
#                    @"missing_answers": string
#                ]
#            ]
#
#       go through each submission -> print necessary stats
#       furthermore -> gather statistics over all submissions

state %args;
state %master;
state %results;
state @submission_filenames;
state $verbose = '';

# Task 1 - Get Arguments
# GetOptions("master=s" => \$master_filename, "submissions=s{,}" => \@submission_filenames, 'verbose!' => \$verbose, "help!" => usage(), )
#   or die(Utility::error_args);

$args{"submissions"} = \@submission_filenames;

GetOptions(
    \%args, "master=s",
    "submissions=s{,}" => \@submission_filenames,
    'verbose!', "help" => sub { Utility::usage(); exit(0); }
) or die(Utility::error_args);

# GetOptions("submissions=s{,}" => \@submission_filenames)
#   or die(Utility::error_args);

# my @paths    = parse_args( \%args );
# my $fn_input = $paths[0];

# if ( !-f $fn_input ) {
#     Utility::error_file($fn_input);
#     exit(1);
# }
# elsif ( !-r $fn_input ) {
#     Utility::error_access($fn_input);
#     exit(1);
# }

# state @submission_filenames = split( " ", $args{"submissions"} );
print_header();
process_master();
process_submissions();
evaluate_submissions();

sub process_master {
    Utility::start_master_parse();

    if ( Utility::exists_file( $args{"master"} ) ) {
        Utility::error_access( $args{"master"} );
        exit(1);
    }
    Utility::start_process( $args{"master"} );
    my $file_content = read_file( $args{"master"} );
    my @questions_raw = split /_{10,}/, $file_content;

    my $count = 0;
    foreach my $question (@questions_raw) {

        next if !( trim( join "\n", $question ) =~ /^\d+\.\s/ );

        my %question_container;
        my @false_answers;
        my $true_answer;
        my %answers;
        my $question_string;
        my @question_split = split "\n", $question;
        for my $question_line (@question_split) {
            if ( $question_line =~ /.+/
                && (   $question_line !~ /\[\s\]/
                    && $question_line !~ /\[[X,x]\]/ ) )
            {
                $question_string .= trim($question_line);
                $question_string .= " ";
            }
            elsif ( $question_line =~ / \[ \s \] /x ) {
                push( @false_answers, trim( $question_line =~ s/\[\s\]//r ) );
            }
            elsif ( $question_line =~ / \[ X \] /x ) {
                $true_answer = trim( $question_line =~ s/\[[X,x]\]//r );
            }
        }
        my ($question_nr) = $question_string =~ /(^\d{1,3})/;
        $question_string = trim( $question_string =~ s/^\d{1,3}\.\s//r );
        $question_string =~ s/:$//;
        $answers{"true"}                        = $true_answer;
        $answers{"false"}                       = \@false_answers;
        $question_container{"question_text"}    = $question_string;
        $question_container{"question_answers"} = \%answers;
        $master{$question_nr}                   = \%question_container;
    }
    Utility::file_parsed( scalar(values %master) );
}

sub process_submissions {
    Utility::start_submission_parse();
    for my $submission (@submission_filenames) {
        Utility::start_process($submission);
        if ( Utility::exists_file($submission) ) {
            Utility::error_skip();
            next;
        }

        my $file_content = read_file($submission);
        my $string = "================================================================================
                                  END OF EXAM
================================================================================";

        $file_content =~ s/$string//g;
        my @questions_raw = split /_{10,}/, $file_content;


        my $count = 0;
        foreach my $question (@questions_raw) {

            next if !( trim( join "\n", $question ) =~ /^\d+\.\s/ );

            my %question_container;
            my @false_answers;
            my @true_answers;
            my %answers;
            my $question_string;
            my @question_split = split "\n", $question;
            for my $question_line (@question_split) {
                if (
                    $question_line =~ /.+/
                    && (   $question_line !~ /\[\s\]/
                        && $question_line !~ /\[[X,x]\]/ )
                  )
                {
                    $question_string .= trim($question_line);
                    $question_string .= " ";
                }
                elsif ( $question_line =~ / \[ \s \] /x ) {
                    push( @false_answers,
                        trim( $question_line =~ s/\[\s\]//r ) );
                }
                elsif ( $question_line =~ / \[ X \] /x ) {
                    push( @true_answers,
                     trim( $question_line =~ s/\[[X,x]\]//r ));
                }
            }
            my ($question_nr) = $question_string =~ /(^\d{1,3})/;
            $question_string = trim( $question_string =~ s/^\d{1,3}\.\s//r );
            $question_string =~ s/:$//;
            $answers{"true"}                        = \@true_answers;
            $answers{"false"}                       = \@false_answers;
            $question_container{"question_text"}    = $question_string;
            $question_container{"question_answers"} = \%answers;
            $results{$submission}{$question_nr}     = \%question_container;
            my @master_answers = ($master{$question_nr}{"question_answers"}{"true"}, $master{$question_nr}{"question_answers"}{"false"}->@*);
            my @given_answers = (@true_answers, @false_answers);

            # my %ref = $results{$submission}->%*;
            # say values %ref;

            # foreach (keys %master) {
            #     my @found_questions = (((values %results)->%*){"question_text"}->@*);
            #     say @found_questions;
            #     # if($master{$_}->{"question_text"} ~~ ;
            # }
#             my $cnt = 0;
#          while ( my ( $key, $value ) = each $results{$submission}->%* ) { 
#             if (!($value->{"question_text"} eq $master{$key}{"question_text"})) {
#                 $cnt++;
#             }
# }
            for (0..$#master_answers) {
                if (! ($master_answers[$_] ~~ @given_answers)) {
                    Utility::missing_answer($master_answers[$_], $question_nr);
                }
            }
            $count++;
        }
            my @master_questions;
            my @t;
        for my $key (keys %master) {
            push(@master_questions, $master{$key}{"question_text"});
        }
        # my @arr = keys $results{$submission}->%*;
        # my @test;
        # for (@arr) {
        #     # say ;
        #     push(@test, $results{$submission}{$_}{"question_text"});
        # }
        for my $key (keys $results{$submission}->%*) {
            # say $results{$key}{"question_text"};
            push(@t, $results{$submission}{$key}{"question_text"});
        }
 
        for (@master_questions) {
            if (!($_ ~~ @t)) {
                Utility::missing_question($_);
            }
        }
        # for my $val (@master_questions) {
        #     if ( !($val ~~ @submission_questions)) {
        #         Utility::missing_question($val);
        #     }
        # }
        # say @submission_questions;
        # for my $val (keys $results->{$submission}->@*) {
        #     say $val;
        # }
        # for(values %master) {
        #     for my $question ($_->{"question_text"}) {
        #         if ($question ~~ $results{$submission} ) {

        #         }
        #     }
        # }
        Utility::file_parsed($count);

        # $results{"nr_of_questions"}              = $question_nr;
        # my $file_content          = read_file($submission);
        # my @raw_questions = split /_{10,}/, $file_content;
        # for ( 1 .. $#raw_questions - 1 ) {
        #     my %question_container;
        #     my @false_answers;
        #     my @true_answer;
        #     my @question_text;
        #     my %answers;
        #     my @question_split = split "\n", $raw_questions[$question_line];
        #     my $question;

#     for (@question_split) {
#         if ( $question_line =~ /.+/ && ( $question_line !~ /\[\s\]/ && $question_line !~ /\[X\]/ ) ) {
#             $question .= trim($question_line);
#             $question .= " ";
#         }
#         elsif ( $question_line =~ / \[ \s \] /x ) {
#             push( @false_answers, trim($question_line) );
#         }
#         elsif ( $question_line =~ / \[ X \] /x ) {
#             push( @true_answer, trim($question_line) );
#         }
#     }

#     $question = trim($question);
#     if(!$question) {
#         Utility::missing_question($submission, $master_file{$question_line}->{"question_text"});
#     }
#     if ($question) {
#     my ($question_nr) = $question =~ /(^\d{1,3})/;

       #     if ( $true_answer[0] eq
       #         $master_file{$question_nr}->{"question_answers"}->{"true"}[0] )
       #     {
       #         if($#true_answer == 0) {
       #                 $count++;
       #         }
       #     }

        #     $answers{"true"}                        = \@true_answer;
        #     $answers{"false"}                       = \@false_answers;
        #     $question_container{"question_text"}    = $question;
        #     $question_container{"question_answers"} = \%answers;
        #     $submissions{$submission}               = \%question_container;
        #     }

        # }
        # printf("%s: \t\t%d/%d\n",$submission, $count, $#raw_questions - 1);
    }
}

sub evaluate_submissions {
    Utility::start_evaluation();
    while ( my ( $key, $value ) = each(%results) ) {
        my $questions_found = scalar(keys $value->%*);
        say $questions_found;
        Utility::start_process($key);
        my $count = 0;
        while ( my ( $innerkey, $innervalue ) = each( $value->%* ) ) {
            if ( $innervalue->{"question_answers"}{"true"} ) {

                if ( $master{$innerkey}{"question_answers"}{"true"} eq
                    $innervalue->{"question_answers"}{"true"} )
                {
                    if (
                        scalar(
                            $master{$innerkey}{"question_answers"}{"false"}->@*
                        ) == scalar(
                            $innervalue->{"question_answers"}{"false"}->@*
                        )
                      )
                    {
                        $count++;
                    }
                }

            }

            # say $innervalue->{"question_answers"}{"true"};
            # say $results{$key}{$innerkey}{"question_answers"}{"true"};
        }
        say $count;

        # my $size = scalar (keys $value->%*);
        # say $value{"question_answers"};
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

sub usage {
    print
"Usage:\n\trandomizer command syntax:\n\n\t\t./randomizer [options] [arguments]\n\n\tGeneric command options:\n\n";
    print "\t\t-f, --file:\tSpecify the file to be processed.\n";
    print "\t\t-o, --output:\tSpecify the output file.\n";
    print "\t\t-h, --help:\tRead more detailed instructions.\n";
    print "\n";
}

sub print_header {
    my $text = 
"
 ____                                         
/\  _`\                                       
\ \,\L\_\    ___    ___   _ __    __    ____  
 \/_\__ \   /'___\ / __`\/\`'__\/'__`\ /',__\ 
   /\ \L\ \/\ \__//\ \L\ \ \ \//\  __//\__, `\
   \ `\____\ \____\ \____/\ \_\\ \____\/\____/
    \/_____/\/____/\/___/  \/_/ \/____/\/___/ 

                         created by McSquanchy   
"
printf "%s", $text;
}