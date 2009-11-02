package Text::PhoneScan::Marked;
use base 'Text::PhoneScan::Scanner';
my $phone_words = qr/(?:t|p|Tel|phone|mobile|mob|f|fax|m|telephone)/i;
my $phonestuff = __PACKAGE__->phonestuff;

sub scan { 
    my @rv;
    push @rv, $1 
        while $_[1]->{text} =~ s/(?:\b|^)$phone_words[:.]* \s*($phonestuff)//;
    return @rv;
}
1;

