use lib 'lib';
use Canary::MasterDB;
use Email::Store 'dbi:SQLite:canary-proto.db';
Canary::MasterDB::User->retrieve(1)->setup_environment;

Email::Store->setup() if !-d $Email::Store::Kinosearch::index_path;
use File::Find;
use File::Slurp;
my $count;
find({wanted => \&wanted, no_chdir => 1}, shift @ARGV);
exit;
sub wanted { 
    my $file = $File::Find::name;
    return unless -f $file;
    return if $file =~ /dovecot/;
    $count++; 
    my $content = read_file($file);
    $content =~ s/\r//g;
    warn $content;
    Email::Store::Mail->store($content);
    #if ($count > 40) { exit }
}
