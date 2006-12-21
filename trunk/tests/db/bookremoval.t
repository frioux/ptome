#Test the database directly

use lib "../testclasses";
use TOMETest::DBTest;
use SQL::Interpolate qw(sql_interp);
use Test::More tests => 4;

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
	
#Add a sample library to the libraries table
($sql, @bind) = sql_interp("INSERT INTO libraries", {name => 'test1', intertome => 'TRUE'});
$dbt->{dbh}->do($sql, undef, @bind);
my $library_one_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.libraries_id_seq')");

#Add a few fake books
($sql, @bind) = sql_interp("INSERT INTO books", {isbn => '01', title => 'TestBookOne', author => 'Author Person', edition => 'None'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("INSERT INTO books", {isbn => '02', title => 'TestBookTwo', author => 'Author Person', edition => 'None'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("INSERT INTO books", {isbn => '03', title => 'TestBookThree', author => 'Author Person', edition => 'None'});
$dbt->{dbh}->do($sql, undef, @bind);

#Add their corresponding tomebooks entries
($sql, @bind) = sql_interp("INSERT INTO tomebooks", {isbn => '01', originator => $patron_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $tomebook_one_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.tomebooks_id_seq')");

($sql, @bind) = sql_interp("INSERT INTO tomebooks", {isbn => '02', originator => $patron_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $tomebook_two_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.tomebooks_id_seq')");

($sql, @bind) = sql_interp("INSERT INTO tomebooks", {isbn => '03', originator => $patron_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $tomebook_three_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.tomebooks_id_seq')");

#Try to remove book 01
($sql, @bind) = sql_interp("UPDATE tomebooks SET timeremoved = ", 'now()', "WHERE id = ", $tomebook_one_id);
eval {$dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there isn't an error message
is($dbt->{dbh}->errstr, undef, "DB will allow tomebook to be removed if no checkouts exist for it");

#De-removify book 01
($sql, @bind) = sql_interp("UPDATE tomebooks SET timeremoved = ", 'NULL', "WHERE id = ", $tomebook_one_id);
$dbt->{dbh}->do($sql, undef, @bind);

#Add a checkout for book 01
($sql, @bind) = sql_interp("INSERT INTO checkouts", {tomebook => $tomebook_one_id, uid => $user_id, borrower => $patron_id, semester => $semester_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $checkout_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.checkouts_id_seq')");

#Try to remove book 01 again
($sql, @bind) = sql_interp("UPDATE tomebooks SET timeremoved = ", 'now()', "WHERE id = ", $tomebook_one_id);
eval {$dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there is an error message
isnt($dbt->{dbh}->errstr, undef, "DB won't allow tomebook to be removed while it has a current checkout");

#Mark the checkout as checked in
($sql, @bind) = sql_interp("UPDATE checkouts SET checkin = ", 'now()', " WHERE id = ", $checkout_id);
$dbt->{dbh}->do($sql, undef, @bind);

#Try to remove book 01 again
($sql, @bind) = sql_interp("UPDATE tomebooks SET timeremoved = ", 'now()', "WHERE id = ", $tomebook_one_id);
eval {$dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there isn't an error message
is($dbt->{dbh}->errstr, undef, "DB will allow tomebook to be removed if its checkouts are marked as checked in");

#Remove the checkout for book 01
($sql, @bind) = sql_interp("DELETE FROM checkouts WHERE", {id => $checkout_id});
$dbt->{dbh}->do($sql, undef, @bind);

#Add a checkout for book 02
($sql, @bind) = sql_interp("INSERT INTO checkouts", {tomebook => $tomebook_two_id, uid => $user_id, borrower => $patron_id, semester => $semester_id, library => $library_one_id});
$dbt->{dbh}->do($sql, undef, @bind);
my $checkout_id = $dbt->{dbh}->selectrow_array("SELECT currval('public.checkouts_id_seq')");

#Attempt to remove book 03
($sql, @bind) = sql_interp("UPDATE tomebooks SET timeremoved = ", 'now()', "WHERE id = ", $tomebook_three_id);
eval {$dbt->{dbh}->do($sql, undef, @bind); };

#Test to make sure there isn't an error message
is($dbt->{dbh}->errstr, undef, "DB will allow tomebook to be removed even if there are valid checkouts for other books");

#Clean up after ourselves
($sql, @bind) = sql_interp("DELETE FROM checkouts WHERE", {id => $checkout_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM tomebooks WHERE", {id => $tomebook_one_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM tomebooks WHERE", {id => $tomebook_two_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM tomebooks WHERE", {id => $tomebook_three_id});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM books WHERE", {isbn => '01'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM books WHERE", {isbn => '02'});
$dbt->{dbh}->do($sql, undef, @bind);

($sql, @bind) = sql_interp("DELETE FROM books WHERE", {isbn => '03'});
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





