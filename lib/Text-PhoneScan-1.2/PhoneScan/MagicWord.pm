package Text::PhoneScan::MagicWord;
use base 'Text::PhoneScan::Scanner';
my $magic = qr/
number|
phone|
call|
cell|
mobile|
fax|
contact|
ring|
toll free/ix;
my $phonestuff = __PACKAGE__->phonestuff;

sub scan { 
    my @rv;
    my $text = $_[1]->{text};
    my @out;
    for my $t (split /\n\n/, $text) {
        while ($t =~ s/(?:^|\b)$magic [^+\(\d\)]+($phonestuff)//ox) {
            my ($prev, $match, $number) = ($`, $&, $1);
            push @rv, $number if length $number >4
                                and $prev !~ /(card|insurance)\s*$/;
        }
        push @out, $t;
   }
   $_[1]->{text} = join "\n\n", @out;

    return @rv;
}
1;

