#Test the database directly

use lib "../modules";
use TOMETest::DBTest;
use Test::More tests => 7;
use DBI;

my $dbt = TOMETest::DBTest->new();
my %config = $dbt->returnconfig();
isnt (%config, undef);

my $username = $config{'dbiusername'};
isnt ($username, undef);

my $password = $config{'dbipassword'};
isnt ($password, undef);

my $address = $config{'dbihostname'};
isnt ($address, undef);

my $port = $config{'dbiport'};
isnt ($port, undef);

my $database = $config{'dbidbname'};
isnt ($database, undef);

my $dbh = DBI->connect("dbi:Pg:dbname=$database;host=$address;port=$port", $username, $password, { RaiseError => 1, PrintError => 0 });
is ($DBI::errstr, undef);

$dbh->disconnect;
