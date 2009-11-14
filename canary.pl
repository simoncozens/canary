use lib 'lib';
use Canary;
use Module::Pluggable require => 1, search_path => ["Buscador"];
__PACKAGE__->plugins;

use HTTP::Session::Store::File;
use HTTP::Session::State::Cookie;
use Plack::Builder;

builder {
  enable "Plack::Middleware::Static",
       path => qr{^/chrome/}, root => './';
  enable "Plack::Middleware::HTTPSession",
       store => HTTP::Session::Store::File->new(dir => "/tmp/canary"),
       state => HTTP::Session::State::Cookie->new(name => "canarysid", path => "/", domain => "127.0.0.1");
  Canary->app(model_prefix => "Canary", 
              compiled_templates => "compiled_templates"
              templates => ["user_templates", "templates"],
              );
};
