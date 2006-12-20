#Test the database directly

use lib "../testclasses";
use TOMETest::DBTest;
use SQL::Interpolate qw(sql_interp);
use Test::More tests => 3;

my $dbt = TOMETest::DBTest->new();

#Add a semester to work with
my ($sql, @bind) = sql_interp("INSERT INTO semesters", {name => 'test'});
$dbt->{dbh}->do($sql, undef, @bind);
my $semester_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.semesters_id_seq')");

#Add a user
($sql, @bind) = sql_interp("INSERT INTO users", {username => 'test', email => 'this@that.com', password => 'password'});
$dbt->{dbh}->do($sql, undef, @bind);
my $user_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.users_id_seq')");

#Add a patron
($sql, @bind) = sql_interp("INSERT INTO patrons", {name => 'test', email => 'this@that.com'});
$dbt->{dbh}->do($sql, undef, @bind);
my $patron_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.patrons_id_seq')");
	
#Add a couple of sample libraries to the libraries table
($sql, @bind) = sql_interp("INSERT INTO libraries", {name => 'test1', intertome => 'TRUE'});
$dbt->{dbh}->do($sql, undef, @bind);
my $library_one_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.libraries_id_seq')");

($sql, @bind) = sql_interp("INSERT INTO libraries", {name => 'test2', intertome => 'TRUE'});
$dbt->{dbh}->do($sql, undef, @bind);
my $library_two_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.libraries_id_seq')");

#Add a couple of fake books
($sql, @bind) = sql_interp("INSERT INTO books", {isbn => '01', title => 'TestBookOne', author => 'Author Person', edition => 'None'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("INSERT INTO books", {isbn => '02', title => 'TestBookTwo', author => 'Author Person', edition => 'None'});
$dbt->{dbh}->do($sql, undef, @bind);

#Add their corresponding tomebooks entries
($sql, @bind) = sql_interp("INSERT INTO tomebooks", {isbn => '01', originator => $patron_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("INSERT INTO tomebooks", {isbn => '02', originator => $patron_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);

#Add a reservation for book 01
($sql, @bind) = sql_interp("INSERT INTO reservations", {isbn => '01', uid => $user_id, patron => $patron_id, library_from => $library_two_id, library_to => $library_one_id, semester => $semester_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $reservation_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.reservations_id_seq')");

#Remove Library One from the InterTOME system
($sql, @bind) = sql_interp("UPDATE libraries SET intertome = ", 'FALSE', " WHERE id = ", $library_one_id);
eval {$dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "DB won't allow floor to leave InterTOME while it has a pending reservation");

#Reset Library One to be in InterTOME once more
($sql, @bind) = sql_interp("UPDATE libraries SET intertome = ", 'TRUE', " WHERE id = ", $library_one_id);
$dbt->{dbh}->do($sql, undef, @bind);

#Update the reservation to be fulfilled
($sql, @bind) = sql_interp("UPDATE reservations SET fulfilled = ", 'now()', " WHERE id = ", $reservation_id);
$dbt->{dbh}->do($sql, undef, @bind);

#Remove Library One from the InterTOME system
($sql, @bind) = sql_interp("UPDATE libraries SET intertome = ", 'FALSE', " WHERE id = ", $library_one_id);
eval { $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure no error is returned
is($dbt->{dbh}->errstr, undef, "But it can leave after the reservation is fulfulled");

#Reset Library One to be in InterTOME once more
($sql, @bind) = sql_interp("UPDATE libraries SET intertome = ", 'TRUE', " WHERE id = ", $library_one_id);
$dbt->{dbh}->do($sql, undef, @bind);

#Now remove the reservation altogether
($sql, @bind) = sql_interp("DELETE FROM reservations WHERE", {id => $reservation_id});
$dbt->{dbh}->do($sql, undef, @bind);

#Try to remove the library from InterTOME once more
($sql, @bind) = sql_interp("UPDATE libraries SET intertome = ", 'FALSE', " WHERE id = ", $library_one_id);
eval { $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure it doesn't return an error
is($dbt->{dbh}->errstr, undef, "Leaving InterTOME works properly with no reservations");

#Clean up after ourselves
($sql, @bind) = sql_interp("DELETE FROM tomebooks WHERE", {isbn => '01'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM tomebooks WHERE", {isbn => '02'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM books WHERE", {isbn => '01'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM books WHERE", {isbn => '02'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM libraries WHERE", {name => 'test1'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM libraries WHERE", {name => 'test2'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM patrons WHERE", {name => 'test'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM users WHERE", {username => 'test'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM semesters WHERE", {name => 'test'});
$dbt->{dbh}->do($sql, undef, @bind);





