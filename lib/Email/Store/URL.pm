package Email::Store::URL;
use URI::Title;
use 5.006;
use strict;
use warnings;
use Email::Store::DBI;
use base 'Email::Store::DBI';
use Email::Store::Mail;
use URI::Find::Schemeless::Stricter;

Email::Store::URL->table("url");
Email::Store::URL->columns(All => qw/id mail url title/);
Email::Store::URL->columns(Primary => qw/id/);
Email::Store::URL->has_a(mail => "Email::Store::Mail");
Email::Store::Mail->has_many( urls => "Email::Store::URL" );

sub on_store_order { 80 }

sub on_store {
    my ($self, $mail) = @_;
    my $simple = $mail->body;
    URI::Find::Schemeless::Stricter->new(sub {
        Email::Store::URL->create({
            mail => $mail->id,
            url => "".$_[1],
            title => "".URI::Title::title($_[0]->as_string)
        });
    })->find(\$simple);
}

sub describe {
    my ($url, $title) = ($_[0]->url,$_[0]->title);
    $title ||= "<code>$url</code>";
    qq{Found a URL (<a href="$url">$title</a>)}
}

=head1 NAME

Email::Store::URL - Provides a list of URLs for an email

=head1 SYNOPSIS

Remember to create the database table:

    % make install
    % perl -MEmail::Store="..." -e 'Email::Store->setup'

And now:

    foreach my $e ($mail->urls) {
        print $e->url."\n";
    }

=head1 DESCRIPTION

This module finds URLs within emails

=head1 SEE ALSO

L<Email::Store::Mail>, L<URI::Find::Schemeless::Stricter>.

=head1 AUTHOR

Simon Cozens, L<simon@simon-cozens.org>

This module is distributed under the same terms as Perl itself.

=cut

1;
__DATA__
CREATE TABLE IF NOT EXISTS url (
    id int AUTO_INCREMENT NOT NULL PRIMARY KEY,
    mail varchar(255),                                                 
    url varchar(1024),                                                         
    title varchar(255)
);

