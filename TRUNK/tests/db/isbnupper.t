#Test the database directly

use lib "../modules";
use TOMETest::DBTest;
use Test::More tests => 6;
use DBI;

my $dbt = TOMETest::DBTest->new();
my %config = $dbt->returnconfig();
my $username = $config{'dbiusername'};
my $password = $config{'dbipassword'};
my $address = $config{'dbihostname'};
my $port = $config{'dbiport'};
my $database = $config{'dbidbname'};

my $dbh = DBI->connect("dbi:Pg:dbname=$database;host=$address;port=$port", $username, $password);
is ($DBI::errstr, undef);

my $sth = $dbh->prepare("INSERT INTO books (isbn, title, author, edition) VALUES (?, ?, ?, ?)");
$sth->execute("007027410x", "Blah", "Blah", "5th");

#Check to see if it actually got inserted
$sth = $dbh->prepare("SELECT count(*) FROM books");
$sth->execute();
is($sth->fetchrow_array(), "1");

#Check to see if the lowercase ISBN exists -- this should return undef
$sth = $dbh->prepare("SELECT isbn FROM books WHERE isbn=?");
$sth->execute("007027410x");
is($sth->fetchrow_array(), undef);

#Check to see if the uppercase ISBN exists -- this should return the uppercase ISBN
$sth = $dbh->prepare("SELECT isbn FROM books WHERE isbn=?");
$sth->execute("007027410X");
is($sth->fetchrow_array(), "007027410X");

#Verify that if the entry is updated to a lowercase value, it automatically gets corrected to uppercase
$sth = $dbh->prepare("UPDATE books SET isbn=? WHERE isbn=?");
$sth->execute("007027410x", "007027410X");

#Check to see if the lowercase ISBN exists -- this should return undef
$sth = $dbh->prepare("SELECT isbn FROM books WHERE isbn=?");
$sth->execute("007027410x");
is($sth->fetchrow_array(), undef);

#Check to see if the uppercase ISBN exists -- this should return the uppercase ISBN
$sth = $dbh->prepare("SELECT isbn FROM books WHERE isbn=?");
$sth->execute("007027410X");
is($sth->fetchrow_array(), "007027410X");
