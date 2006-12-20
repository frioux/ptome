#Test the database directly

use lib "../modules";
use TOMETest::DBTest;
use Test::More tests => 2;

my $dbt = TOMETest::DBTest->new();

#Try and add both MixedCase@letu.edu and mixedcase@letu.edu, verify it returns an error
my $sth = $dbt->{dbh}->prepare("INSERT INTO patrons (email, name) VALUES (?, ?)");
$sth->execute("MixedCase@letu.edu", "Blah");

$sth = $dbt->{dbh}->prepare("INSERT INTO patrons (email, name) VALUES (?, ?)");
eval { $sth->execute("mixedcase@letu.edu", "Blah"); };

isnt($@, undef, "Database doesn't allow duplicate emails to be inserted");

#Now remove MixedCase@letu.edu and try inserting mixedcase@letu.edu again -- it should work this time
$sth = $dbt->{dbh}->prepare("DELETE FROM patrons WHERE email=?");
$sth->execute("MixedCase@letu.edu");

$sth = $dbt->{dbh}->prepare("INSERT INTO patrons (email, name) VALUES (?, ?)");
$sth->execute("mixedcase@letu.edu", "Blah");

is($dbt->{dbh}->errstr, undef, "But we can still insert things later");

#Clean up after ourselves
$sth = $dbt->{dbh}->prepare("DELETE FROM patrons WHERE email=?");
$sth->execute("mixedcase@letu.edu");
