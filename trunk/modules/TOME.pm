package TOME;

use base 'CGI::Application';

use CGI::Application::Plugin::DBH qw(dbh_config dbh);
use CGI::Application::Plugin::Session;

use DateTime::Format::Pg;

use Template;
use Params::Validate ':all';
use SQL::Interpolate qw(sql_interp);

use strict;
use warnings;

our %CONFIG = (
	cgibase		=> '/perl/tome/cgi',

	templatepath	=> '../templates',

	dbidatasource   => 'dbi:Pg:dbname=tome;host=127.0.0.1',
	dbiusername	=> 'tome',
	dbipassword	=> 'password',

	notifyfrom	=> 'TOMEkeeper <tomekeeper@tome>',
);

require 'site-config.pl';

sub cgiapp_init {
	my $self = shift;

	$self->dbh_config($CONFIG{dbidatasource}, $CONFIG{dbiusername}, $CONFIG{dbipassword}, { RaiseError => 1});
	$self->session_config(
		CGI_SESSION_OPTIONS	=> [ 'driver:PostgreSQL', $self->query, { Handle => $self->dbh } ],
		SEND_COOKIE		=> 1,
		DEFAULT_EXPIRY		=> '+24h',
	);
	$self->error_mode('error_runmode');

	$self->param('semesters', $self->semester_info);
	$self->param('currsemester', $self->semester_info({ current => 'true' }));
}

sub error_runmode {
	my $self = shift;

	return $self->error({ message => "Internal exception error", extended => $@ });
}

sub tomebooks_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		isbn		=> { type => SCALAR, optional => 1 },
		status		=> { type => SCALAR, regex => qr/^all|can_reserve|can_checkout|in_collection$/, default => 'all' },
		title		=> { type => SCALAR, optional => 1 },
		author		=> { type => SCALAR, optional => 1 },
		edition		=> { type => SCALAR, optional => 1 },
		libraries	=> { type => ARRAYREF },
		semester	=> { type => SCALAR, default => $self->param('currsemester')->{id} },
	});

	# I've decided to require listing what libraries you want, if you give an empty list, no books can be found
	unless(@{$params{libraries}}) {
		return ();
	}

	my (@likecolumns, @columns, @conditions, @values);

	foreach (qw(title author edition)) {
		if(defined($params{$_})) {
			$params{$_} =~ s/([\\%_])/\\$1/g;
			push @likecolumns, $_;
			push @values, $params{$_};
		}
	}
	if(defined($params{isbn})) {
		push @columns, 'tomebooks.isbn';
		push @values, $params{isbn};
	}
	
	foreach(@likecolumns) {
		push @conditions, "$_ ILIKE '%' || ? || '%'";
	}
	foreach(@columns) {
		push @conditions, "$_ = ?";
	}

	if($params{status} eq 'can_reserve' || $params{status} eq 'can_checkout') {
		push @conditions, "timeremoved IS NULL AND (expire IS NULL OR expire >= ?)";
		push @values, $params{semester};
		if($params{status} eq 'can_reserve') {
			# books that are not reserved or checked out for this semester (may still be checked out to a previous semester)
			# Note that we check for checkouts on this semester and future ones.  It seemed like a good idea the time...
			push @conditions, "NOT EXISTS(SELECT 1 FROM checkouts WHERE checkin IS NULL AND tomebook = tomebooks.id AND ((semester >= ? AND reservation = FALSE) OR (semester = ? AND reservation = TRUE)))";
			push @values, ($params{semester}) x 2;
		} else {
			# books with no outstanding checkouts and no reservations for this semester
			push @conditions, "NOT EXISTS(SELECT 1 FROM checkouts WHERE checkin IS NULL AND tomebook = tomebooks.id AND ((reservation = FALSE) OR (semester = ? AND reservation = TRUE)))";
			push @values, $params{semester};
		}
	} elsif($params{status} eq 'in_collection') {
		push @conditions, "timeremoved IS NULL";
	}
	
	push @conditions, "library IN (" . join(',', ('?') x @{$params{libraries}}) . ")";
	push @values, @{$params{libraries}};

	push @conditions, 'tomebooks.isbn = books.isbn';
	my $statement = 'SELECT tomebooks.id FROM books, tomebooks WHERE ' . join(' AND ', @conditions) . " ORDER BY timeremoved DESC, title, id ASC";

	warn "Statement of doom: $statement";
	warn "Binds: " . join(',', @values);

	my $sth = $dbh->prepare($statement);
	
	$sth->execute(@values);
	
	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}
	
	return @results;
}

