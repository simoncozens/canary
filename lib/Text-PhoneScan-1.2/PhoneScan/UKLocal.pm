package Text::PhoneScan::UKLocal;
use base 'Text::PhoneScan::Scanner';
my $extension_suffix = __PACKAGE__->extension_suffix;
my $uklocal = qr/(?:[1-9]\d{3}\s+[1-9]\d{3}|[1-9]\d{5})$extension_suffix/;

sub scan { 
    my @rv;
    push @rv, $1 
        while $_[1]->{text} =~ s/(?:\b|^)($uklocal)(\b|$)//;
    return @rv;
}
1;

