package Email::Store::KinoSearch;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.02';
use KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch::InvIndexer;
our $index_path ||= "./emailstore-index";
use Module::Pluggable::Ordered search_path => ["Email::Store"];

sub on_store_order { 99 }
sub on_store {
    my ($self, $mail) = @_;
    my $analyzer = KinoSearch::Analysis::PolyAnalyzer->new( language => 'en' ); 
    my $indexer = KinoSearch::InvIndexer->new(
        invindex => $index_path, 
        create => (!-d $index_path),
        analyzer => $analyzer);
    $self->call_plugins("spec_kinosearch_fields", $indexer);
    my $doc = $indexer->new_doc;
    $self->call_plugins("kinosearch_index", $mail, $doc);
    $indexer->add_doc($doc);
    $indexer->finish;
}

sub kinosearch_index_order { 1 } # I really am the king of this
sub spec_kinosearch_fields_order { 1}
sub spec_kinosearch_fields {
    my ($self, $indexer) = @_;
    $indexer->spec_field(name => "list", analyzed => 0);
    $indexer->spec_field(name => "text", stored => 1);
    $indexer->spec_field(name => $_, stored => 1) for qw/from cc to/;
    $indexer->spec_field(name => "id", analyzed => 0, stored => 1);
    $indexer->spec_field(name => "has", stored => 0);
}
sub kinosearch_index {
    my ($self, $mail, $doc) = @_;
    $doc->set_value(list => join " ", map {$_->name} $mail->lists);
    for (qw(From Cc To)) {
        $doc->set_value(lc $_ => join " ", map {$_->name->name} 
                                       $mail->addressings(role => $_)
        );
    }
    $doc->set_value(text => $mail->simple->body);
    $doc->set_value(id => $mail->message_id);
}

package Email::Store::Mail;
use KinoSearch::Searcher;
my $analyzer = KinoSearch::Analysis::PolyAnalyzer->new( language => 'en' );
my $query_parser = KinoSearch::QueryParser::QueryParser->new(
    analyzer => $analyzer, fields   => [ 'text' ],
    default_boolop => 'AND',
);

my $searcher;

sub kinosearch_search {
    my ($class, $terms) = @_;
 $searcher ||= KinoSearch::Searcher->new(
    invindex => $index_path, 
    analyzer => $analyzer);
    return $searcher->search( query => $query_parser->parse( $terms ) );
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Email::Store::KinoSearch - Search your Email::Store with KinoSearch

=head1 SYNOPSIS

  use Email::Store;
  $Email::Store::KinoSearch::index_path = "/var/db/mailstore_index";
  Email::Store::Mail->store($_) for @mails;

  @some_mails = 
    Email::Store::Mail->kinosearch_search("from:dan list:perl6-internals");
  
  @may_mails = Email::Store::Mail->kinosearch_search_during
            ("from:dan list:perl6-internals", "2004-05-01", "2004-05-31");

=head1 DESCRIPTION

This module adds KinoSearch indexing to Email::Store's indexing. Whenever a
mail is indexed, an entry will be added in the KinoSearch index which is
located at C<$Email::Store::KinoSearch::index_path>. If you don't change
this variable, you'll end up with an index called F<emailstore-index> in
the current directory.

=head1 METHODS

The module hooks into the C<store> method in the usual way, and provides
two new search methods:

=over 3

=item C<kinosearch_search>

This takes a query and returns a list of mails matching that query. The
query terms are by default joined together with the C<OR> operator.

=item C<kinosearch_search_during>

As above, but also takes two ISO format dates, returning only mails in 
that period.

=back

=head1 NOTES FOR PLUG-IN WRITERS

This module provides a hook called C<kinosearch_index>. You
should provide methods called C<kinosearch_index_order> (a
numeric ordering) and C<kinosearch_index>. This last should
expect a C<Email::Store::Mail> object and a hash reference. Write into
this hash reference any fields you want to be searchable:

    package Email::Store::Annotations;
    sub kinosearch_index_order { 10 }
    sub kinosearch_index {
        my ($self, $mail, $hash);
        $hash->{notes} = join " ", $mail->annotations;
    }

Now you should be able to use C<notes:foo> to search for mails with
"foo" in their annotations.

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
