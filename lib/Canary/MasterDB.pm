package Canary::MasterDB;
use Class::DBI::Loader;
my $loader = Class::DBI::Loader->new(
    dsn => "dbi:SQLite:canary-master.db",
    namespace => "Canary::MasterDB",
    options => { AutoCommit => 1 },
    relationships => 1,
);