sub expire_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
		libraries       => { type => ARRAYREF },
	});

	my ($sql, @bind) = sql_interp('SELECT id AS tomebook FROM tomebooks WHERE expire <=', $params{semester}, 'AND timeremoved IS NULL AND library IN', $params{libraries}, 'ORDER BY expire, originator ASC');
	my $sth = $dbh->prepare($sql);

	$sth->execute(@bind);
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}
	return \@results;
}

sub reservation_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
		libraries       => { type => ARRAYREF },
	});

	my ($sql, @bind) = sql_interp('SELECT tomebook, borrower, comments, semester, checkout FROM checkouts WHERE semester <=', $params{semester}, 'AND reservation = TRUE AND library IN', $params{libraries}, 'ORDER BY semester, borrower ASC');
	
	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}
	return \@results;
}

sub dueback_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
		libraries	=> { type => ARRAYREF },
	});

	my ($sql, @bind) = sql_interp('SELECT tomebook, borrower, comments, semester, checkout FROM checkouts WHERE semester <=', $params{semester}, 'AND checkin IS NULL AND reservation = FALSE AND library IN', $params{libraries}, 'ORDER BY semester, borrower ASC');

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}
	return \@results;
}

sub add_book {
	my $self = shift;

	my %params = validate(@_, {
		isbn	=> { type => SCALAR },
		title	=> { type => SCALAR },
		author	=> { type => SCALAR },
		edition	=> { type => SCALAR, default => 'None' },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("INSERT INTO books (isbn, title, author, edition) VALUES (?, ?, ?, ?)");
	$sth->execute($params{isbn}, $params{title}, $params{author}, $params{edition});
}

sub add_class {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR },
		name	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	$dbh->do("INSERT INTO classes (id, name) VALUES (?, ?)", undef, @params{qw(id name)});
}

sub book_exists {
	my $self = shift;

	my %params = validate (@_, {
		isbn	=> { type => SCALAR },
	});

	# !!! Refactor into a query to general books search sub

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT COUNT(isbn) FROM books WHERE isbn = ?");
	$sth->execute($params{isbn});

	my ($count) = $sth->fetchrow_array;
	return $count;
}

sub book_classes {
	my $self = shift;

	my %params = validate (@_, {
		isbn	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare('SELECT id, name FROM classes, classbooks WHERE classbooks.class = classes.id AND isbn = ? ORDER BY class');
	$sth->execute($params{isbn});

	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}

	return \@results;
}

sub add_tomebook {
	my $self = shift;

	my %params = validate(@_, {
		isbn		=> { type => SCALAR },
		originator 	=> { type => SCALAR },
		expire		=> { type => SCALAR, optional => 1, regex => qr/^\d+$/ },
		comments	=> { type => SCALAR, optional => 1 },
		library		=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my @columns = qw(isbn originator library);
	my @values = ($params{isbn}, $params{originator}, $params{library});

	foreach(qw(expire comments)) {
		if($params{$_}) {
			push @columns, $_;
			push @values, $params{$_};
		}
	}

	# !!! Split out comments into other sub, return new id so caller can create book entry and add a comment

	my $statement = 'INSERT INTO tomebooks (' . join(',', @columns) . ') VALUES (?' . (', ?' x (@columns - 1)) . ')';
	my $dbh = $self->dbh;
	$dbh->do($statement, undef, @values);

	my ($id) = $dbh->selectrow_array("SELECT currval('public.tomebooks_id_seq')");
	return $id;
}

sub classbook_add {
	my $self = shift;

	my %params = validate(@_, {
		isbn		=> { type => SCALAR },
		usable	 	=> { type => SCALAR, regex => qr/^true|false$/, default => 1 },
		verified	=> { type => SCALAR, regex => qr/^\d+$/ },
		comments	=> { type => SCALAR, optional => 1 },
		class		=> { type => SCALAR },
		uid		=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my ($sql, @bind) = sql_interp('INSERT INTO classbooks', \%params);
	$self->dbh->do($sql, undef, @bind);
}

sub tomebook_info {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT tomebooks.isbn AS isbn, books.title AS title, books.author AS author, books.edition AS edition, originator, comments, expire, tomebooks.id AS id, timedonated, library, timeremoved FROM tomebooks, books WHERE tomebooks.isbn = books.isbn AND tomebooks.id = ?");
	$sth->execute($params{id});

	my $results = $sth->fetchrow_hashref;
	foreach(qw(timedonated timeremoved)) {
		if(defined($results->{$_})) {
			$results->{$_} = DateTime::Format::Pg->parse_timestamptz($results->{$_});
		}
	}

	return $results;
}

sub tome_stats {
	my $self = shift;

	my $dbh = $self->dbh;

	my %stats;
	($stats{totalcollection}) = $dbh->selectrow_array('SELECT count(id) FROM tomebooks');
	($stats{currentcollection}) = $dbh->selectrow_array('SELECT count(id) FROM tomebooks WHERE timeremoved IS NULL');
	($stats{totalcheckouts}) = $dbh->selectrow_array('SELECT count(checkout) FROM checkouts');
	my $sth = $dbh->prepare('SELECT count(checkout) FROM checkouts WHERE semester = ?');
	$sth->execute($self->param('currsemester')->{id});
	($stats{semestercheckouts}) = $sth->fetchrow_array;

	$sth = $dbh->prepare('SELECT originator, COUNT(id) AS books FROM tomebooks GROUP BY originator ORDER BY books DESC, originator ASC LIMIT 10');
	$sth->execute;
	while(my $result = $sth->fetchrow_hashref) {
		push @{$stats{top10donators}}, $result;
	}


	return \%stats;
}

sub book_update {
	my $self = shift;

	my %params = validate(@_, {
		isbn	=> { type => SCALAR, regex => qr/^\w+$/ },
		title 	=> { type => SCALAR },
		author	=> { type => SCALAR },
		edition	=> { type => SCALAR, optional => 1 },
	});

	my $dbh = $self->dbh;
	$dbh->do('UPDATE books SET title = ?, author = ?, edition = ? WHERE isbn = ?', undef, @params{qw(title author edition isbn)});
}

sub tomebook_update {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, regex => qr/^\d+$/ },
		originator 	=> { type => SCALAR },
		expire		=> { type => SCALAR, optional => 1, regex => qr/^\d*$/ },
		comments	=> { type => SCALAR, optional => 1 },
		library		=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;
	if(defined($params{expire}) && $params{expire} > 0) { # There is an expiration date
		$dbh->do('UPDATE tomebooks SET originator = ?, expire = ?, comments = ?, library = ? WHERE id = ?', undef, @params{qw(originator expire comments library id)});
	} elsif(defined($params{expire})) { # The user specifically said there wasn't
		$dbh->do('UPDATE tomebooks SET originator = ?, expire = NULL, comments = ?, library = ? WHERE id = ?', undef, @params{qw(originator comments library id)});
	} else { # No updates done to the expiration date
		$dbh->do('UPDATE tomebooks SET originator = ?, comments = ?, library = ? WHERE id = ?', undef, @params{qw(originator comments library id)});
	}
}


sub checkout_history {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT checkouts.id AS id, semester, borrower, checkout, reservation, checkin, comments, uid, username, library FROM checkouts, users WHERE uid = users.id AND tomebook = ? ORDER BY semester DESC");
	$sth->execute($params{id});
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		foreach(qw(checkin checkout)) {
			if(defined($result->{$_})) {
				$result->{$_} = DateTime::Format::Pg->parse_timestamptz($result->{$_});
			}
		}
		push @results, $result;
	}

	return \@results;
}

sub find_orphans {
	my $self = shift;

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare('SELECT DISTINCT isbn FROM tomebooks WHERE tomebooks.timeremoved IS NULL AND isbn NOT IN (SELECT books.isbn FROM books, classbooks WHERE classbooks.isbn = books.isbn) ORDER BY isbn');
	$sth->execute();
	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

	return @results;
}

sub find_useless {
	my $self = shift;

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare('SELECT tomebooks.id AS id FROM tomebooks, classbooks WHERE tomebooks.timeremoved IS NULL AND classbooks.usable = FALSE AND tomebooks.isbn = classbooks.isbn ORDER BY tomebooks.isbn,id');
	$sth->execute();
	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

	return @results;
}

sub tomebook_checkout {
	my $self = shift;

	my %params = validate(@_, {
		tomebook	=> { type => SCALAR, regex => qr/^\d+$/ },
		borrower	=> { type => SCALAR },
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
		reservation	=> { type => SCALAR, regex => qr/^true|false$/ },
		uid		=> { type => SCALAR, regex => qr/^\d+$/ },
		library		=> { type => SCALAR, regex => qr/^\d+$/ },
	});			

	my ($sql, @bind) = sql_interp('INSERT INTO checkouts', \%params);
	$self->dbh->do($sql, undef, @bind);
	
	my ($id) = $self->dbh->selectrow_array("SELECT currval('public.checkouts_id_seq')");
	return $id;
}

sub tomebook_can_checkout {
	my $self = shift;

	my %params = validate(@_, {
		tomebook	=> { type => SCALAR, regex => qr/^\d+$/ },
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my ($sql, @bind) = sql_interp('SELECT 1 FROM checkouts WHERE', { tomebook => $params{tomebook} }, 'AND checkin IS NULL AND reservation = FALSE');
	if($self->dbh->selectrow_array($sql, undef, @bind)) {
		return $self->error({ message => "Book #$params{tomebook} is already checked out" });
	}

	($sql, @bind) = sql_interp('SELECT 1 FROM checkouts WHERE', \%params, 'AND reservation = TRUE');
	if($self->dbh->selectrow_array($sql, undef, @bind)) {
		return $self->error({ message => "Book #$params{tomebook} has already been reserved for that semester" });
	}

	return 0;
}

sub tomebook_can_reserve {
	my $self = shift;

	my %params = validate(@_, {
		tomebook	=> { type => SCALAR, regex => qr/^\d+$/ },
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my ($sql, @bind) = sql_interp('SELECT 1 FROM checkouts WHERE', \%params, 'AND checkin IS NULL AND reservation = FALSE');
	if($self->dbh->selectrow_array($sql, undef, @bind)) {
		return $self->error({ message => "Book #$params{tomebook} is already checked out for that semester and cannot be reserved" });
	}
	($sql, @bind) = sql_interp('SELECT 1 FROM checkouts WHERE', \%params, 'AND checkin IS NULL AND reservation = TRUE');
	if($self->dbh->selectrow_array($sql, undef, @bind)) {
		return $self->error({ message => "Book #$params{tomebook} is already reserved for that semester" });
	}


	return 0;
}

sub tomebook_fill_reservation {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	$dbh->do('UPDATE checkouts set checkout = now(), reservation = FALSE WHERE id = ?', undef, @params{qw(id)});
}

sub tomebook_cancel_checkout {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	$dbh->do('DELETE FROM checkouts WHERE id = ?', undef, @params{qw(id)});
}

sub tomebook_checkin {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	$dbh->do('UPDATE checkouts set reservation = FALSE WHERE id = ?', undef, @params{qw(id)}); # Obviously can't be reserved if it's checked in...
	$dbh->do('UPDATE checkouts SET checkin = now() WHERE id = ?', undef, @params{qw(id)});
}

sub tomebook_remove {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
		undo	=> { type => SCALAR, regex => qr/^true|false$/, default => 'false' },
	});

	if($params{undo} eq 'false') {
		my ($sql, @bind) = sql_interp('UPDATE tomebooks SET timeremoved = now() WHERE', { id => $params{id} });
		$self->dbh->do($sql, undef, @bind);
	} else {
		my ($sql, @bind) = sql_interp('UPDATE tomebooks SET timeremoved = NULL WHERE', { id => $params{id} });
		$self->dbh->do($sql, undef, @bind);
	}
}

sub update_checkout_comments {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, regex => qr/^\d+$/ },
		comments	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	$dbh->do('UPDATE checkouts SET comments = ? WHERE id = ?', undef, $params{comments}, $params{id});
}

sub book_info {
	my $self = shift;

	my %params = validate(@_, {
		isbn	=> { type => SCALAR, regex => qr/^\w+$/ },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT isbn, title, author, edition FROM books WHERE isbn = ?");
	$sth->execute($params{isbn});
	return $sth->fetchrow_hashref;
}

sub class_list {
	my $self = shift;

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT id, name FROM classes ORDER BY id ASC");
	$sth->execute;
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}

	return \@results;
}

sub class_info {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT name, comments FROM classes WHERE id = ?");
	$sth->execute($params{id});
	my ($name, $comments) = $sth->fetchrow_array;

	$sth = $dbh->prepare("SELECT isbn, usable, verified, comments, uid, username FROM classbooks, users WHERE uid = users.id AND class = ? ORDER BY usable DESC");
	$sth->execute($params{id});
	my @books;
	while(my $result = $sth->fetchrow_hashref) {
		push @books, $result;
	}

	return { name => $name, comments => $comments, books => \@books };
}

sub class_update_comments {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR },
		comments	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	$dbh->do('UPDATE classes SET comments = ? WHERE id = ?', undef, $params{comments}, $params{id});
}

sub classbook_update {
	my $self = shift;

	my %params = validate(@_, {
		class		=> { type => SCALAR },
		isbn		=> { type => SCALAR, regex => qr/^\w+$/ },
		usable	 	=> { type => SCALAR, regex => qr/^true|false$/ },
		verified	=> { type => SCALAR, regex => qr/^\d+$/ },
		uid		=> { type => SCALAR, regex => qr/^\d+$/ },
		comments	=> { type => SCALAR },
	});


	my ($sql, @bind) = sql_interp('UPDATE classbooks SET', { usable => $params{usable}, verified => $params{verified}, comments => $params{comments}, uid => $params{uid} }, 'WHERE', { class => $params{class}, isbn => $params{isbn} });
	$self->dbh->do($sql, undef, @bind);
}

sub class_delete {
	my $self = shift;
	
	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\w+$/ },
	});

	my $dbh = $self->dbh;

	$dbh->do('DELETE FROM classbooks WHERE class = ?', undef, @params{qw(id)});
	$dbh->do('DELETE FROM classes WHERE id = ?', undef, @params{qw(id)});
}

sub class_delete_book {
	my $self = shift;

	my %params = validate(@_, {
		class		=> { type => SCALAR },
		isbn		=> { type => SCALAR, regex => qr/^\w+$/ },
	});

	my $dbh = $self->dbh;

	$dbh->do('DELETE FROM classbooks WHERE class = ? AND isbn = ?', undef, @params{qw(class isbn)});
}

sub user_info {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, optional => 1 },
		username	=> { type => SCALAR, optional => 1 },
	});

	my $statement = 'SELECT id, username, email, notifications, admin, disabled, password FROM users';
	my $sth;
	if($params{id}) {
		$sth = $self->dbh->prepare($statement . ' WHERE id = ? ORDER BY disabled, username');
		$sth->execute($params{id});
	} elsif($params{username}) {
		$sth = $self->dbh->prepare($statement . ' WHERE username = ? ORDER BY disabled, username');
		$sth->execute($params{username});
	} else {
		$sth = $self->dbh->prepare($statement . ' ORDER BY disabled, username');
		$sth->execute;
	}

	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}

	return ($params{id} || $params{username}) ? $results[0] : \@results;
}

