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

#Try and add both MixedCase@letu.edu and mixedcase@letu.edu, verify it returns an error
my $sth = $dbh->prepare("INSERT INTO patrons (email, name) VALUES (?, ?)");
$sth->execute("MixedCase@letu.edu", "Blah");

$sth = $dbh->prepare("INSERT INTO patrons (email, name) VALUES (?, ?)");
eval { $sth->execute("mixedcase@letu.edu", "Blah"); };

isnt($@, undef);

#Now remove MixedCase@letu.edu and try inserting mixedcase@letu.edu again -- it should work this time
$sth = $dbh->prepare("DELETE FROM patrons WHERE email=?");
$sth->execute("MixedCase@letu.edu");

$sth = $dbh->prepare("INSERT INTO patrons (email, name) VALUES (?, ?)");
$sth->execute("mixedcase@letu.edu", "Blah");

is($dbh->errstr, undef);

#Clean up after ourselves
$sth = $dbh->prepare("DELETE FROM patrons WHERE email=?");
$sth->execute("mixedcase@letu.edu");

$dbh->disconnect;

