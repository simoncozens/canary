package Text::PhoneScan::International;
use base 'Text::PhoneScan::Scanner';
my $extension_suffix = __PACKAGE__->extension_suffix;
my $phonestuff = qr/[\.\d\ \t\(\)\-]+\d$extension_suffix/ ;

my $idds =
qr/(?:2(?:1[2368]|2\d|3\d|4\d|5[012345678]|6\d|9[01789]|[07])
     |3(?:5\d|7[012345678]|8[015679]|[0123469])
     |4(?:2[01]|[013456789]\d?) # Blame Romania
     |5(?:0\d|9\d|[12345678])
     |6(?:7[23456789]|8[023456789]|9[012]|[0123456])
     |8(?:5[02356]|8[06]|[1246])
     |9(?:6[012345678]|7[1234567]|9[3456]|[012458])|[17])/x;

sub scan { 
    my @rv;
    push @rv, $1 
        while $_[1]->{text} =~ s/(?:\b|\W|^)((?:\+|00 )\s*\(?\s*$idds\s*\)?[ \t-]+$phonestuff)(\b|$)//x;

    return @rv;
}
1;

