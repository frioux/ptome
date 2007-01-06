#Test the database directly

use lib "../testclasses";
use TOMETest::DBTest;
use SQL::Interpolate qw(sql_interp);
use Test::More tests => 6;

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

($sql, @bind) = sql_interp("INSERT INTO books", {isbn => '02', title => 'TestBookTwo', author => 'Author Person', edition => 'None'});
$dbt->{dbh}->do($sql, undef, @bind);

#Add their corresponding tomebooks entries
($sql, @bind) = sql_interp("INSERT INTO tomebooks", {isbn => '01', originator => $patron_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $tomebook_one = $dbt->{dbh}->selectrow_array("SELECT currval('public.tomebooks_id_seq')");

($sql, @bind) = sql_interp("INSERT INTO tomebooks", {isbn => '02', originator => $patron_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $tomebook_two = $dbt->{dbh}->selectrow_array("SELECT currval('public.tomebooks_id_seq')");

#Add a checkout
($sql, @bind) = sql_interp("INSERT INTO checkouts", {tomebook => $tomebook_one, uid => $user_id, borrower => $patron_id, semester => $semester_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $checkout_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.checkouts_id_seq')");

#Attempt to update the comments
($sql, @bind) = sql_interp("UPDATE checkouts SET comments = ", "123456", " WHERE id = ", $checkout_id);
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there isn't an error message
is($dbt->{dbh}->errstr, undef, "DB will allow the comments field to be updated on a checkout");

#Attempt to update the isbn field (shouldn't be allowed)
($sql, @bind) = sql_interp("UPDATE checkouts SET isbn = ", "123456", " WHERE id = ", $checkout_id); 
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "DB will not allow ISBN to be updated on a checkout");

#Attempt to update the library field (shouldn't be allowed)
($sql, @bind) = sql_interp("UPDATE checkouts SET library = ", $library_two_id, " WHERE id = ", $checkout_id);
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "DB will not allow the library field to be updated on a checkout");

#Attempt to update the semester field (shouldn't be allowed)
($sql, @bind) = sql_interp("UPDATE checkouts SET semester = ", $semester_id_two, " WHERE id = ", $checkout_id);
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "DB will not allow the semester field to be updated on a checkout");

#Remove book 2 from the collection
($sql, @bind) = sql_interp("UPDATE tomebooks SET timeremoved = ", "now()", " WHERE id = ", $tomebook_two);
$dbt->{dbh}->do($sql, undef, @bind);

#Attempt to add a checkout for book 2
($sql, @bind) = sql_interp("INSERT INTO checkouts", {tomebook => $tomebook_two, uid => $user_id, borrower => $patron_id, semester => $semester_id, library => $library_one_id});
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "Removed books cannot be checked out");

#Attempt to add a checkout for book 1 (already checked out)
($sql, @bind) = sql_interp("INSERT INTO checkouts", {tomebook => $tomebook_one, uid => $user_id, borrower => $patron_id, semester => $semester_id, library => $library_one_id});
eval{ $dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "New checkouts cannot be made when all existing copies of a book are already checked out");

#Clean up after ourselves
($sql, @bind) = sql_interp("DELETE FROM checkouts WHERE", {id => $checkout_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM tomebooks WHERE", {id => $tomebook_one});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM tomebooks WHERE", {id => $tomebook_two});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM books WHERE", {isbn => '01'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM books WHERE", {isbn => '02'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM libraries WHERE", {id => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM libraries WHERE", {id => $library_two_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM patrons WHERE", {id => $patron_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM users WHERE", {id => $user_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM semesters WHERE", {id => $semester_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM semesters WHERE", {id => $semester_id_two});
$dbt->{dbh}->do($sql, undef, @bind);




