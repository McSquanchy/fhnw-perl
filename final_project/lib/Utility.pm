package Utility;

use experimental 'signatures';
use File::Spec;
use List::Util 'shuffle';
use Tie::File;
use Text::LineNumber;

our @questions;
our $fh_output;
our $question_separator;

# ------------------------------------------------
#
# Argument Parsing
#
# ------------------------------------------------

sub parse_args {
    my $argc  = keys %{ $_[0] };
    my @paths = ();
    if ( $argc > 2 ) {
        warn "\nToo many arguments. See --help for more information.\n\n";
        die("too_many_args");
    }
    elsif ( $argc == 0 ) {
        warn "\nToo few arguments. See --help for more information.\n\n";
        die("too_few_args");
    }
    elsif ( $argc == 2 && ${ $_[0] }{"help"} ) {
        warn "\nWrong usage. See --help for more information.\n\n";
        die("wrong_args");
    }
    elsif ( $argc == 1 && ${ $_[0] }{"help"} ) {
        _usage();
        exit(0);
    }
    elsif ( $argc == 1 && !${ $_[0] }{"file"} ) {
        error_args();
        die("error_args");
    }
    elsif ( $argc == 1 ) {
        @paths[0] = ${ $_[0] }{"file"};
    }
    else {
        @paths[0] = ${ $_[0] }{"file"};
        @paths[1] = ${ $_[0] }{"output"};
    }
    return @paths;
}

sub error_args {
    warn "\nWrong flags. See --help for more information.\n\n";
}

sub error_file {
    warn "\nSupplied argument isn't a file!\n\n";
}

sub error_access {
    warn "\nSupplied file cannot be read from!\n\n";
}

sub _usage {
    print
"Usage:\n\trandomizer command syntax:\n\n\t\t./randomizer [options] [arguments]\n\n\tGeneric command options:\n\n";
    print "\t\t-f, --file:\tSpecify the file to be processed.\n";
    print "\t\t-o, --output:\tSpecify the output file.\n";
    print "\t\t-h, --help:\tRead more detailed instructions.\n";
    print "\n";
}

# ------------------------------------------------
#
# Strings
#
# ------------------------------------------------

sub get_processed_filename($initialfile) {
    sub {
        sprintf '%04d%02d%02d-%02d%02d%02d',
          $_[5] + 1900, $_[4] + 1, $_[3], $_[2], $_[1], $_[0];
      }
      ->(localtime) . "-" . $initialfile;
}

sub extract_filename($fn) {
    my $system_separator = File::Spec->catfile( '', '' );
    my @split = split /$system_separator/, $fn;
    return $split[-1];
}

# ------------------------------------------------
#
# Logic
#
# ------------------------------------------------

sub find_all_questions(@content) {

    # ^\d+\.(\s|\d)\s?.+
    my @index;
    for ( 0 .. $#content ) {
        if ( $content[$_] =~ /.+/ ) {
            printf( "Found Line At %d\n", $_ );
            $content[$_] = $content[$_];
        }
        else {
            $content[$_] = undef;
        }
    }
    printf( "Total Empty Lines: %s\n", $content[-1] );
}

sub find_answer_lines(@content) {
    my @lines;
    for ( 0 .. $#content ) {
        if ( $content[$_] =~ /(\[\s?\])/ ) {
            push( @lines, $_ );
        }
    }
    return @lines;
}

sub count_questions(@content) {

    # print join("\n", @content);
    my $concat = join( "", @content );

    my @count = ( $concat =~ /(\[\s\].+)/g );
    print @count;

    # for (@content) {
    #     if ($_ =~ /(\s+ \[ \s \] .+)/x) {
    #         $count++;
    #     };
    # }
    # return join("\n", @content);
}

sub split_content(@content) {
    my @separators;
    for ( 0 .. $#content ) {
        if ( $content[$_] =~ /_{10,}/ ) {
            push( @separators, $_ );
        }
    }
    return @separators;
}

sub swap_questions ( $firstsep, $secondsep, $array ) {
    # printf( "%d - %d: ", $firstsep, $secondsep );
    reset 'answer_lines';
    my @answers_lines;
    for ( $firstsep .. $secondsep - 1 ) {
        if ( @{$array}[$_] =~ /\[\s?\]/ ) {
            # print "match, ";
            push( @answer_lines, $_ );
        }
    }

    my @shuffled = shuffle @answer_lines;
    @{$array}[@answer_lines] = @{$array}[@shuffled];
}

sub process_questions($filename) {
    my @array;
    tie @array, 'Tie::File', $filename or die "dmg";
    my @splits = split_content(@array);

    # print join "\n", @splits;
    for ( 0 .. $#splits - 1 ) {
        swap_questions( $splits[$_], $splits[ ( $_ + 1 ) ], \@array );
    }
    if ( $splits[-1] < $#array ) {
        swap_questions( $splits[-1], $#array, \@array );
    }

    untie @array;

    # my $dmg = count_questions(@array);
    # find_all_questions(@array);
    # my @answers = find_answer_lines(@array);
    # print join("\n", @answers);
    # print "\n";
    # printf ("%d\n", $dmg);
}

# sub process_questions ($content ) {
#     my @array;
#     tie @array, 'Tie::File', $content or die "dmg";
#     my @answer_lines;

#     my $count = 0;

#     for ( 0 .. $#array ) {
#         if ( $array[$_] =~ /(\[ \].+)/ ) {

#             # say $array[$_];
#             push( @answer_lines, $_ );
#             $count++;
#         }
#     }

#     my $iterator = 0;
#     while ( $iterator < $#answer_lines ) {
#         @array[
#           $answer_lines[$iterator],
#           $answer_lines[ $iterator + 1 ],
#           $answer_lines[ $iterator + 2 ],
#           $answer_lines[ $iterator + 3 ],
#           $answer_lines[ $iterator + 4 ]
#           ]
#           = @array[
#           shuffle(
#               $answer_lines[$iterator],
#               $answer_lines[ $iterator + 1 ],
#               $answer_lines[ $iterator + 2 ],
#               $answer_lines[ $iterator + 3 ],
#               $answer_lines[ $iterator + 4 ]
#           )
#           ];
#         $iterator += 5;
#     }

#     untie @array;

# }

# ------------------------------------------------
#
# I/O
#
# ------------------------------------------------

sub write_to_file ( $fh, $content ) {
    print $fh $content;
}

sub _swap_lines ( $indexA, $indexB, @file ) {
    my $tmp_line = $file[$indexA];
    $file[$indexA] = $file[$indexB];
    $file[$indexB] = $tmp_line;
}

1;

# ARRAY SWAP: @lines[$i, $i+1] = @lines[$i+1, $i];
# use Statistics::Basics qw< mean mode median >;
# Documentation:
# Overview
# Test-Suite
# How to use
# Code Commentary


sub exists_file($filename) {
    return (!-f $fn_input || !-r $fn_input)
}

sub missing_question($filename, $question_text) {
    printf ("%s:\n\tMissing question: %s\n", $filename, $question_text);
}

sub missing_answer($filename, $answer_text) {
     printf ("%s:\n\tMissing answer: %s\n", $filename, $answer_text);
}