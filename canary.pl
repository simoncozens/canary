use lib 'lib';
use Module::Pluggable require => 1, search_path => ["Buscador"];
__PACKAGE__->plugins;
package Canary;
use base 'MicroMaypole';
use Canary;
use Canary::Mail;
use Email::Store qw/dbi:SQLite:email.db/;
use Plack::Builder;

sub interesting {
    return Email::Store::CaptainsLog->search_recent(10);

}

builder {
  enable "Plack::Middleware::Static",
       path => qr{^/chrome/}, root => './';

  Canary->app(model_prefix => "Canary", compiled_templates =>
  "compiled_templates");
};
