#Test the database directly

use lib "../modules";
use TOMETest::DBTest;
use Test::More tests => 2;

my $dbt = TOMETest::DBTest->new();

#Try and add both MixedCase and mixedcase, verify it returns an error
my $sth = $dbt->{dbh}->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
$sth->execute("MixedCase", "MixedCase@letu.edu", "Blah");

$sth = $dbt->{dbh}->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
eval { $sth->execute("mixedcase", "MixedCase@letu.edu", "Blah"); };

isnt($@, undef, "DB won't allow duplicate usernames");

#Now remove MixedCase try inserting mixedcase again -- it should work this time
$sth = $dbt->{dbh}->prepare("DELETE FROM users WHERE username=?");
$sth->execute("MixedCase");

$sth = $dbt->{dbh}->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
eval { $sth->execute("mixedcase", "MixedCase@letu.edu", "Blah"); };

is($dbt->{dbh}->errstr, undef, "But we can add it after we delete the other one");

#Clean up after ourselves
$sth = $dbt->{dbh}->prepare("DELETE FROM users WHERE username=?");
$sth->execute("mixedcase");
