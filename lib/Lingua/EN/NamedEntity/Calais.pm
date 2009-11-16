package Lingua::EN::NamedEntity::Calais;
use base 'Exporter';
our @EXPORT = qw/extract_entities/;
use Net::Calais;
my $calais = Net::Calais->new(apikey => $ENV{CALAIS_KEY} || die "You need to set the environment variable CALAIS_KEY");
use JSON;
sub extract_entities {
    my $data = shift;
    my $markup;
    my $attempts = 0; 
    until ($markup) { 
        eval { local $SIG{ALRM} = sub { die "alarm\n" };
        alarm 10;
        $markup = $calais->enlighten($data, contentType => 'text/raw',
    outputFormat=>"Application/JSON");
        alarm 0;
        };
        if ($markup =~ /<Error/ and $attempts++ < 10) { 
        return;
        sleep 5; warn "Failed, retrying"; redo 
        }
    }
    return if $markup =~ /<Error/;
    my $stuff = eval { from_json($markup) } || {};
    my @entities;
    for (grep { $_->{_typeGroup} eq 'entities' } values %$stuff) {
        push @entities, {
            scores => $_->{relevance},
            entity => $_->{name},
            class => lc $_->{_type},
        } unless lc $_->{_type} eq "url";
    }
    return @entities;
}
