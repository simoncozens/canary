package Text::PhoneScan::France;
use base 'Text::PhoneScan::Scanner';
my $extension_suffix = __PACKAGE__->extension_suffix;
my $match_prefix = __PACKAGE__->match_prefix;

sub scan { 
    my @rv;
    while ($_[1]->{text} =~ /$match_prefix((?:\d{2}[\s\.]+)+)$extension_suffix/g) {
        my $number = $1;
        $number =~ s/^\s+//;
        $number =~ s/\s+$//;
        my $x_number = $number;
        $x_number =~ s/\D+//g;
        if (length $x_number == 10) { 
            $_[1]->{text} =~ s/$number//;
            push @rv, $number;
        }
    }
    return @rv;
}
1;

