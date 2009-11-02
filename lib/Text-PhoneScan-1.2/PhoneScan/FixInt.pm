package Text::PhoneScan::FixInt;
use base 'Text::PhoneScan::Scanner';
sub scan { 
    $_[1]->{text} =~ s/(^|\b)44 [12]\d{2,}/+$&/g;
    # We'll leave this for the UK scanner to patch up for now.
    #$_[1]->{text} =~ s/\+44 \(0\)\s*/+44 /g; # Don't do that!
    return 
}
1;