sub user_add {
	my $self = shift;

	my %params = validate(@_, {
		username	=> { type => SCALAR },
		email		=> { type => SCALAR },
		password	=> { type => SCALAR, default => '' },
	});

	my ($sql, @bind) = sql_interp('INSERT INTO users', \%params);
	$self->dbh->do($sql, undef, @bind);
}

sub user_update {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, regex => qr/^\d+$/ },
		username	=> { type => SCALAR },
		email		=> { type => SCALAR },
		notifications	=> { type => SCALAR, regex => qr/^true|false$/ },
		disabled	=> { type => SCALAR, regex => qr/^true|false$/, optional => 1 },
		admin		=> { type => SCALAR, regex => qr/^true|false$/, optional => 1 },
		password	=> { type => SCALAR, optional => 1 },
	});

	my %user;
	foreach(qw(username email notifications admin disabled password)) {
		if(defined($params{$_})) { $user{$_} = $params{$_}; }
	}

	my ($sql, @bind) = sql_interp('UPDATE users SET', \%user, 'WHERE id =', $params{id});
	$self->dbh->do($sql, undef, @bind);
}

sub semester_info {
	my $self = shift;
	
	my %params = validate(@_, {
		current	=> { type => SCALAR, regex => qr/^true|false$/, default => 'false' },
	});

	my $sth;
	if($params{current} eq 'true') {
		$sth = $self->dbh->prepare('SELECT id, name FROM semesters WHERE current = TRUE');
	} else {
		$sth = $self->dbh->prepare('SELECT id, name FROM semesters ORDER BY id');
	}
	$sth->execute;

	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}

	return ($params{current} eq 'true') ? $results[0] : \@results;
}

