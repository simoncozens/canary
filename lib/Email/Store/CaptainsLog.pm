package Email::Store::CaptainsLog;
use 5.006;
use strict;
use warnings;
use Email::Store::DBI;
use base 'Email::Store::DBI';

Email::Store::CaptainsLog->table("captains_log");
Email::Store::CaptainsLog->columns(All => qw/id added text mail/);
Email::Store::CaptainsLog->columns(Primary => qw/id/);
Email::Store::CaptainsLog->has_a(mail => "Email::Store::Mail");
Email::Store::CaptainsLog->has_a(added => 'Time::Piece',
           inflate => sub { Time::Piece->strptime(shift, "%Y-%m-%dT%H:%M:%S") },
           deflate => 'datetime',
         );

__PACKAGE__->set_sql(recent => qq{
    SELECT *
    FROM captains_log
    ORDER BY added DESC
    LIMIT ?
});

CHECK { for (Email::Store->plugins) {
    next unless $_->isa("Email::Store::DBI");
$_->add_trigger(after_create => sub {
    my $thing = shift;
    if ($thing->can("describe")) {
        Email::Store::CaptainsLog->create({
            mail => $thing->mail,
            added => Time::Piece->new(),
            text => $thing->describe()
        })
    }
});
};
}


sub Email::Store::List::Post::describe { 
    my $list = shift->list;
    "Mail belonged to mailing list <a href=\"/list/view/".$list->id."\">".$list->name."</a>"; }

sub Email::Store::NEReference::describe {
    my $ne = shift->named_entity;
    "Found a ".lc($ne->description)." (<a
    href=\"/named_entity/view/".$ne->id."\">".$ne->thing."</a>)";
}

package Email::Store::CaptainsLog;

=head1 NAME

Email::Store::CaptainsLog - Write a log of all the things we've found

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
CREATE TABLE IF NOT EXISTS captains_log (
    id int AUTO_INCREMENT NOT NULL PRIMARY KEY,
    text varchar(4096),
    mail integer,
    added varchar(255)
);

