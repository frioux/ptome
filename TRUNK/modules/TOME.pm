package TOME;

#{{{pod

=head1 NAME

TOME

=cut

=head1 SYNOPSIS

This is the main module for all TOME interactions.

=cut

=head1 DESCRIPTION

I really don't know how all of this works...

=cut

#}}}

#{{{ use's
use base 'CGI::Application';

use TOME::TemplateCallbacks;

use CGI::Application::Plugin::DBH qw(dbh_config dbh);
use CGI::Application::Plugin::Session;
use CGI::Application::Plugin::HTMLPrototype;

use DateTime::Format::Pg;

use Template;
use Params::Validate ':all';
use SQL::Interpolate qw(sql_interp);
use MIME::Lite;

use strict;
use warnings;
#}}}

#{{{ CONFIG

=head2 CONFIG

The CONFIG hash describes various and sundry configurata.

These configurata are:

=over

=item cgibase

the relative location of the cgi stuff

=item staticbase

unsure

=item templatepath 

the relative location of the templates

=item dbidatasource 

the database source.  funky format, description please?

=item dbiusername

username for the database

=item dbipassword

password for the database

=item notifyfrom

the "address" email messages are from

=item adminemail

the "address" email messages are sent to

=item devmode

whether or not this is being run in development mode

=item devemailto

the "address" email messages are sent to when in development mode

=back

Note: address format is 'Name <email@domain>`

=cut
our %CONFIG = (
	cgibase		=> '/perl/tome/cgi',
	staticbase	=> '/tome',

	templatepath	=> '../templates',

	dbidatasource   => 'dbi:Pg:dbname=tome;host=127.0.0.1',
	dbiusername	=> 'tome',
	dbipassword	=> 'password',

	notifyfrom	=> 'TOMEkeeper <tomekeeper@tome>',
	adminemail	=> 'TOMEadmin <tomeadmin@tome>',

	devmode		=> 0,
	devemailto	=> 'TOMEadmin <tomeadmin@tome>',
);
#}}}

require '../site-config.pl';

$ENV{PATH} = '/usr/sbin:/usr/bin:/sbin:/bin';


#{{{ cgiapp_init


=head2 cgiapp_init

This appears to (and probably does considering the name) set up various variables that are needed for CGI stuff.  It takes no arguments.

=cut

sub cgiapp_init {
	my $self = shift;

	$self->dbh_config($CONFIG{dbidatasource}, $CONFIG{dbiusername}, $CONFIG{dbipassword}, { RaiseError => 1});
	$self->session_config(
		CGI_SESSION_OPTIONS	=> [ 'driver:PostgreSQL', $self->query, { Handle => $self->dbh } ],
		SEND_COOKIE		=> 1,
		COOKIE_PARAMS		=> {
						-path	=> $TOME::CONFIG{cgibase},
					},
		DEFAULT_EXPIRY		=> '+24h',
	);
	$self->error_mode('error_runmode');

	$self->param('semesters', $self->semester_info);
	$self->param('currsemester', $self->semester_info({ current => 'true' }));
}
#}}}

#{{{ error_runmode

=head2 error_runmode

This is called when there is an error that we really don't know what caused.
This takes one argument:

=over

=item error

the error message (I presume)

=back

=cut

sub error_runmode {
	my $self = shift;

	my $error = shift;
	
	my $debug = $error . "\n\nTime: " . localtime(time);
	if(ref $self) { # Make sure we really have an object here
		$debug = $error . "\n\nUser: " . $self->param('user_info')->{username} . "\n\n" . $self->dump();
	}
	
	$self->sendmail({
		To	=> $TOME::CONFIG{adminemail},
		Subject	=> 'Unknown TOME Error',
		Data	=> $debug,
	});

	return $self->error({ message => "Internal exception error", extended => $debug });
}
#}}}

#{{{ error
=head2 error

error

=head2 error

This function is called when there is a fatal error.

This function takes a hash as an argument:

=over

=item message

the short error message

=item extended

the details of the error message

=back

=cut

sub error {
	my $self = shift;
	my $params = shift;
	
	warn "$params->{message}" . ($params->{extended} ? " - $params->{extended}" : '');
	
	my $output;
	eval {
		$output = $self->template({ file => 'error.html', vars => { message => $params->{message} }});
	};
	if($@) {
		$output = "TOME experienced a fatal error.";
	}

	return $output;
}
#}}}

