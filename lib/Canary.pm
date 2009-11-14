package Canary;
use strict;
use warnings;
use base 'MicroMaypole';
use Canary;
use Canary::Mail;
use Canary::MasterDB;
use Authen::Passphrase;
use Email::Store;

sub authenticate {
    my $self = shift;
    my $sess = $self->{req}->env->{"psgix.session"};
    if (!$sess->get("user") and !try_to_login($self)) {
        return $self->respond("login");
    }
    # XXX Set database up, set correct name of index
    $self->{user} = $sess->get("user");
    Email::Store->import("dbi:SQLite:canary-".$self->{user}->id.".db");
    $Email::Store::KinoSearch::index_path = "emailstore-index-".$self->{user}->id;
    return;
}

sub try_to_login {
    my $self = shift;
    my $params = $self->{req}->parameters;
    my ($p, $u);
    unless($u = $params->{username} and $p = $params->{password}) {
        push @{$self->{messages}}, "Need to give a username and a password to log in";
        return;
    }
    my ($user) = Canary::MasterDB::User->search(username => $u);
    if (!$user) {
        # Don't leak more information than necessary
        push @{$self->{messages}}, "Username or password incorrect";
        return;
    }
    my $real = Authen::Passphrase->from_crypt($user->password);
    if ($real->match($p)) {
        push @{$self->{messages}}, "Login successful";
        $self->{req}->env->{"psgix.session"}->set("user" => $user->id);
        return 1;
    }
    push @{$self->{messages}}, "Username or password incorrect";
    return 0;
}

sub interesting {
    return Email::Store::CaptainsLog->search_recent(10);

}

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
