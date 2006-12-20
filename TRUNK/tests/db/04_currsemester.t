#Test the database directly

use lib "../modules";
use TOMETest::DBTest;
use Test::More tests => 3;
use DBI;

my $dbt = TOMETest::DBTest->new();
my %config = $dbt->returnconfig();
my $username = $config{'dbiusername'};
my $password = $config{'dbipassword'};
my $address = $config{'dbihostname'};
my $port = $config{'dbiport'};
my $database = $config{'dbidbname'};

my $dbh = DBI->connect("dbi:Pg:dbname=$database;host=$address;port=$port", $username, $password, { RaiseError => 1, PrintError => 0 });

#Try and add two semesters, with both of them having the current value set to true.  It should fail on the second one.
my $sth = $dbh->prepare("INSERT INTO semesters (name, current) VALUES (?, ?)");
$sth->execute("2006, Spring", "TRUE");

$sth = $dbh->prepare("INSERT INTO semesters (name, current) VALUES (?, ?)");
eval { $sth->execute("2006, Fall", "TRUE"); };

isnt($@, '');

#Now add a semester with current set to false.  This should succeed.
$sth = $dbh->prepare("INSERT INTO semesters (name, current) VALUES (?, ?)");
eval { $sth->execute("2006, Fall", "FALSE"); };

is($@, '');

#Now update the newly-added semester's current to true.  This should fail.

my ($id) = $dbh->selectrow_array("SELECT currval('public.semesters_id_seq')");

$sth = $dbh->prepare("UPDATE semesters SET current = TRUE WHERE id=?");
eval { $sth->execute($id); };

isnt($@, '');

#Clean up after ourselves
$sth = $dbh->prepare("DELETE FROM semesters");
$sth->execute();

$dbh->disconnect;