#{{{tomebooks_search 

=head2 tomebooks_search 

This returns an array of found textbooks.

It takes arguments in the form of a hash:

=over

=item isbn

the isbn to look for

=item status

that status of the book (all, can_reserve, can_checkout, or in_collection)

=item title

the title of the book

=item author

the author of the book

=item  edition

the edition of the book

=item libraries

the libraries to look in for the book (Note: this is an array reference...whatever thatmeans.)

=item semester

the semester that the book is here for???

=back

=cut

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

	#warn "Statement of doom: $statement";
	#warn "Binds: " . join(',', @values);

	my $sth = $dbh->prepare($statement);
	
	$sth->execute(@values);
	
	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}
	
	return @results;
}
#}}}

#{{{expire_search 

=head2 expire_search 

This function returns a list of books that will expire on the given semester with the given libraries.

The arguments are given as a hash:

=over

=item semester

The semester in which the books will expire

=item libraries

The libraries the books reside in

=back

=cut

sub expire_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
		libraries       => { type => ARRAYREF },
	});

	my ($sql, @bind) = sql_interp('SELECT id AS tomebook FROM tomebooks WHERE expire <=', $params{semester}, 'AND timeremoved IS NULL AND library IN', $params{libraries}, 'ORDER BY expire');
	my $sth = $dbh->prepare($sql);

	$sth->execute(@bind);
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}
	return \@results;
}
#}}}

#{{{reservation_search 

=head2 reservation_search 

This function returns an array of books that are reserved in a given semester from given libraries.

The arguments are given as a hash:

=over

=item semester

the semester that the books are reserved for

=item libraries

the libraries that the books are in

=back

=cut

sub reservation_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
		libraries       => { type => ARRAYREF },
	});

	my ($sql, @bind) = sql_interp('SELECT tomebook, borrower, patrons.name as borrower_name, patrons.email as borrower_email, comments, semester, checkout FROM checkouts, patrons WHERE patrons.id = borrower AND semester <=', $params{semester}, 'AND reservation = TRUE AND library IN', $params{libraries}, 'ORDER BY semester, borrower_name ASC');
	
	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}
	return \@results;
}
#}}}

#{{{dueback_search 

=head2 dueback_search 

This function returns a list of books that are due back at the given semester from the given libraries.

The arguments are given as a hash:

=over

=item semester

the semester that the books are due back

=item libraries

the libraries that the books are in

=back

=cut

sub dueback_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
		libraries	=> { type => ARRAYREF },
	});

	my ($sql, @bind) = sql_interp('SELECT tomebook, borrower, patrons.name AS borrower_name, patrons.email AS borrower_email, comments, semester, checkout FROM checkouts, patrons WHERE semester <=', $params{semester}, 'AND patrons.id = borrower AND checkin IS NULL AND reservation = FALSE AND library IN', $params{libraries}, 'ORDER BY semester, borrower_name ASC');

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}
	return \@results;
}
#}}}

#{{{add_book 

=head2 add_book 

This function is used to add a book to TOME.  This is not for adding a real book, but for adding a book type.  Like adding a Class, not an Object.

This function takes a hash as an argument:

=over

=item isbn

The ISBN of the book

=item title

The Title of the book

=item author

The Author of the book

=item edition

The Edition of the book

=back

=cut

sub add_book {
	my $self = shift;

	my %params = validate(@_, {
		isbn	=> { type => SCALAR },
		title	=> { type => SCALAR },
		author	=> { type => SCALAR },
		edition	=> { type => SCALAR, default => 'None' },
	});

	my $dbh = $self->dbh;

	$params{isbn} = uc $params{isbn};

	my $sth = $dbh->prepare("INSERT INTO books (isbn, title, author, edition) VALUES (?, ?, ?, ?)");
	$sth->execute($params{isbn}, $params{title}, $params{author}, $params{edition});
}
#}}}

#{{{add_class 

=head2 add_class 

This function adds a class to TOME.

The arguments are given as a hash:

=over

=item id

The "School Readable" name of the class (that is, something like, MATH9999)

=item name

The Human Readable name of the Class

=back

=cut

