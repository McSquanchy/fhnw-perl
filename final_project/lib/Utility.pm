package Utility;

use experimental 'signatures';
use File::Spec;

# ------------------------------------------------
#
# Argument Parsing
#
# ------------------------------------------------

sub parse_args {
    my $argc = keys %{$_[0]};
    my @paths = ();
    if ($argc > 2) {
        warn "\nToo many arguments. See --help for more information.\n\n";
        die("too_many_args");
    }
    elsif ($argc == 0) {
        warn "\nToo few arguments. See --help for more information.\n\n";
        die("too_few_args");
    }
    elsif ($argc == 2 && ${ $_[0] }{"help"}) {
        warn "\nWrong usage. See --help for more information.\n\n";
        die("wrong_args");
    }
    elsif ($argc == 1 && ${ $_[0] }{"help"} ) {
        _usage();
        exit(0);
    }
    elsif ($argc == 1 && !${ $_[0] }{"file"} ) {
        error_args();
        die("error_args");
    }
    elsif ($argc == 1) {
        @paths[0] = ${ $_[0] }{"file"};
    } else {
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
    print "Usage:\n\trandomizer command syntax:\n\n\t\t./randomizer [options] [arguments]\n\n\tGeneric command options:\n\n";
    print "\t\t-f, --file:\tSpecify the file to be processed.\n";
    print "\t\t-o, --output:\tSpecify the name of the output file.\n";
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
  ->(localtime) . "-". $initialfile;
}

sub extract_filename($fn) {
    my $system_separator = File::Spec->catfile('', '');
    my @split = split /$system_separator/, $fn;
    return $split[-1];
}

# ------------------------------------------------
#
# Logic
#
# ------------------------------------------------

sub count_questions($content) {
    my $count = 1;
    while ($content =~ /$count/) {
        $count++;
    }
    return $count-1;
}

sub read_question($number, $test) {
    my $text = $test =~ /^.*\b([ ])\b.*$/;
    print $text;
    print "\n";
}

1;

