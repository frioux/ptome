#Test the database directly

use lib "../testclasses";
use TOMETest::DBTest;
use SQL::Interpolate qw(sql_interp);
use Test::More tests => 4;

my $dbt = TOMETest::DBTest->new();

#Add a semester or two to work with
my ($sql, @bind) = sql_interp("INSERT INTO semesters", {name => 'test'});
$dbt->{dbh}->do($sql, undef, @bind);
my $semester_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.semesters_id_seq')");

my ($sql, @bind) = sql_interp("INSERT INTO semesters", {name => 'test2'});
$dbt->{dbh}->do($sql, undef, @bind);
my $semester_id_two = $dbt->{dbh}->selectrow_array("SELECT currval('public.semesters_id_seq')");

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

#Add their corresponding tomebooks entries
($sql, @bind) = sql_interp("INSERT INTO tomebooks", {isbn => '01', originator => $patron_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);

#Add a reservation
($sql, @bind) = sql_interp("INSERT INTO reservations", {isbn => '01', uid => $user_id, patron => $patron_id, library_from => $library_two_id, library_to => $library_one_id, semester => $semester_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $reservation_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.reservations_id_seq')");

#Attempt to update the patron ID
($sql, @bind) = sql_interp("UPDATE reservations SET patron = ", $patron_id, " WHERE id = ", $reservation_id);
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there isn't an error message
is($dbt->{dbh}->errstr, undef, "DB will allow patron ID to be updated on a reservation");

#Attempt to update the isbn field (shouldn't be allowed)
($sql, @bind) = sql_interp("UPDATE reservations SET isbn = ", "123456", " WHERE id = ", $reservation_id); 
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "DB will not allow ISBN to be updated on a reservation");

#Attempt to update the library_to field (shouldn't be allowed)
($sql, @bind) = sql_interp("UPDATE reservations SET library_to = ", $library_two_id, " WHERE id = ", $reservation_id);
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "DB will not allow the \"To\" library to be updated on a reservation");

#Attempt to update the semester field (shouldn't be allowed)
($sql, @bind) = sql_interp("UPDATE reservations SET semester = ", $semester_id_two, " WHERE id = ", $reservation_id);
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "DB will not allow the semester field to be updated on a reservation");

#Clean up after ourselves
($sql, @bind) = sql_interp("DELETE FROM reservations WHERE", {id => $reservation_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM tomebooks WHERE", {isbn => '01'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM books WHERE", {isbn => '01'});
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

($sql, @bind) = sql_interp("DELETE FROM semesters WHERE", {name => 'test2'});
$dbt->{dbh}->do($sql, undef, @bind);




