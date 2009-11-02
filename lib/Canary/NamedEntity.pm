package Canary::NamedEntity;
use strict;
use Data::Page;

sub view {
    my ($self, $mm, @args) = @_;
    my $entity = Email::Store::NamedEntity->retrieve($args[0]);
    $mm->respond("named_entity/view", entity => $entity);
}

1;