sub add_class {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR },
		name	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	$dbh->do("INSERT INTO classes (id, name) VALUES (?, ?)", undef, @params{qw(id name)});
}
#}}}

#{{{patrons_search 

=head2 patrons_search 

This function finds patrons.

Arguments are given as a hash:

=over

=item id

The Nickname of the patron

=item name

The Real Name of the patron

=item email

The Email of the patron

=back

=cut

sub patrons_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		id		=> { type => SCALAR, optional => 1 },
		name		=> { type => SCALAR, optional => 1 },
		email		=> { type => SCALAR, optional => 1 },
	});

	my (@columns, @likecolumns, @conditions, @values);

	foreach (qw(name email)) {
		if(defined($params{$_})) {
			$params{$_} =~ s/([\\%_])/\\$1/g;
			push @likecolumns, $_;
			push @values, $params{$_};
		}
	}

	foreach (qw(id)) {
		if(defined($params{$_})) {
			push @columns, $_;
			push @values, $params{$_};
		}
	}


	foreach(@likecolumns) {
		push @conditions, "$_ ILIKE '%' || ? || '%'";
	}

	foreach(@columns) {
		push @conditions, "$_ = ?";
	}

	my $statement = 'SELECT id, name, email FROM patrons WHERE ' . join(' OR ', @conditions) . " ORDER BY email ASC";

	my $sth = $dbh->prepare($statement);
	
	$sth->execute(@values);
	
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}
	
	return @results;
}
#}}}

#{{{patron_add 

=head2 patron_add 

foo

=cut

sub patron_add {
	my $self = shift;

	my %params = validate(@_, {
		email	=> { type => SCALAR },
		name	=> { type => SCALAR },
	});

	my ($sql, @bind) = sql_interp('INSERT INTO patrons', \%params);
	my $sth = $self->dbh->prepare($sql);
	$sth->execute(@bind);
}
#}}}

#{{{patron_update 

=head2 patron_update 

foo

=cut

sub patron_update {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR },
		email	=> { type => SCALAR },
		name	=> { type => SCALAR },
	});

	my ($sql, @bind) = sql_interp('UPDATE patrons SET email = ', \$params{'email'}, ', name = ', \$params{'name'}, 'WHERE id = ', \$params{id});
	my $sth = $self->dbh->prepare($sql);
	$sth->execute(@bind);
}
#}}}

#{{{patron_info 

=head2 patron_info 

foo

=cut

sub patron_info {
	my $self = shift;
	
	my %params = validate(@_, {
		email	=> { type => SCALAR, optional => 1 },
		id	=> { type => SCALAR, regex => qr/^\d+$/, optional => 1 },
	});

	my ($sql, @bind);
	if($params{email}) {
		($sql, @bind) = sql_interp('SELECT id, email, name FROM patrons WHERE email ILIKE ', \$params{email});
	} elsif($params{id}) {
		($sql, @bind) = sql_interp('SELECT id, email, name FROM patrons WHERE id = ', \$params{id});
	} else {
		die "Neither email nor id specified in patron_info";
	}

	my $sth = $self->dbh->prepare($sql);
	$sth->execute(@bind);
	return $sth->fetchrow_hashref;
}
#}}}

#{{{books_search 

=head2 books_search 

foo

=cut

sub books_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		isbn		=> { type => SCALAR, optional => 1 },
		title		=> { type => SCALAR, optional => 1 },
		author		=> { type => SCALAR, optional => 1 },
		edition		=> { type => SCALAR, optional => 1 },
	});

	my (@likecolumns, @conditions, @values);

	foreach (qw(title author edition)) {
		if(defined($params{$_})) {
			$params{$_} =~ s/([\\%_])/\\$1/g;
			push @likecolumns, $_;
			push @values, $params{$_};
		}
	}

	foreach(@likecolumns) {
		push @conditions, "$_ ILIKE '%' || ? || '%'";
	}

	if(defined($params{isbn})) {
		$params{isbn} =~ s/([\\%_])/\\$1/g;
		push @conditions, "isbn ILIKE ? || '%'";
		push @values, $params{isbn};
	}
	
	my $statement = 'SELECT isbn FROM books WHERE ' . join(' AND ', @conditions) . " ORDER BY isbn ASC";

	my $sth = $dbh->prepare($statement);
	
	$sth->execute(@values);
	
	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}
	
	return @results;
}
#}}}

