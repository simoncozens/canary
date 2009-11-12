package Canary::Base;
use strict;
use Data::Page;
use UNIVERSAL::moniker;

sub underlying_class { 
    my $class = shift;
    $class =~ s/Canary/Email::Store/g;
    return $class;
}

sub view {
    my ($self, $mm, @args) = @_;
    my $thing = $self->underlying_class->retrieve($args[0]);
    if ($args[1] eq "setwiki" 
        and $thing->can("wikitext")
        and my $newtext = $mm->{req}->parameters->{"wiki"}) {
        $thing->wikitext($newtext);
        $thing->update;
    }
    $mm->respond("", $self->moniker => $thing);
}

package Canary::Entity;
use base 'Canary::Base';
package Canary::NamedEntity;
use base 'Canary::Base';
sub moniker { "entity" };
sub wiki {
    my ($self, $mm, @args) = @_;
    my $thing = $self->underlying_class->retrieve($args[0]);
    my $res = Plack::Response->new(200);
    $res->content_type('text/plain');
    $res->body($thing->wikitext);
    return $res;
}

package Canary::Address;
use base 'Canary::Base';
sub underlying_class { "Email::Store::Entity::Address" } 

package Canary::Name;
use base 'Canary::Base';
sub underlying_class { "Email::Store::Entity::Name" } 

1;
