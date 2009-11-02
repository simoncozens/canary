package Text::PhoneScan; use Carp;

require 5.005_62; # For qr//
use strict;
use warnings;
our $VERSION="1.2";

=head1 NAME

Text::PhoneScan - Find phone numbers in text

=head1 SYNOPSIS

  use Text::PhoneScan;
  my $scanner = Text::PhoneScan->new($text,
                                     scanners => ['Marked', 'Oftel', 'UK']);
  my @numbers = $scanner->numbers;
  my %numbers = $scanner->numbers_by_scanner;

=head1 DESCRIPTION

This module examines a chunk of text and tries to return any telephone
numbers it finds. It has a pluggable back-end system which determines
which heuristics it uses to extract numbers. 

=head1 METHODS

=head2 new($text, scanners=>[...])

This creates a new scanner with a given piece of text, and, optionally,
specifies which backend modules to use. Currently available scanners
are:

=over 3

=item Marked

This tries to pick out numbers which are 'marked' in some way - for
instance, prefixed by "Tel:" or "P:". 

=item MagicWord

This tries to pick out numbers marked by 'magic words', such as "Call me
on XXX YYYYYY".

=item Oftel

Returns numbers which conform to the UK's OfTel recommended layouts.

=item UK

Returns other numbers which match known UK exchanges.

=item International

Returns numbers which are begin "+" and a valid country code.

=item US

Returns numbers which match known US and Canada exchanges.

=item France

Matches French phone numbers

=item NoISBN

Removes things which look more like ISBNs than phone numbers.

=item FixInt

Normalises international dialing numbers - inserts the "+" prefix where
it's missing, removes trunk codes, etc.

=item UKLocal

Returns UK local dialing numbers; this is the most vague of all. 

=back

The default set of scanners is pretty good, but errs on the side of
returning too many numbers rather than too few. If, for instance, you
know you're never going to be dealing with international phone numbers,
you may want to customise the list of scanners; remember that order is
important.

=cut

my $def_scanners = 
    [qw(NoISBN Marked MagicWord FixInt International Oftel US France UK UKLocal)];

sub new {
    my ($class, $text, %options) = @_;
    croak "No text given to scan for numbers!" unless $text;
    my $obj = bless {
        text => $text,
        scanners => ($options{scanners}||$def_scanners)
    }, $class;
    for (@{$obj->{scanners}}) {
        $_="Text::PhoneScan::$_" unless /::/;
        eval "require $_";
        if ($@) { croak "Problem loading scanner $_: $@" }
    }
    return $obj;
}

=head2 numbers 

Returns the phone numbers found in the text.

=cut

sub numbers {
    my $self = shift;
    my %stuff = $self->numbers_by_scanner; 
    return keys %stuff;
}

=head2 numbers_by_scanner

Returns a hash with the phone numbers as the keys and the scanner which
found each number as the values.

=cut

sub numbers_by_scanner {
    my $self = shift;
    $self->_find_em unless exists $self->{found};
    return %{$self->{numbers}};
}

sub _find_em {
    my $self = shift;
    $self->{found} = 1;
    for my $scanner (@{$self->{scanners}}) {
        do {
            next unless $_;
            s/^\s+//; s/\s+$//;
            $self->{numbers}{$_} = $scanner
        } for $scanner->scan($self);
    }
    for (keys %{$self->{numbers}}) {
        delete $self->{numbers}->{$_}
            unless $self->{numbers}->{$_}->check($_);
    }
}

package Text::PhoneScan::Scanner;
my $extension_suffix = qr/\s*(?:(?:ext|x)[\s.:]*\d+)?/i ;
sub extension_suffix { $extension_suffix };
sub match_prefix { qr/(?:^|\b)(?<![=])/ };
sub phonestuff { qr/\+?[\d\ \t\(\)-]+\d$extension_suffix/ };
sub check {1}
sub scan  {}

=head1 AUTHOR

Simon Cozens C<simon@kasei.com>

=head1 SEE ALSO

perl(1).

=cut
