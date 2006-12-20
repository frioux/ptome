#Test the database directly

use lib "../modules";
use TOMETest::DBTest;
use Test::More tests => 5;

my $dbt = TOMETest::DBTest->new();

my $sth = $dbt->{dbh}->prepare("INSERT INTO books (isbn, title, author, edition) VALUES (?, ?, ?, ?)");
$sth->execute("007027410x", "Blah", "Blah", "5th");

#Check to see if it actually got inserted
$sth = $dbt->{dbh}->prepare("SELECT count(*) FROM books");
$sth->execute();
is($sth->fetchrow_array(), "1");

#Check to see if the lowercase ISBN exists -- this should return undef
$sth = $dbt->{dbh}->prepare("SELECT isbn FROM books WHERE isbn=?");
$sth->execute("007027410x");
is($sth->fetchrow_array(), undef);

#Check to see if the uppercase ISBN exists -- this should return the uppercase ISBN
$sth = $dbt->{dbh}->prepare("SELECT isbn FROM books WHERE isbn=?");
$sth->execute("007027410X");
is($sth->fetchrow_array(), "007027410X");

#Verify that if the entry is updated to a lowercase value, it automatically gets corrected to uppercase
$sth = $dbt->{dbh}->prepare("UPDATE books SET isbn=? WHERE isbn=?");
$sth->execute("007027410x", "007027410X");

#Check to see if the lowercase ISBN exists -- this should return undef
$sth = $dbt->{dbh}->prepare("SELECT isbn FROM books WHERE isbn=?");
$sth->execute("007027410x");
is($sth->fetchrow_array(), undef);

#Check to see if the uppercase ISBN exists -- this should return the uppercase ISBN
$sth = $dbt->{dbh}->prepare("SELECT isbn FROM books WHERE isbn=?");
$sth->execute("007027410X");
is($sth->fetchrow_array(), "007027410X");

$sth = $dbt->{dbh}->prepare("DELETE FROM books WHERE isbn=?");
$sth->execute("007027410X");
