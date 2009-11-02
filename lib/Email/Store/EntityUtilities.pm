package Email::Store::EntityUtilities;

1;

package Email::Store::Mail;

__PACKAGE__->set_sql(mentioned_entity => qq{
    SELECT DISTINCT mail.message_id 
    FROM named_entity, mail, mail_date
    WHERE
        description = ?
    AND mail.message_id = mail_date.mail
    AND thing = ?
    AND mail.message_id = named_entity.mail
    ORDER BY mail_date.date DESC
});


# This is an evil hack
Email::Store::Entity::Name->set_sql(most_common => qq{
    SELECT name id, count(*) total
        FROM addressing
    WHERE entity = ?
    GROUP BY name
    ORDER BY total
    LIMIT 1
});


Email::Store::Entity::Address->set_sql(most_common => qq{
    SELECT address id, count(*) total
        FROM addressing
    WHERE entity = ?
    GROUP BY address
    ORDER BY total
    LIMIT 1
});

my $sorted = qq{
    SELECT addressing.id
    FROM addressing, mail_date
    WHERE %s = ?
     AND addressing.mail = mail_date.mail
    ORDER BY mail_date.date DESC
};

Email::Store::Addressing->set_sql(name_sorted => sprintf($sorted, "name"));
Email::Store::Addressing->set_sql(entity_sorted => sprintf($sorted, "entity"));
Email::Store::Addressing->set_sql(address_sorted => sprintf($sorted, "address"));

sub mentioned_mails {
    my $self = shift;
    my %mails;
    return unless $self->name;
    for ($self->addressings) {
        $mails{$_->mail->id} = {
            mail => $_->mail,
            role => $_->role
        }
    }
    my @ment = 
        grep {!exists $mails{$_->id}}
    Email::Store::Mail->search_mentioned_entity("person", $self->name);
    #for (@ment) {
    #    $mails{$_->id} ||= {
    #        mail => $_,
    #        role => "mentioned"
    #    }
    #}
    #sort {$b->{mail}->date cmp $a->{mail}->date} values %mails;
}


package Email::Store::Entity;
sub most_common_name { Email::Store::Entity::Name->search_most_common(shift->id)->first }
sub most_common_address { Email::Store::Entity::Address->search_most_common(shift->id)->first }

1;
