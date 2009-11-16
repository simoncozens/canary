package Email::Store::Group;
use Search::ContextGraph;
our $cgfile;
my $cg;

# Organic groups are sets of entities in email's addressings with n>4
# A mail belongs to a group if it matches that group exactly or if n>6
# and its entity set is the near-neighbour of a group with similarity greater
# than epsilon

sub get_cg {
    my $cg = -f $cgfile ? MyCG->retrieve($cgfile) : MyCG->new();
    $cg->{file} = $cgfile;
    return $cg;
}

sub on_store_order { 90 }
sub on_store {
    my ($self, $mail) = @_;
    $cg ||= get_cg();
    
    my @people = map { $_->entity} $mail->addressings;
    return unless @people;
    $cg->add($mail->id, \@people);
}


package MyCG;
use base 'Search::ContextGraph';
sub MyCG::DESTROY { $_[0]->store($_[0]->{file}); }

1;
__DATA__

