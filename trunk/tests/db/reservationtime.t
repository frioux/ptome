#Test the database directly

use lib "../testclasses";
use TOMETest::DBTest;
use SQL::Interpolate qw(sql_interp);
use Test::More tests => 2;

my $dbt = TOMETest::DBTest->new();

#Add a semester or two to work with
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
	
#Add a sample library to the libraries table
($sql, @bind) = sql_interp("INSERT INTO libraries", {name => 'test1', intertome => 'TRUE'});
$dbt->{dbh}->do($sql, undef, @bind);
my $library_one_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.libraries_id_seq')");

#Add a fake book
($sql, @bind) = sql_interp("INSERT INTO books", {isbn => '01', title => 'TestBookOne', author => 'Author Person', edition => 'None'});
$dbt->{dbh}->do($sql, undef, @bind);

#Add its corresponding tomebooks entry
($sql, @bind) = sql_interp("INSERT INTO tomebooks", {isbn => '01', originator => $patron_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);

#Add a reservation
my $create_timestamptz = '2000-01-02';
($sql, @bind) = sql_interp("INSERT INTO reservations", {isbn => '01', uid => $user_id, patron => $patron_id, library_from => $library_one_id, library_to => $library_one_id, semester => $semester_id, reserved => $create_timestamptz});
$dbt->{dbh}->do($sql, undef, @bind);
my $reservation_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.reservations_id_seq')");

#Attempt to set the fulfilled timestamp at a time after it was created 
my $after_timestamptz = 'TIMESTAMP WITH TIME ZONE \'2000-01-03\'';
($sql, @bind) = sql_interp("UPDATE reservations SET fulfilled = ", $after_timestamptz, " WHERE id = ", $reservation_id);
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there isn't an error message
is($dbt->{dbh}->errstr, undef, "DB will allow reservation fulfilled date to be after reserved date");

#Attempt to set the fulfilled timestamp at a time before it was created 
my $before_timestamptz = 'TIMESTAMP WITH TIME ZONE \'2000-01-01\'';
($sql, @bind) = sql_interp("UPDATE reservations SET fulfilled = ", $before_timestamptz, " WHERE id = ", $reservation_id);
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "DB will not allow reservation fulfilled date to be before reserved date");

#Clean up after ourselves
($sql, @bind) = sql_interp("DELETE FROM reservations WHERE", {id => $reservation_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM tomebooks WHERE", {isbn => '01'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM books WHERE", {isbn => '01'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM libraries WHERE", {name => 'test1'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM patrons WHERE", {name => 'test'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM users WHERE", {username => 'test'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM semesters WHERE", {name => 'test'});
$dbt->{dbh}->do($sql, undef, @bind);
