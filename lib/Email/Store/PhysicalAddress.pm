package Email::Store::PhysicalAddress;
use Geo::Coder::Google;

use Email::Store::DBI;
use base 'Email::Store::DBI';
use Email::Store::Mail;
use URI::Find::Schemeless::Stricter;

Email::Store::PhysicalAddress->table("physical_address");
Email::Store::PhysicalAddress->columns(All => qw/id mail address lat long zoom/);
Email::Store::PhysicalAddress->columns(Primary => qw/id/);
Email::Store::PhysicalAddress->has_a(mail => "Email::Store::Mail");
Email::Store::Mail->has_many( physical_addresses => "Email::Store::PhysicalAddress" );

my $us_state = qr/(?:A[LKSZREAEEEP]|
   C[AOT]|D[EC]|F[ML]|G[AU]|HI|I[DLNA]|K[SY]|LA|M[EHDAINSOTP]|N[EVHJMYCD]|
   O[HKR]|P[WAR]|RI|S[CD]|T[NX]|UT|V[TIA]|W[AVIY])/x;
my $uk_post_town =
   qr/(?:AL|B[ABDHLNRST]?|C[ABFHMORTVW]|D[ADEGHLNTY]|E[CHNX]?|F[KY]|
   G[LUY]?|H[ADGPRSUX]|I[GMPV]|JE|K[ATWY]|L[ADELNSU]?|M[EKL]?|N[EGNPRW]?|
   O[LX]|P[ORAEHL]|R[GHM]|S[AEGKLMNOPRSTWY]?|T[ADFNQRSW]|UB|W[ACDFNRSV]?|
   YO|ZE)/x;

my $uk_postcode = qr/$uk_post_town\d{1,3}[ \t]+\d{1,2}[A-Z][A-Z]/;
my $us_zipcode = qr/$us_state[ \t]+\d{5}/;

sub on_store_order { 80 }

sub on_store {
    my ($self, $mail) = @_;
    my @lines = split /\n/, $mail->simple->body;
    my @found;
    my $last =0;

    for (0..$#lines) {
        if ($lines[$_] =~ /(.*\b($uk_postcode|$us_zipcode)\b)/) {
            if ($_ - $last > 10) { $last = $_-10 } # Max of 10 lines
            my $address = join "\n", @lines[$last+1..$_];
            # Trim whitespace and quoters
            $address =~ s/^\s*
                           (?:[A-Z][A-Z]>)? # SUPERCITE
                           [\s>:]+//msgox;
            if ($address) { push @found, $address }
        } elsif ($lines[$_] !~ /\w/) {
            $last = $_;
        }
    }

    for (@found) {
        my ($address, $lat, $long, $zoom) = narrow($_);
        Email::Store::PhysicalAddress->create({
            mail => $mail->id,
            address => $address,
            lat => $lat,
            long => $long,
            zoom => $zoom
        });
    }
}

sub describe {
    my $address = shift->address;
    qq{Found an address ($address</a>)}
}

sub narrow {
    my $address = shift;
    my $geocoder = Geo::Coder::Google->new(apikey => $ENV{GOOGLE_KEY} );
    my $location = $geocoder->geocode( location => $address );
    return ($address) if !$location;
    $address = $location->{address} || $address;
    return ($address, $location->{Point}{coordinates}[0],
     $location->{Point}{coordinates}[1], $location->{AddressDetails}{Accuracy});
}


__DATA__
CREATE TABLE IF NOT EXISTS physical_address (
    id int AUTO_INCREMENT NOT NULL PRIMARY KEY,
    mail varchar(255),                                                 
    address text,
    lat varchar(255),
    long varchar(255),
    zoom varchar(255)
);

