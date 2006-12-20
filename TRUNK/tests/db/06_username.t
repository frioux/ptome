#Test the database directly

use lib "../modules";
use TOMETest::DBTest;
use Test::More tests => 2;
use DBI;

my $dbt = TOMETest::DBTest->new();
my %config = $dbt->returnconfig();
my $username = $config{'dbiusername'};
my $password = $config{'dbipassword'};
my $address = $config{'dbihostname'};
my $port = $config{'dbiport'};
my $database = $config{'dbidbname'};

my $dbh = DBI->connect("dbi:Pg:dbname=$database;host=$address;port=$port", $username, $password, { RaiseError => 1, PrintError => 0 });

#Try and add both MixedCase and mixedcase, verify it returns an error
my $sth = $dbh->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
$sth->execute("MixedCase", "MixedCase@letu.edu", "Blah");

$sth = $dbh->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
eval { $sth->execute("mixedcase", "MixedCase@letu.edu", "Blah"); };

isnt($@, undef);

#Now remove MixedCase try inserting mixedcase again -- it should work this time
$sth = $dbh->prepare("DELETE FROM users WHERE username=?");
$sth->execute("MixedCase");

$sth = $dbh->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
eval { $sth->execute("mixedcase", "MixedCase@letu.edu", "Blah"); };

is($dbh->errstr, undef);

#Clean up after ourselves
$sth = $dbh->prepare("DELETE FROM users WHERE username=?");
$sth->execute("mixedcase");

$dbh->disconnect;

