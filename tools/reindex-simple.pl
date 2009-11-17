use UNIVERSAL::require;
#use Email::Store::DBI "dbi:SQLite:email.db";
use Email::Store::Mail;
my $class = "Email::Store::".shift @ARGV;
$class->require or die $@;
require Email::Store;
Email::Store->import("dbi:SQLite:email.db");

my $iterator = Email::Store::Mail->retrieve_all;
while (my $mail = $iterator->next) {
    $class->on_store($mail);
}
