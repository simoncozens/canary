use Test::More 'no_plan';
use Text::PhoneScan;
use Spreadsheet::ParseExcel::Simple;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;


sub phone_ok {
    my ($line, $want) = @_;
    my $s = Text::PhoneScan->new($line);
    my @want = ref $want ? @$want : ($want);
    my @found = $s->numbers;
    ok(eq_set(\@found, \@want), "Phone check: $line") || do {
       my %found = $s->numbers_by_scanner;
       print ("# ", YELLOW, "In string: $line", RESET,"\n");
       for (keys %found) {
           print ("# ", GREEN, "$found{$_} found <$_>", RESET,"\n");
       }
       print ("# ", RED, "Did not find <$_>", RESET,"\n") foreach grep !$found{$_}, @want;
    
    };
}

my $xls = Spreadsheet::ParseExcel::Simple->read('t/test.xls');
foreach my $sheet ($xls->sheets) {
  while ($sheet->has_data) {
    my ($got, $comment, @want) = $sheet->next_row;
		next unless $got;
		phone_ok($got => [ grep $_, @want ]); # Grr again.
  }
}

1;
