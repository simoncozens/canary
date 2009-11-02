package Text::PhoneScan::Oftel;
use base 'Text::PhoneScan::Scanner';
my $extension_suffix = __PACKAGE__->extension_suffix;
# Oftel recommended presentations with brackets
my $oftel_b = qr/
             (\(0\d{3}\) \s+ \d{3} \s+ \d{4}|
             \(0\d{2}\) \s+ \d{4} \s+ \d{4}|
             \(0\d{4}\) \s+ \d{3} \s+ \d{3})/x;
my $oftel = qr/(01\d{2} \s+ \d{3} \s+ \d{4}|
                01\d{3} \s+ \d{3} \s+ \d{3}|
                02\d    \s+ \d{4} \s+ \d{4}|
                0\d{4}  \s+ \d{3} \s+ \d{3})/x;
# Bracketed Lax Oftel:
my $oftel_bl = qr/(\(0\d{3}\) \s* \d{3} \s+ \d{4}|
                   \(0\d{2}\) \s* \d{4} \s+ \d{4}|
                   \(0\d{4}\) \s* \d{3} \s+ \d{3})/x;

# Unbracketed Lax Oftel:
my $oftel_l = qr/(01\d{2} \s* \d{7}|
                  01\d{3} \s* \d{6}|
                  02\d    \s* \d{8})/x;

sub scan { 
    my @rv;

    push @rv, $1 
        while $_[1]->{text} =~ s/($oftel_b$extension_suffix)(\b|$)//sm;
    push @rv, $1 
        while $_[1]->{text} =~ s/(?:\b|^)($oftel$extension_suffix)(\b|$)//sm;
    push @rv, $1 
        while $_[1]->{text} =~ s/($oftel_bl$extension_suffix)(\b|$)//sm;
    push @rv, $1 
        while $_[1]->{text} =~ s/(?:\b|^)($oftel_l$extension_suffix)(\b|$)//;

    return @rv;
}

sub prune { }
1;