sub semester_set {
	my $self = shift;

	my %params = validate(@_, {
		id => { type => SCALAR, regex => qr/^\d+$/ },
	});

	$self->dbh->begin_work;
	$self->dbh->do('UPDATE semesters SET current = FALSE');
	my($sql, @bind) = sql_interp('UPDATE semesters SET current = TRUE WHERE', { id => $params{id} });
	$self->dbh->do($sql, undef, @bind);
	$self->dbh->commit;
}

sub semester_add {
	my $self = shift;

	my %params = validate(@_, {
		name	=> { type => SCALAR },
	});

	my ($sql, @bind) = sql_interp('INSERT INTO semesters', { name => $params{name} });
	$self->dbh->do($sql, undef, @bind);
}

sub library_add {
	my $self = shift;

	my %params = validate(@_, {
		name	=> { type => SCALAR },
	});

	my ($sql, @bind) = sql_interp('INSERT INTO libraries', { name => $params{name} });
	$self->dbh->do($sql, undef, @bind);
}

sub library_info {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, optional => 1 },
	});

	my $statement = 'SELECT id, name FROM libraries';
	my $sth;
	if($params{id}) {
		$sth = $self->dbh->prepare($statement . ' WHERE id = ?');
		$sth->execute($params{id});
	} else {
		$sth = $self->dbh->prepare($statement . ' ORDER BY name');
		$sth->execute;
	}

	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}

	return $params{id} ? $results[0] : \@results;
}

