package Text::PhoneScan::NoISBN;
use base 'Text::PhoneScan::Scanner';
sub scan { $_[1]->{text} =~ s/IS[SB]N\D+\d+x?//gi; return }
1;
