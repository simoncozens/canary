package Canary::Mail;
use strict;
use Data::Page;

sub view {
    my ($self, $mm, @args) = @_;
    my $mail = Email::Store::Mail->retrieve($args[0]);
    if (defined $args[1] and $args[1] eq "delete_ne") {
        # XXX reindex all emails with references
        my $ne = Email::Store::NamedEntity->retrieve($args[2]);
        if ($ne) { $ne->delete } # Cascading delete takes care of NERefs
    } elsif (defined $args[1] and $args[1] eq "delete_neref") {
        my (@refs) = Email::Store::NERef->search(
            entity => $args[2],
            mail => $args[0]
        );
        $_->delete for @refs;
        # XXX reindex this email
    }

    $mm->respond("mail/view", mail => $mail);
}

sub raw {
    my ($self, $mm, @args) = @_;
    my $mail = Email::Store::Mail->retrieve($args[0]);
    my $r = HTTP::Engine::Response->new;
    $r->headers->header("Content-Type" => "text/plain");
    $r->body($mail->body);
    $r;
}

sub search {
    my ($self, $mm) = @_;
    my $params = $mm->{req}->parameters();
    my $p = Data::Page->new();
    my $hits = Email::Store::Mail->kinosearch_search($params->{terms});
    if (!$hits->total_hits) { return $mm->respond("mail/search"); }
    $p->total_entries($hits->total_hits);
    $p->current_page($params->{page} || 1);
    $p->entries_per_page($params->{epp} || 10);
    $hits->seek($p->first - 1, $p->entries_on_this_page );
    my $highlighter = KinoSearch::Highlight::Highlighter->new(
        excerpt_field  => 'text',
    );
    $hits->create_excerpts( highlighter => $highlighter );
    my @mails;
    my %things;
    while ( my $hashref = $hits->fetch_hit_hashref ) {
        while ($params->{terms} =~ /has:(\w+)/g) { 
            my $thing = $hashref->{$1};
            $things{$thing}++ if $thing;
        }
        my $mail = Email::Store::Mail->retrieve($hashref->{id});
        $mail->{excerpt} = $hashref->{excerpt};
        push @mails, $mail;
    }   

    $self->_suggest_better_terms($mm, $hits, $params->{terms});
    $mm->respond("mail/search", pager => $p, mails => \@mails, things =>
    [keys %things]);
}

sub recent {
    my ($self, $mm, @args) = @_;
    my @mails = Email::Store::Mail->search_recent();
    $mm->respond("mail/recent", mails => \@mails);

}

sub thread {
    my ($self, $mm, @args) = @_;
    my $mail = Email::Store::Mail->retrieve($args[0]);
    my (undef, $noun, $verb) = split /\//,  $mm->{req}->path;
    my $root       = $mail->container->root;

    while (1) {
        last if $root->message->date;
        my @children = $root->children;
        last if (@children>1);
        $root = $children[0];
    }

    if ($verb eq "lurker") { 
       my $lurker     = Mail::Thread::Chronological->new;
       my @root       = $lurker->arrange( $root );
       $mm->respond("mail/lurker", root => \@root, mail => $mail);
    } else {
       $mm->respond("mail/thread", thread => $root, mail => $mail);
    }
}

sub lurker { goto &thread }


sub _suggest_better_terms {
    my ($self, $mm, $hits, $terms) = @_;

}
1;