sub library_users {
	my $self = shift;

	my %params = validate(@_, {
		library		=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my ($sql, @bind) = sql_interp('SELECT uid FROM library_access WHERE', \%params);
	my $sth = $self->dbh->prepare($sql);
	$sth->execute(@bind);
	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

	return @results;
}

sub library_access {
	my $self = shift;

	my %params = validate(@_, {
		user		=> { type => SCALAR, regex => qr/^\d+$/ },
		libraries	=> { type => ARRAYREF, optional => 1 },
	});

	my ($sql, @bind) = sql_interp('SELECT id, name FROM library_access, libraries WHERE library_access.library = libraries.id AND ', { uid => $params{user} }, 'ORDER BY name');

	my $sth = $self->dbh->prepare($sql);
	$sth->execute(@bind);
	
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}

	unless($params{libraries}) { return \@results; }

	my %access = map { $_->{id} => 1 } @results;
	foreach my $library (@{$params{libraries}}) {
		unless($access{$library}) {
			my ($sql, @bind) = sql_interp('INSERT INTO library_access', { library => $library, uid => $params{user} });
			$self->dbh->do($sql, undef, @bind);
		} else {
			delete $access{$library};
		}
	}
	foreach my $library (keys %access) {
		my ($sql, @bind) = sql_interp('DELETE FROM library_access WHERE', { library => $library, uid => $params{user} });
		$self->dbh->do($sql, undef, @bind);
	}
}

sub error {
	my $self = shift;
	my $params = shift;
	
	warn "$params->{message} - $params->{extended}";
	
	return $self->template({ file => 'error.html', vars => { message => $params->{message} }});
}

sub template {
	my $self = shift;

	my %params = validate(@_, {
		file	=> { type => SCALAR },
		vars	=> { type => HASHREF, default => {} },
		plain	=> { type => SCALAR, default => 0 },
	});

	%{$params{vars}} = (
		%{$params{vars}},
		config		=> \%CONFIG,
		session		=> $self->session->param_hashref(),
		semesters	=> $self->param('semesters'),
		semestershash	=> { map { $_->{id} => $_ } @{$self->param('semesters')} },
		currsemester	=> $self->param('currsemester'),
	);

	if($self->param('user_info')) {
		$params{vars}{user_info} = $self->param('user_info');
	}

	my $tt = Template->new({INCLUDE_PATH => $CONFIG{templatepath}, ($params{plain} ? () : (PRE_PROCESS => 'header.html', POST_PROCESS => 'footer.html'))}) or die $Template::ERROR;
	my $output;

	$tt->process($params{file}, $params{vars}, \$output) or die $tt->error;

	return $output;
}

1;

