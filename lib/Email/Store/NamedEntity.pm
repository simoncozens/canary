package Email::Store::NamedEntity;
use 5.006;
use WWW::Wikipedia;
use strict;
use warnings;
our $VERSION = '1.3';
use Email::Store::DBI;
use base 'Email::Store::DBI';
use Email::Store::Mail;

Email::Store::NamedEntity->table("named_entity");
Email::Store::NamedEntity->columns(All => qw/id thing description wikitext/);
Email::Store::NamedEntity->columns(Primary => qw/id/);

package Email::Store::NEReference;
use base 'Email::Store::DBI';
Email::Store::NEReference->table("ne_reference");
Email::Store::NEReference->columns(All => qw/id mail named_entity score/);
Email::Store::NEReference->columns(Primary => qw/id/);
Email::Store::NEReference->has_a(mail => "Email::Store::Mail");
Email::Store::NEReference->has_a(named_entity => "Email::Store::NamedEntity");
Email::Store::NamedEntity->has_many(mails => [ "Email::Store::NEReference" => "mail" ]);
Email::Store::Mail->has_many(named_entities => [ "Email::Store::NEReference" => "named_entity" ]);

package Email::Store::NamedEntity;

use Text::MediawikiFormat 'wikiformat';

sub wikihtml { wikiformat shift->wikitext }

my %interesting = map {$_=>1} qw(city company country facility faxnumber
holiday industryterm medicalcondition medicaltreatment movie musicalbum
musicgroup naturalfeature organization operatingsystem person
phonenumber product programminglanguage provinceorstate publishedmedium
radioprogram radiostation sportsevent sportsleague technology tvshow );

sub on_store_order { 80 }

sub on_store {
    my ($self, $mail) = @_;
    my $simple = $mail->simple;
    require Lingua::EN::NamedEntity::Calais;
    my $body = ($simple->body);

    foreach my $e (Lingua::EN::NamedEntity::Calais::extract_entities($body)) 
    { 
        my $class = $e->{class};
        my $score = $e->{scores} || 0;
        next unless $interesting{$class};
        my $ref = Email::Store::NamedEntity->find_or_create({
            thing => $e->{entity},
            description => $class,
        });
        if (!$ref->wikitext) {
            my $language = ($mail->languages)[0];
            $language = $language ? $language->language : "en";
            my $wiki = WWW::Wikipedia->new(language => $language);
             my $result = $wiki->search( $e->{entity});
             if ( $result and $result->text() ) {
                my $text = $result->text;
                1 while $text =~ s/\{\{.*?\}\}//sm;
                1 while $text =~ s/<ref>.*?<\/ref>//sm;
                 $ref->wikitext($text);
             } else { $ref->wikitext("No information found about this") }
            $ref->update;
        }
        $ref->add_to_mails({mail => $mail->id, score => $score });
    }
}

sub spec_kinosearch_fields_order { 80 }

sub spec_kinosearch_fields {
    my ($self, $indexer) = @_;
    $indexer->spec_field(name => $_) for keys %interesting;
}

sub kinosearch_index_order { 80 }

sub kinosearch_index {
    my ($self, $mail, $doc) = @_;
    
    my %topics;
    foreach my $e ($mail->named_entities) {
        push @{$topics{lc($e->description)}}, lc($e->thing);
    }   
    
    foreach my $key (keys %topics) {
        $doc->set_value($key => join ' ', @{$topics{$key}});
        $doc->set_value(has => $doc->get_value("has")." ".$key);
    }
}


=head1 NAME

Email::Store::NamedEntity - Provides a list of named entities for an email

=head1 SYNOPSIS

Remember to create the database table:

    % make install
    % perl -MEmail::Store="..." -e 'Email::Store->setup'

And now:

    foreach my $e ($mail->named_entities) {
        print $e->thing," which is a ", $e->description,"(score=",$e->score(),")\n";
    }

=head1 DESCRIPTION

C<Named entities> is the NLP jargon for proper nouns which represent people, 
places, organisations, and so on. Clearly this is useful meta data to extract 
from a body of emails.

This extension for C<Email::Store> adds the C<named_entity> table, and exports
the C<named_entities> method to the C<Email::Store::Mail> class which returns 
a list of C<Email::Store::NamedEntity> objects.

A C<Email::Store::NamedEntity> object has three fields -

=over 4
    
=item thing

The entity we've extracted e.g "Bob Smith" or "London" w

=item description 

What class of entity it is e.g "person", "organisation" or "place" 

=item score

How likely like it is to be that class.

=back

C<Email::Store::NamedEntity> will also attempt to index each field
so that if you ahve the C<Email::Store::Plucene> module installed 
then you could search using something like

    place:London


=head1 SEE ALSO

L<Email::Store::Mail>, L<Lingua::EN::NamedEntity>.

=head1 AUTHOR

Simon Wistow, C<simon@thegestalt.org>

This module is distributed under the same terms as Perl itself.

=cut

1;
__DATA__
CREATE TABLE IF NOT EXISTS named_entity (
    id int AUTO_INCREMENT NOT NULL PRIMARY KEY,
    mail varchar(255),
    thing varchar(255),
    description varchar(60),
    wikitext text
);

CREATE TABLE IF NOT EXISTS ne_reference (
    id integer NOT NULL auto_increment primary key,
    named_entity integer,
    score float(4,2),
    mail varchar(255)
);

