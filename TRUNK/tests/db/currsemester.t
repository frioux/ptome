#Test the database directly

use lib "../modules";
use TOMETest::DBTest;
use Test::More tests => 3;

my $dbt = TOMETest::DBTest->new();

#Try and add two semesters, with both of them having the current value set to true.  It should fail on the second one.
my $sth = $dbt->{dbh}->prepare("INSERT INTO semesters (name, current) VALUES (?, ?)");
$sth->execute("2006, Spring", "TRUE");

$sth = $dbt->{dbh}->prepare("INSERT INTO semesters (name, current) VALUES (?, ?)");
eval { $sth->execute("2006, Fall", "TRUE"); };

isnt($@, '', "DB doesn't allow multiple current semesters");

#Now add a semester with current set to false.  This should succeed.
$sth = $dbt->{dbh}->prepare("INSERT INTO semesters (name, current) VALUES (?, ?)");
eval { $sth->execute("2006, Fall", "FALSE"); };

is($@, '', "But it doesn allow multiple semesters");

#Now update the newly-added semester's current to true.  This should fail.

my ($id) = $dbt->{dbh}->selectrow_array("SELECT currval('public.semesters_id_seq')");

$sth = $dbt->{dbh}->prepare("UPDATE semesters SET current = TRUE WHERE id=?");
eval { $sth->execute($id); };

isnt($@, '', "Can't have multiple current semesters, even on update");

#Clean up after ourselves
$sth = $dbt->{dbh}->prepare("DELETE FROM semesters");
$sth->execute();