#{{{book_exists 

=head2 book_exists 

foo

=cut

sub book_exists {
	my $self = shift;

	# This sub has to be different from books_search because it searches for an exact ISBN

	my %params = validate (@_, {
		isbn	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT COUNT(isbn) FROM books WHERE isbn = ?");
	$sth->execute($params{isbn});

	my ($count) = $sth->fetchrow_array;
	return $count;
}
#}}}

#{{{book_classes 

=head2 book_classes 

foo

=cut

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
#}}}

#{{{add_tomebook 

=head2 add_tomebook 

foo

=cut

sub add_tomebook {
	my $self = shift;

	my %params = validate(@_, {
		isbn		=> { type => SCALAR },
		originator 	=> { type => SCALAR, regex => qr/^\d+$/ },
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
#}}}

#{{{classbook_add 

=head2 classbook_add 

foo

=cut

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
#}}}

#{{{tomebook_info 

=head2 tomebook_info 

foo

=cut

sub tomebook_info {
	my $self = shift;

	my %params = validate(@_, {
		tomebook	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my ($sql, @bind) = sql_interp('SELECT id, isbn, expire, comments, timedonated, library, timeremoved, originator FROM tomebooks WHERE', { id => $params{tomebook} });

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	return $sth->fetchrow_hashref();
}
#}}}

#{{{tomebook_info_deprecated 

=head2 tomebook_info_deprecated 

foo

=cut

sub tomebook_info_deprecated {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT tomebooks.isbn AS isbn, books.title AS title, books.author AS author, books.edition AS edition, originator, patrons.name as originator_name, patrons.email as originator_email, comments, expire, tomebooks.id AS id, timedonated, library, timeremoved FROM tomebooks, books, patrons WHERE tomebooks.isbn = books.isbn AND patrons.id = originator AND tomebooks.id = ?");
	$sth->execute($params{id});

	my $results = $sth->fetchrow_hashref;
	foreach(qw(timedonated timeremoved)) {
		if(defined($results->{$_})) {
			$results->{$_} = DateTime::Format::Pg->parse_timestamptz($results->{$_});
		}
	}

	return $results;
}
#}}}

#{{{tome_stats 

=head2 tome_stats 

foo

=cut

sub tome_stats {
	my $self = shift;

	my %params = validate(@_, {
		libraries	=> { type => ARRAYREF },
	});


	my $dbh = $self->dbh;

	my (%stats, $sql, @bind);
	($sql, @bind) = sql_interp('SELECT count(id) FROM tomebooks WHERE library IN', $params{libraries});
	my $sth = $dbh->prepare($sql); $sth->execute(@bind);
	($stats{totalcollection}) = $sth->fetchrow_array;

	($sql, @bind) = sql_interp('SELECT count(id) FROM tomebooks WHERE timeremoved IS NULL AND library IN', $params{libraries});
	$sth = $dbh->prepare($sql); $sth->execute(@bind);
	($stats{currentcollection}) = $sth->fetchrow_array;

	($sql, @bind) = sql_interp('SELECT count(checkout) FROM checkouts WHERE library IN', $params{libraries});
	$sth = $dbh->prepare($sql); $sth->execute(@bind);
	($stats{totalcheckouts}) = $sth->fetchrow_array;

	($sql, @bind) = sql_interp('SELECT count(checkout) FROM checkouts WHERE semester = ', $self->param('currsemester')->{id}, 'AND library IN', $params{libraries});
	$sth = $dbh->prepare($sql); $sth->execute(@bind);
	($stats{semestercheckouts}) = $sth->fetchrow_array;

	($sql, @bind) = sql_interp('SELECT originator, patrons.name as originator_name, patrons.email as originator_email, COUNT(tomebooks.id) AS books FROM tomebooks, patrons WHERE originator = patrons.id AND library IN', $params{libraries}, 'GROUP BY originator, patrons.name, patrons.email ORDER BY books DESC, originator_name ASC LIMIT 10');
	$sth = $dbh->prepare($sql); $sth->execute(@bind);
	while(my $result = $sth->fetchrow_hashref) {
		push @{$stats{top10donators}}, $result;
	}


	return \%stats;
}
#}}}

#{{{book_update 

=head2 book_update 

foo

=cut

sub book_update {
	my $self = shift;

	my %params = validate(@_, {
		isbn	=> { type => SCALAR },
		title 	=> { type => SCALAR },
		author	=> { type => SCALAR },
		edition	=> { type => SCALAR, optional => 1 },
	});

	my $dbh = $self->dbh;
	$dbh->do('UPDATE books SET title = ?, author = ?, edition = ? WHERE isbn = ?', undef, @params{qw(title author edition isbn)});
}
#}}}

#{{{tomebook_update 

=head2 tomebook_update 

foo

=cut

sub tomebook_update {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, regex => qr/^\d+$/ },
		originator 	=> { type => SCALAR, regex => qr/^\d+$/ },
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
#}}}

#{{{patron_checkouts 

=head2 patron_checkouts 

foo

=cut

sub patron_checkouts {
	my $self = shift;

	my %params = validate(@_, {
		patron	=> { type => SCALAR, regex => qr/^\d+$/ },
		all	=> { default => 0 },
	});

	my $dbh = $self->dbh;

	my ($sql, @bind);
	if($params{all}) {
		($sql, @bind) = sql_interp('SELECT id FROM checkouts WHERE', { borrower => $params{patron} }, 'ORDER BY checkout');
	} else {
		($sql, @bind) = sql_interp('SELECT id FROM checkouts WHERE checkin IS NULL and', { borrower => $params{patron} }, 'ORDER BY checkout');
	}

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	my @results;
	while(my @result = $sth->fetchrow_array()) {
		push @results, $result[0];
	}

	return \@results;
}
#}}}

#{{{checkout_info 

=head2 checkout_info 

foo

=cut

sub checkout_info {
	my $self = shift;

	my %params = validate(@_, {
		checkout	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my ($sql, @bind) = sql_interp('SELECT tomebook, semester, checkout, checkin, comments, reservation, library, uid, id, borrower FROM checkouts WHERE', { id => $params{checkout} });
	
	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	return $sth->fetchrow_hashref();
}
#}}}

#{{{checkout_history 

=head2 checkout_history 

foo

=cut

sub checkout_history {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT checkouts.id AS id, semester, borrower, patrons.name as borrower_name, patrons.email as borrower_email, checkout, reservation, checkin, comments, uid, username, library FROM checkouts, users, patrons WHERE uid = users.id AND patrons.id = borrower AND tomebook = ? ORDER BY semester DESC");
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
#}}}

#{{{find_orphans 

=head2 find_orphans 

foo

=cut

sub find_orphans {
	my $self = shift;

	my %params = validate(@_, {
		libraries       => { type => ARRAYREF },
	});

	my $dbh = $self->dbh;

	my ($sql, @bind) = sql_interp('SELECT DISTINCT isbn FROM tomebooks WHERE library IN', $params{libraries}, ' AND tomebooks.timeremoved IS NULL AND isbn NOT IN (SELECT books.isbn FROM books, classbooks WHERE classbooks.isbn = books.isbn) ORDER BY isbn');
	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);
	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

	return @results;
}
#}}}

#{{{find_useless 

=head2 find_useless 

foo

=cut

sub find_useless {
	my $self = shift;
	
	my %params = validate(@_, {
		libraries       => { type => ARRAYREF },
	});

	my $dbh = $self->dbh;

	my ($sql, @bind) = sql_interp('SELECT DISTINCT tomebooks.id AS id, tomebooks.isbn FROM tomebooks, classbooks WHERE tomebooks.timeremoved IS NULL AND classbooks.usable = FALSE AND tomebooks.isbn = classbooks.isbn AND library IN', $params{libraries}, ' AND tomebooks.id NOT IN (SELECT tomebooks.id FROM tomebooks, classbooks WHERE classbooks.usable = TRUE AND tomebooks.isbn = classbooks.isbn) ORDER BY tomebooks.isbn,id');
	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

	return @results;
}
#}}}

#{{{tomebook_checkout 

=head2 tomebook_checkout 

foo

=cut

sub tomebook_checkout {
	my $self = shift;

	my %params = validate(@_, {
		tomebook	=> { type => SCALAR, regex => qr/^\d+$/ },
		borrower	=> { type => SCALAR, regex => qr/^\d+$/ },
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
#}}}

#{{{tomebook_can_checkout 

=head2 tomebook_can_checkout 

foo

=cut

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
#}}}

#{{{tomebook_can_reserve 

=head2 tomebook_can_reserve 

foo

=cut

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
#}}}

#{{{tomebook_fill_reservation 

=head2 tomebook_fill_reservation 

foo

=cut

sub tomebook_fill_reservation {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	$dbh->do('UPDATE checkouts set checkout = now(), reservation = FALSE WHERE id = ?', undef, @params{qw(id)});
}
#}}}

#{{{tomebook_cancel_checkout 

=head2 tomebook_cancel_checkout 

foo

=cut

sub tomebook_cancel_checkout {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	$dbh->do('DELETE FROM checkouts WHERE id = ?', undef, @params{qw(id)});
}
#}}}

#{{{tomebook_checkin 

=head2 tomebook_checkin 

foo

=cut

sub tomebook_checkin {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	$dbh->do('UPDATE checkouts set reservation = FALSE WHERE id = ?', undef, @params{qw(id)}); # Obviously can't be reserved if it's checked in...
	$dbh->do('UPDATE checkouts SET checkin = now() WHERE id = ?', undef, @params{qw(id)});
}
#}}}

#{{{tomebook_remove 

=head2 tomebook_remove 

foo

=cut

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
#}}}

#{{{update_checkout_comments 

=head2 update_checkout_comments 

foo

=cut

sub update_checkout_comments {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, regex => qr/^\d+$/ },
		comments	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	$dbh->do('UPDATE checkouts SET comments = ? WHERE id = ?', undef, $params{comments}, $params{id});
}
#}}}

#{{{book_info 

=head2 book_info 

foo

=cut

sub book_info {
	my $self = shift;

	my %params = validate(@_, {
		isbn	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT isbn, title, author, edition FROM books WHERE isbn = ?");
	$sth->execute($params{isbn});
	return $sth->fetchrow_hashref;
}
#}}}

#{{{class_search 

=head2 class_search 

foo

=cut

sub class_search {
	my $self = shift;
	
	my %params = validate(@_, {
		id	=> { type => SCALAR, optional => 1 },
		name	=> { type => SCALAR, optional => 1 },
	});

	my (@conditions, @values);

	if(defined($params{id})) {
		_quote_like($params{id});
		push @conditions, "id ILIKE ? || '%'";
		push @values, $params{id};
	}
	
	if(defined($params{name})) {
		_quote_like($params{id});
		push @conditions, "name ILIKE '%' || ? || '%'";
		push @values, $params{id};
	}

	my $statement = 'SELECT id, name FROM classes ' . (@conditions ? 'WHERE ' . join(' AND ', @conditions) : '') . ' ORDER BY id ASC';

	my $sth = $self->dbh->prepare($statement);
	
	$sth->execute(@values);
	
	my @results;
	while(my $result = $sth->fetchrow_hashref) {
		push @results, $result;
	}
	
	return \@results;
}
#}}}

#{{{class_list 

=head2 class_list 

foo

=cut

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
#}}}

#{{{class_info 

=head2 class_info 

foo

=cut

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
#}}}

#{{{class_update_comments 

=head2 class_update_comments 

foo

=cut

sub class_update_comments {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR },
		comments	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	$dbh->do('UPDATE classes SET comments = ? WHERE id = ?', undef, $params{comments}, $params{id});
}
#}}}

#{{{classbook_update 

=head2 classbook_update 

foo

=cut

sub classbook_update {
	my $self = shift;

	my %params = validate(@_, {
		class		=> { type => SCALAR },
		isbn		=> { type => SCALAR },
		usable	 	=> { type => SCALAR, regex => qr/^true|false$/ },
		verified	=> { type => SCALAR, regex => qr/^\d+$/ },
		uid		=> { type => SCALAR, regex => qr/^\d+$/ },
		comments	=> { type => SCALAR },
	});


	my ($sql, @bind) = sql_interp('UPDATE classbooks SET', { usable => $params{usable}, verified => $params{verified}, comments => $params{comments}, uid => $params{uid} }, 'WHERE', { class => $params{class}, isbn => $params{isbn} });
	$self->dbh->do($sql, undef, @bind);
}
#}}}

#{{{class_delete 

=head2 class_delete 

foo

=cut

sub class_delete {
	my $self = shift;
	
	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\w+$/ },
	});

	my $dbh = $self->dbh;

	$dbh->do('DELETE FROM classbooks WHERE class = ?', undef, @params{qw(id)});
	$dbh->do('DELETE FROM classes WHERE id = ?', undef, @params{qw(id)});
}
#}}}

#{{{class_delete_book 

=head2 class_delete_book 

foo

=cut

sub class_delete_book {
	my $self = shift;

	my %params = validate(@_, {
		class		=> { type => SCALAR },
		isbn		=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	$dbh->do('DELETE FROM classbooks WHERE class = ? AND isbn = ?', undef, @params{qw(class isbn)});
}
#}}}

#{{{user_info 

=head2 user_info 

foo

=cut

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
		$sth = $self->dbh->prepare($statement . ' WHERE username ILIKE ? ORDER BY disabled, username');
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
#}}}

#{{{user_add 

=head2 user_add 

foo

=cut

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
#}}}

#{{{user_update 

=head2 user_update 

foo

=cut

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
#}}}

#{{{semester_info 

=head2 semester_info 

foo

=cut

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
#}}}

#{{{semester_set 

=head2 semester_set 

foo

=cut

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
#}}}

#{{{semester_add 

=head2 semester_add 

foo

=cut

sub semester_add {
	my $self = shift;

	my %params = validate(@_, {
		name	=> { type => SCALAR },
	});

	my ($sql, @bind) = sql_interp('INSERT INTO semesters', { name => $params{name} });
	$self->dbh->do($sql, undef, @bind);
}
#}}}

#{{{library_add 

=head2 library_add 

foo

=cut

sub library_add {
	my $self = shift;

	my %params = validate(@_, {
		name	=> { type => SCALAR },
	});

	my ($sql, @bind) = sql_interp('INSERT INTO libraries', { name => $params{name} });
	$self->dbh->do($sql, undef, @bind);
}
#}}}

#{{{library_info 

=head2 library_info 

foo

=cut

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
#}}}

#{{{library_users 

=head2 library_users 

foo

=cut

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
#}}}

#{{{library_access 

=head2 library_access 

foo

=cut

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
#}}}

#{{{template 

=head2 template 

foo

=cut

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
		prototype	=> $self->prototype,
		tome		=> TOME::TemplateCallbacks->new($self),
	);

	if($self->param('user_info')) {
		$params{vars}{user_info} = $self->param('user_info');
	}

	my $tt = Template->new({INCLUDE_PATH => $CONFIG{templatepath}, ($params{plain} ? () : (PRE_PROCESS => 'header.html', POST_PROCESS => 'footer.html'))}) or die $Template::ERROR;
	my $output;

	$tt->process($params{file}, $params{vars}, \$output) or die $tt->error;

	return $output;
}
#}}}

#{{{sendmail 

=head2 sendmail 

foo

=cut

sub sendmail {
	my $self = shift;

	my %params = validate(@_, {
		From	=> { type => SCALAR, default => $TOME::CONFIG{notifyfrom} },
		To	=> { type => SCALAR, default => $TOME::CONFIG{amdinemail} },
		Subject	=> { type => SCALAR },
		Data	=> { type => SCALAR },
	});

	if($TOME::CONFIG{devmode} && $TOME::CONFIG{devemailto}) {
		$params{Data} = "** Devmode email originally to: $params{To} **\n\n" . $params{Data};
		$params{To} = $TOME::CONFIG{devemailto};
	}

	my $message = MIME::Lite->new(
		From	=> $params{From},
		To	=> $params{To},
		Subject	=> $params{Subject},
		Data	=> $params{Data},
	);
	$message->send;
}
#}}}

#{{{_quote_like 

=head2 _quote_like 

foo

=cut

sub _quote_like {
	return ($_[0] =~ s/([\\%_])/\\$1/g);
}
#}}}

1;

=head1 AUTHOR

Curtis Fjord Hawthornre

=cut

=head1 BUGS

??

=cut

=head1 SEE ALSO

postgreSQL

=cut

=head1 COPYRIGHT

gpl?

=cut


