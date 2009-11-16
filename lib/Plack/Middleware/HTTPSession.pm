package Plack::Middleware::HTTPSession;
use Plack::Request;
use Plack::Response;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use HTTP::Session;
 
__PACKAGE__->mk_accessors(qw( state store ));
 
sub call {
    my $self = shift;
    my $env = shift;
    $env->{'psgix.session'} =  HTTP::Session->new(
        state => $self->state,
        store => $self->store,
        request => Plack::Request->new($env)
    );
 
    my $res = Plack::Response->new(@{ $self->app->($env) });
    $env->{'psgix.session'}->response_filter($res);
    $env->{'psgix.session'}->finalize();
    $res->finalize();
}
 
1;
