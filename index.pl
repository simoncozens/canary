use lib 'lib';
use Email::Store "dbi:SQLite:email.db";
Email::Store->setup if !-d "emailstore-index";
use File::Find;
use File::Slurp;
my $count;
find({wanted => \&wanted, no_chdir => 1}, "maildir/.read-mail-2009-10/") ;
exit;
sub wanted { 
    my $file = $File::Find::name;
    return unless -f $file;
    $count++; 
    my $content = read_file($file);
    $content =~ s/\r//g;
    Email::Store::Mail->store($content);
    #if ($count > 40) { exit }
}
