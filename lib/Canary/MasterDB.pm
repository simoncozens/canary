package Canary::MasterDB;
use Class::DBI::Loader;
my $loader = Class::DBI::Loader->new(
    dsn => "dbi:SQLite:canary-master.db",
    namespace => "Canary::MasterDB",
    options => { AutoCommit => 1 },
    relationships => 1,
);

package Canary::MasterDB::User;
use strict;
use warnings;

sub setup_environment {
    my $uid = shift->id;
    Email::Store::DBI->set_db(Main => "dbi:SQLite:canary-$uid.db");
    $Email::Store::KinoSearch::index_path = "emailstore-index-$uid";
    $Email::Store::Group::cgfile = "groups-$uid.cng";
}

