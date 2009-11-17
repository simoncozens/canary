use lib 'lib';
use Email::Store "dbi:SQLite:email.db";
    my $hits = Email::Store::Mail->kinosearch_search(shift @ARGV);
    use Data::Dumper;
    while ( my $hashref = $hits->fetch_hit_hashref ) {
        print Dumper($hashref);
        #print $hashref->{id},"\n";
    }

