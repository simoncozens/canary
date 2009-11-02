package Email::Store::Recent;
1;

package Email::Store::Mail;
use strict;

__PACKAGE__->set_sql(recent_posts => qq{
    SELECT mail.message_id
    FROM list_post, mail_date, mail
    WHERE
         list_post.list = ?
     AND mail.message_id = list_post.mail
     AND mail.message_id = mail_date.mail
    ORDER BY mail_date.date DESC
});

__PACKAGE__->set_sql(recent => qq{
    SELECT mail.message_id
    FROM mail_date, mail
    WHERE mail.message_id = mail_date.mail
    ORDER BY mail_date.date DESC
});


1;
