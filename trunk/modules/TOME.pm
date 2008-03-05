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

=item dbidbname

the database name that TOME is stored under

=item dbihostname

the hostname of the database server

=item dbiport

the port the database server is running on

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
our %CONFIG;
#}}}

require '../site-config.pl';

$ENV{PATH} = '/usr/sbin:/usr/bin:/sbin:/bin';


#{{{ cgiapp_init


=head2 cgiapp_init

This appears to (and probably does considering the name) set up various variables that are needed for CGI stuff.  It takes no arguments.

=cut

sub cgiapp_init {
	my $self = shift;

        # Note that it is important that RaiseError and AutoCommit get turned on.  RaiseError means that if there is ever any sort of
        # SQL error,then the DBI will cause a 'die' that gets handled by the error_runmode.  AutoCommit means that every SQL statement
        # is executed inside of its own transaction by default.  This can be temporarily turned off by using the DBI begin_work method
        # and then turned back on with the commit method.
	$self->dbh_config("dbi:Pg:dbname=$CONFIG{dbidbname};host=$CONFIG{dbihostname}", $CONFIG{dbiusername}, $CONFIG{dbipassword}, { RaiseError => 1, AutoCommit => 1});
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
		$debug = $error;
	       	if($self->param('user_info')) {
			$debug .= "\n\nUser: " . $self->param('user_info')->{username};
		}
		$debug .= "\n\n" . $self->dump();
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
		$output = $self->template({ file => 'error.html', vars => { message => $params->{message}, extended => $params->{extended} }});
	};
	if($@) {
		$output = "TOME experienced a fatal error.";
	}

	return $output;
}
#}}}

#{{{isbn_search

=head2 isbn_search

This returns an array of found isbns.

It takes arguments in the form of a hash:

=over

=item title

the title of the book

=item author

the author of the book

=item edition

the edition of the book

=back

=cut

sub isbn_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		title		=> { type => SCALAR, optional => 1 },
		author		=> { type => SCALAR, optional => 1 },
		edition		=> { type => SCALAR, optional => 1 },
	});

	my (@likecolumns, @values, @conditions);

	foreach (qw(title author edition)) {
		if(defined($params{$_})) {
			_quote_like($params{$_});
			push @likecolumns, $_;
			push @values, $params{$_};
		}
	}

        # If there are no parameters specified, don't run the search
        unless(@likecolumns) {
            return ();
        }

	foreach(@likecolumns) {
		push @conditions, "$_ ILIKE '%' || ? || '%'";
	}

	my $statement = 'SELECT isbn FROM books WHERE ' . join(' AND ', @conditions) . ' ORDER BY isbn';

	my $sth = $dbh->prepare($statement);

	$sth->execute(@values);

	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

	return @results;
}
#}}}

#{{{tomebook_availability_search

=head2 tomebook_availability_search

Returns a list of TOME books available given certain conditions

It takes arguments in the form of a hash:

=over

=item isbn

the isbn to look for

=item status

that status of the book (all, can_checkout, or in_collection).  Defaults to in_collection.

=item semester

the semester id to consider when status is can_checkout.  Defaults to the current semester

=item libraries

the libraries to look in for the book (Note: this is an array reference)

=back

=cut

sub tomebook_availability_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		isbn		=> { type => SCALAR },
		status		=> { type => SCALAR, regex => qr/^all|can_checkout|in_collection$/, default => 'in_collection' },
		semester	=> { type => SCALAR, default => $self->param('currsemester')->{id} },
		libraries	=> { type => ARRAYREF },
	});

	# I've decided to require listing what libraries you want, if you give an empty list, no books can be found
	unless(@{$params{libraries}}) {
		return ();
	}

	my ($sql, @bind);

	if($params{status} eq 'all') {
		($sql, @bind) = sql_interp('SELECT id FROM tomebooks WHERE', {isbn => $params{isbn}, library => $params{libraries}});
	} elsif($params{status} eq 'in_collection') {
		($sql, @bind) = sql_interp('SELECT id FROM tomebooks WHERE', {isbn => $params{isbn}, library => $params{libraries}}, 'AND timeremoved IS NULL');
	} elsif($params{status} eq 'can_checkout') {
		($sql, @bind) = sql_interp('SELECT id FROM tomebooks WHERE', {isbn => $params{isbn}, library => $params{libraries}}, 'AND timeremoved IS NULL AND id NOT IN (SELECT tomebook FROM checkouts WHERE', {semester => $params{semester}}, 'AND checkout IS NOT NULL)');
	} else {
		die 'Unknown status requested.';
	}

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

	return \@results;
}
#}}}

#{{{donated_search
sub donated_search {

=head2 donated_search

Takes a hash like this:

patron_id => id

and returns an array of book ids

=cut

  my $self = shift;

  my %params = validate(@_, {
      patron_id => {  type => SCALAR, regex => qr/^\d+$/ }
    });

  my $dbh = $self->dbh;

  my $sth = $dbh->prepare('SELECT id FROM tomebooks WHERE  originator = ?');
  $sth->execute($params{patron_id});

  my @results;
  while(my @result = $sth->fetchrow_array) {
    push @results, $result[0];
  }
  return @results;


}
#}}}

#{{{tomebook_availability_search_amount

=head2 tomebook_availability_search_amount

Returns the number of TOME books available given certain conditions

It takes arguments in the form of a hash:

=over

=item isbn

the isbn to look for

=item status

that status of the book (all, can_reserve, or in_collection).  Defaults to in_collection.

=item semester

the semester id to consider when status is can_reserve.  Defaults to the current semester

=item libraries

the libraries to look in for the book (Note: this is an array reference)

=back

=cut

sub tomebook_availability_search_amount {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		isbn		=> { type => SCALAR },
		status		=> { type => SCALAR, regex => qr/^all|can_reserve|in_collection$/, default => 'in_collection' },
		semester	=> { type => SCALAR, default => $self->param('currsemester')->{id} },
		libraries	=> { type => ARRAYREF },
	});

	# I've decided to require listing what libraries you want, if you give an empty list, no books can be found
	unless(@{$params{libraries}}) {
		return ();
	}

	my ($sql, @bind);

	if($params{status} eq 'all') {
		($sql, @bind) = sql_interp('SELECT count(*) FROM tomebooks WHERE', {isbn => $params{isbn}, library => $params{libraries}});
	} elsif($params{status} eq 'in_collection') {
		($sql, @bind) = sql_interp('SELECT count(*) FROM tomebooks WHERE', {isbn => $params{isbn}, library => $params{libraries}}, 'AND timeremoved IS NULL');
	} elsif($params{status} eq 'can_reserve') {
		my @library_reservations;
		foreach(@{$params{libraries}}) {
			push @library_reservations, 'tomebooks_available_to_reserve(?, ?, ?) - tomebooks_reserved(?, ?, ?)';
			push @bind, (($params{isbn}, $_, $params{semester}) x 2);
		}
		$sql = 'SELECT ' . join(' + ', @library_reservations);
	} else {
		die 'Unknown status requested.';
	}

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	return ($sth->fetchrow_array)[0];
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

#{{{reservation_info

=head2 reservation_info

This function returns an array of hashrefs about a reservations given an ID.

Arguments are as a hashref:

=over

=item id

The reservation ID

=back

The returned hashref contains:

=over

=item id

The reservation ID

=item isbn

The ISBN the reservation is for

=item uid

The user id of the TOMEkeeper responsible for the reservation

=item patron

The id of the patron the reservation is for

=item reserved

The time of the reservation

=item fulfilled

The time of the fulfilment of the reservation.  If this is null, then the reservation has not been fulfilled.

=item comment

Any comments about the reservation

=item library_from

The library that is responsible for the reservation

=item library_to

The library that has the book that is being reserved

=item semester

The semester that the reservation is for

=back

=cut

sub reservation_info {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my ($sql, @bind) = sql_interp('SELECT id, isbn, uid, patron, reserved, fulfilled, comment, library_from, library_to, semester FROM reservations WHERE', { id => $params{id} });

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	my $reservation = $sth->fetchrow_hashref;

	foreach(qw(reserved fulfilled)) {
		if(defined($reservation->{$_})) {
			$reservation->{$_} = DateTime::Format::Pg->parse_timestamptz($reservation->{$_});
		}
	}

	return $reservation;
}
#}}}

#{{{reservation_fulfill
=head2 reservation_fulfill

This function turns reservations into checkouts

Arguments are given as a hashref

=over

=item reservation_id

The ID of the reservation to turn into a checkout

=item tomebook_id

The ID of the tomebook to be used for the checkout

=back

The function returns the ID of the checkout that was created

=cut

sub reservation_fulfill {
	my $self = shift;

	my %params = validate(@_, {
		reservation_id	=> { type => SCALAR, regex => qr/^\d+$/, untaint => 1 },
		tomebook_id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

        if (grep {$self->reservation_info({ id =>$params{reservation_id}})->{library_from} == $_} ($self->library_access({user => $self->session->param('id')}))) {

	$self->dbh->begin_work;
        $self->dbh->do('LOCK TABLE reservations, checkouts');
        my ($sql, @bind) = sql_interp('UPDATE reservations SET fulfilled = now() WHERE', { id => $params{reservation_id} });
        $self->dbh->do($sql, undef, @bind);

        # This sorta scary looking bit of SQL just transfers the information from the reservations table into the checkout table
        # SQL is used because it's faster/easier than making calls to the methods to retrieve info about the reservation and
        # putting that info into the query.  Using SQL also makes it easy to do an embedded check to ensure that the type
        # of TOME book we're turning the reservation into matches the type of book the reservation was for (that's what the
        # tomebooks.isbn = reservations.isbn part of the WHERE clause is for)
          ($sql, @bind) = sql_interp(
        'INSERT INTO ',
          'checkouts ('.
            'tomebook, '.
            'semester, '.
            'comments, '.
            'library, '.
            'uid, '.
            'borrower '.
          ') '.
            'SELECT ',
          \$params{tomebook_id}, ' as tomebook, '.
          'reservations.semester, '.
          'reservations.comment as comments, '.
          'reservations.library_from as library, '.
          'reservations.uid, '.
          'reservations.patron as borrower '.
          'FROM reservations, tomebooks '.
          'WHERE '.
          'tomebooks.isbn = reservations.isbn and ', {
            'reservations.id' => $params{reservation_id},
            'tomebooks.id' => $params{tomebook_id}
          }
        );

        $self->dbh->do($sql, undef, @bind);

	$self->dbh->commit;

	my ($id) = $self->dbh->selectrow_array("SELECT currval('public.checkouts_id_seq')");
	return $id;

      }

      return -1;
}


#}}}

#{{{reservation_create
=head2 reservation_create

This function creates a reservation.

Arguments are in a hashref.  Unless otherwise noted, all parameters are required.

=over

=item isbn

The ISBN of the book to reserve

=item uid

The user ID of the TOMEkeeper responsible for the checkout

=item patron

The patron ID of the borrower

=item comment (optional)

Any comments about the reservation

=item library_from

The library responsible for making the reservation (the library that is requesting the book)

=item library_to

The library the reservation is being made to (the library that has the book that is being requested)

=item semester

The semester the reservation is valid for

=back

=cut

sub reservation_create {
	my $self = shift;

	my %params = validate(@_, {
		isbn		=> { type => SCALAR, regex => qr/^\d+$/ },
		uid		=> { type => SCALAR, regex => qr/^\d+$/ },
		patron		=> { type => SCALAR, regex => qr/^\d+$/ },
		comment		=> { type => SCALAR, optional => 1 },
		library_from	=> { type => SCALAR, regex => qr/^\d+$/ },
		library_to	=> { type => SCALAR, regex => qr/^\d+$/ },
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my ($sql, @bind) = sql_interp('INSERT INTO reservations', \%params);


	$self->dbh->do($sql, undef, @bind);

	my ($id) = $self->dbh->selectrow_array("SELECT currval('public.reservations_id_seq')");
	return $id;
}

#}}}

#{{{reservation_search

=head2 reservation_search

This function returns an array of reservation ids matching search criteria

The arguments are given as a hash.  They're all optional, but if you don't give any, then just an empty array will be returned.

=over

=item semester

The semester that the books are reserved for

=item library_to

An arrayref of libraries the reservations can be going to (the libraries that have the books)

=item library_from

An arrayref of libraries the reservations can be coming from (the libraries that are requesting the books)

=item patron

A patron ID identifying the patron reserving the books

=back

Returns an array of reservation id's.

=cut

sub reservation_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		semester	=> { type => SCALAR, regex => qr/^\d+$/, optional => 1  },
		library_to	=> { type => ARRAYREF, optional => 1 },
		library_from	=> { type => ARRAYREF, optional => 1 },
		patron		=> { type => SCALAR, regex => qr/^\d+$/, optional => 1 },
                all             => { type => SCALAR, regex => qr/^true|false$/, default => 'false' },
	});

        my %conditions;
        foreach(qw(semester library_to library_from patron)) {
		if(defined($params{$_})) {
                  $conditions{$_} = $params{$_};
                }
        }

	# If we aren't given anything to do, don't do anything
	return unless(%conditions);

	my ($sql, @bind) = sql_interp('SELECT id FROM reservations WHERE', \%conditions, $params{all} eq 'false' ? 'AND fulfilled IS NULL' : '');

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);
	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

	return \@results;
}
#}}}

#{{{reservation_cancel
sub reservation_cancel {

=head2 reservation_cancel

takes a hash:
id => reservation_id

  and deletes the reservation from the table entirely
=cut

  my $self = shift;

  my %params = validate(@_, {
      id	=> { type => SCALAR, regex => qr/^\d+$/ },
    });

  if ((grep {$self->reservation_info({ id =>$params{id}})->{library_from} == $_} ($self->library_access({user => $self->session->param('id')}))) ||
    (grep {$self->reservation_info({ id =>$params{id}})->{library_to} == $_} ($self->library_access({user => $self->session->param('id')})))
  )
  {
    my ($sql, @bind) = sql_interp('DELETE FROM reservations WHERE ',{id => $params{'id'}} );
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@bind);
    return 1;
  }
  return 0;
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

The numeric, databasical id of the patron

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

This function adds a patron to the database.

This function takes arguments as a hash as follows:

=over

=item email

The email address of the patron

=item name

The name of the patron (Often the patron's nickname)

=back

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

This function changes the patron at a given id.

The arguments to this function are given as a hash, as usual:

=over

=item id

The id of the patron to change

=item email

The email to set for the given id

=item name

The name to set to the given id

=back

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

This function returns information about patrons matching certain critereon.

The function looks for the following to parameters in a hash in this order:

=over

=item email

The email to try to find

=item id

The exact id to find

=back

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

This function returns an array of books that match a number of critereon.

frew

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

Takes an argument in the form of a hash:

=over

=item tomebook

The id of the tomebook to lookup

=back

Returns a hash:

=over

=item id

id of the tomebook found

=item isbn

isbn of the tomebook found

=item expire

when the book expires

=item comments

any comments on the book

=item timedonated

when the book was donated

=item originator

originator of tomebook

=item library

library of tomebook

=back

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

#{{{patron_classes

=head2 patron_classes

This function finds the classes associated with a patron for a given semester.

Arguments are given as a hash:

=over

=item patron

The numeric, databasical id of the patron

=item semester

The ID of the semester to retrieve classes for.

=back

Returns: An arrayref containing class ids.

=cut

sub patron_classes {
	my $self = shift;

	my %params = validate(@_, {
		patron		=> { type => SCALAR, regex => qr/^\d+$/ },
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my ($sql, @bind) = sql_interp('SELECT class FROM patron_classes WHERE', \%params);

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	my @results;
	while(my @result = $sth->fetchrow_array()) {
		push @results, $result[0];
	}

	return \@results;

}

#}}}

#{{{patron_add_class

=head2 patron_add_class

This function adds a class associated with a patron for a given semester.

Arguments are given as a hash:

=over

=item patron

The numeric, databasical id of the patron

=item semester

The ID of the semester to retrieve classes for.

=item class

The ID of the class to add.

=back

Returns: Nothing.

=cut

sub patron_add_class {
	my $self = shift;

	my %params = validate(@_, {
		patron		=> { type => SCALAR, regex => qr/^\d+$/ },
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
		class		=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	my ($sql, @bind) = sql_interp('INSERT into patron_classes', \%params);

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);
}

#}}}

#{{{patron_delete_class

=head2 patron_delete_class

This function deletes a class associated with a patron for a given semester.

Arguments are given as a hash:

=over

=item patron

The numeric, databasical id of the patron

=item semester

The ID of the semester to retrieve classes for.

=item class

The ID of the class to add.

=back

Returns: Nothing.

=cut

sub patron_delete_class {
	my $self = shift;

	my %params = validate(@_, {
		patron		=> { type => SCALAR, regex => qr/^\d+$/ },
		semester	=> { type => SCALAR, regex => qr/^\d+$/ },
		class		=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my ($sql, @bind) = sql_interp('DELETE FROM patron_classes WHERE', \%params);

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);
}

#}}}

#{{{checkout_search

=head2 checkout_search

This function returns an array of checkout ids matching search criteria

The arguments are given as a hash.  They're all optional, but something other than just status must be specified before anything other than an empty array will be returned.

=over

=item semester

The semester that the books are checked out for

=item library_to

An arrayref of libraries the checkout can be going to (the libraries that have the books)

=item library_from

An arrayref of libraries the checkouts can be coming from (the libraries that are requesting the books)

=item patron

A patron ID identifying the patron checking out the books

=item tomebook

The id of a TOME book

=item status

Either checked_out (still checked out), checked_in (the checkout is finished), or all.  Defaults to checked_out

=back

=cut

sub checkout_search {
	my $self = shift;

	my $dbh = $self->dbh;

	my %params = validate(@_, {
		semester	=> { type => SCALAR, regex => qr/^\d+$/, optional => 1  },
		library_to	=> { type => ARRAYREF, optional => 1 },
		library_from	=> { type => ARRAYREF, optional => 1 },
		patron		=> { type => SCALAR, regex => qr/^\d+$/, optional => 1 },
		tomebook	=> { type => SCALAR, regex => qr/^\d+$/, optional => 1 },
		status		=> { type => SCALAR, regex => qr/^checked_out|checked_in|all$/, default => 'checked_out' },
	});

	my @conditions;
	foreach (qw(semester tomebook)) {
		if($params{$_}) {
			push @conditions, { 'checkouts.' . $_ => $params{$_} };
		}
	}

	if($params{patron}) {
		push @conditions, { 'checkouts.borrower' => $params{patron} };
	}

	if($params{library_from}) {
		push @conditions, { 'checkouts.library' => $params{library_from} };
	}

	if($params{library_to}) {
		push @conditions, { 'tomebooks.library' => $params{library_to} };
	}

	# If we aren't given anything to do, don't do anything
	# Note that this check happens /before/ the conditions are added for 'status'
	# This is because 'status' has a default and will always result in a condition
	unless(@conditions) {
		return ();
	}

	if($params{status} eq 'checked_out') {
		push @conditions, 'checkouts.checkin IS NULL';
	} elsif($params{status} eq 'checked_in') {
		push @conditions, 'checkouts.checkin IS NOT NULL';
	} elsif($params{status} eq 'all') {
		# Nothing special to do here
	} else {
		die 'An unknown status was selected';
	}

        # Note that the unary + must be here to make sure Perl interprets the {} as a block
        @conditions = map {+"AND", $_} @conditions;

	my ($sql, @bind) = sql_interp('SELECT checkouts.id FROM checkouts, tomebooks WHERE tomebooks.id = checkouts.tomebook', @conditions);

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);
	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}
	return @results;
}
#}}}

#{{{checkout_info

=head2 checkout_info

Returns info about a checkout, given an id.

Arguments are as a hashref:

=over

=item id

The ID of the checkout to retrieve info about

=back

Returns a hashref:

=over

=item tomebook

The tomebook ID of the checkout

=item semester

The semester of the checkout

=item checkout

The time of the checkout

=item checkin

The time of the check in.  If this is null, the book is still checked out.

=item comments

Comments about the checkout

=item library

The library responsible for the checkout

=item uid

The id of the TOMEkeeper responsible for the checkout

=item id

The id of the checkout

=item borrower

The id of the patron that checked the book out

=back

=cut

sub checkout_info {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my ($sql, @bind) = sql_interp('SELECT tomebook, semester, checkout, checkin, comments, library, uid, id, borrower FROM checkouts WHERE', { id => $params{id} });

	my $sth = $dbh->prepare($sql);
	$sth->execute(@bind);

	my $checkout = $sth->fetchrow_hashref();

	foreach(qw(checkout checkin)) {
		if(defined($checkout->{$_})) {
			$checkout->{$_} = DateTime::Format::Pg->parse_timestamptz($checkout->{$_});
		}
	}

	return $checkout;
}

#}}}

#{{{checkout_history

=head2 checkout_history

slated for deletion

=cut

sub checkout_history {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT checkouts.id AS id, semester, borrower, patrons.name as borrower_name, patrons.email as borrower_email, checkout, checkin, comments, uid, username, library FROM checkouts, users, patrons WHERE uid = users.id AND patrons.id = borrower AND tomebook = ? ORDER BY semester DESC");
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

#{{{tomebook_cancel_checkout

=head2 tomebook_cancel_checkout

takes hash as input:

 id=> checkout_id

=cut

sub tomebook_cancel_checkout {
  my $self = shift;

  my %params = validate(@_, {
      id	=> { type => SCALAR, regex => qr/^\d+$/ },
    });

  if (grep {$self->tomebook_info({ tomebook => $self->checkout_info({id => $params{id}})->{tomebook}})->{library} == $_} ($self->library_access({user => $self->session->param('id')}))) {

  my $dbh = $self->dbh;

  #$dbh->do('DELETE FROM checkouts WHERE id = ?', undef, @params{qw(id)});
  return 1;
  }
  return 0;
}
#}}}

#{{{tomebook_checkin

=head2 tomebook_checkin

This function checks in a TOME book.  Nothing is returned.  Arguments are a hashref:

=over

=item id

The id of the TOME book

=back

=cut

sub tomebook_checkin {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

      if (grep {$self->tomebook_info({ tomebook => $self->checkout_info({id => $params{id}})->{tomebook}})->{library} == $_} ($self->library_access({user => $self->session->param('id')}))) {
	my $dbh = $self->dbh;

	$dbh->do('UPDATE checkouts SET checkin = now() WHERE id = ?', undef, @params{qw(id)});
        return 1;
      }
      return 0;
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

Takes a hash as an argument:

=over

=item isbn

isbn of book

=back

returns a hash:

=over

=item isbn

isbn of book

=item title

title of book

=item author

author of book

=item edition

edition of book

=back

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

This function can return either a complete listing of classes IDs or a list based on search criteria.  A match only has to satisfy one of the paramters specified to be returned.  In other words, the search criteria use OR instead of AND.

The arguments are as a hashref:

=over

=item id

A case-insensitive search will be performed on the ID given

=item name

A case-insensitive search will be performed on the class name given

=back

This function returns an array of class IDs.

=cut

sub class_search {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, optional => 1 },
		name	=> { type => SCALAR, optional => 1 },
	});

	my (@conditions, @values);

	foreach(qw(id name)) {
		if(defined($params{$_})) {
			_quote_like($params{$_});
			push @conditions, "$_ ILIKE '%' || ? || '%'";
			push @values, $params{$_};
		}
	}

	my $statement = 'SELECT id FROM classes ' . (@conditions ? 'WHERE ' . join(' OR ', @conditions) : '') . ' ORDER BY id ASC';

	my $sth = $self->dbh->prepare($statement);

	$sth->execute(@values);

	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

	return @results;
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

This method returns information about class

Arguments are given as a hash:

=over

=item id

The numeric, databasical id of the class

=back

Returns a hash:

=over

=item name

The text name of the class

=item comments

The text comments about the class

=item verified

Semester ID for which the class has been verified.

=item uid

User ID of the TOMEkeeper that did the last verification

=back

=cut

sub class_info {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT name, comments, verified, uid FROM classes WHERE id = ?");
	$sth->execute($params{id});
	return $sth->fetchrow_hashref;
}
#}}}

#{{{class_books

=head2 class_books

This method returns books associated with a class

Arguments are given as a hash:

=over

=item id

The numeric, databasical id of the class

=back

Returns an arrayref to an array of hashrefs:

=over

=item isbn

ISBN of the book

=item verified

Semester ID for when the book was last verified

=item comments

Comments about the verification of the book

=item usable

Boolean indicating if the book is usable or not

=item uid

The user id of the TOMEkeeper who did the verification

=back

=cut

sub class_books {
	my $self = shift;

	my %params = validate(@_, {
		id	=> { type => SCALAR, regex => qr/^\d+$/ },
	});

	my $dbh = $self->dbh;

	my $sth = $dbh->prepare("SELECT isbn, usable, verified, comments, uid FROM classbooks WHERE class = ? ORDER BY usable,isbn DESC");
	$sth->execute($params{id});
	my @books;
	while(my $result = $sth->fetchrow_hashref) {
		push @books, $result;
	}

	return \@books;
}
#}}}

#{{{class_update_verified

=head2 class_update_verified

This method upates information about a class

Arguments are given as a hash:

=over

=item id

The numeric, databasical id of the class

=item verified

The ID of the semester for which the class has been verified

=item uid

The ID of the TOMEkeeper that did the verification

=back

Returns nothing.

=cut

sub class_update_verified {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, regex => qr/^\d+$/ },
		verified	=> { type => SCALAR, regex => qr/^\d+$/ },
		uid		=> { type => SCALAR, regex => qr/^\d+$/ },

	});

	my $dbh = $self->dbh;

	my ($sql, @bind) = sql_interp('UPDATE classes SET', {verified => $params{verified}, uid => $params{uid}}, 'WHERE', {id => $params{id}});
	my $sth = $dbh->prepare($sql);

	$sth->execute(@bind);
}
#}}}

#{{{class_info_deprecated

=head2 class_info_deprecated

foo

=cut

sub class_info_deprecated {
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
		id		=> { type => SCALAR, regex => qr/^\d+$/ },
		comments	=> { type => SCALAR, regex => qr/^\d+$/ },
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

	my $statement = 'SELECT id, first_name, last_name, username, email, second_contact, notifications, admin, disabled, password FROM users';
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

	my ($id) = $self->dbh->selectrow_array("SELECT currval('public.users_id_seq')");
	return $id;
}
#}}}

#{{{user_update

=head2 user_update

This method updates a user (not a patron).

Arguments are as a hashref.  Everything other than id is optional.

=over

=item id

The user to be modified

=back

=item username

The new username

=item email

The new email

=item notifications

The new notifications flag.  Either 'true' or 'false'.

=item disabled.

The new disabled flag.  Either 'true' or 'false'.

=item admin

The new admin flag.  Either 'true' or 'false'.

=item password

The new password

=back

This method returns nothing.

=cut

sub user_update {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, regex => qr/^\d+$/ },
                first_name      => { type => SCALAR, optional => 0 },
                last_name       => { type => SCALAR, optional => 0 },
		username	=> { type => SCALAR, optional => 1 },
		email		=> { type => SCALAR, optional => 1 },
		second_contact	=> { type => SCALAR, optional => 1 },
		notifications	=> { type => SCALAR, regex => qr/^true|false$/, optional => 1 },
		disabled	=> { type => SCALAR, regex => qr/^true|false$/, optional => 1 },
		admin		=> { type => SCALAR, regex => qr/^true|false$/, optional => 1 },
		password	=> { type => SCALAR, optional => 1 },
	});

	my %user;
	foreach(qw(username email first_name last_name second_contact notifications admin disabled password)) {
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

        # This must happen within a transaction, because, for a little while, the semesters table has no active semesters
	$self->dbh->begin_work;
        $self->dbh->do('LOCK TABLE semesters');
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

	my ($id) = $self->dbh->selectrow_array("SELECT currval('public.semesters_id_seq')");
	return $id;
}
#}}}

#{{{ library_update
=head2 library_update

This method updates a library.

Arguments are as a hashref.  Everything other than id is optional.

=over

=item id

The ID of the library to be updated.

=item name

The new name of the library.

=item intertome

The InterTOME status of the library.  Either 'true' or 'false'.

=cut

sub library_update {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, regex => qr/^\d+$/ },
		name		=> { type => SCALAR, optional => 1 },
		intertome	=> { type => SCALAR, regex => qr/^true|false$/, optional => 1 },
	});

	my %library;
	foreach(qw(name intertome)) {
		if(defined($params{$_})) { $library{$_} = $params{$_}; }
	}

	my ($sql, @bind) = sql_interp('UPDATE libraries SET', \%library, 'WHERE id =', $params{id});
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

Returns information about the libraries in the system.  If a Library ID is given, then a hashref containing the id, name, and InterTOME status (true or false) of that particular library will be returned.  If no id is given, then an arrayref containing hashrefs about every library in the system will be returned.

It takes arguments in the form of a hash:

=over

=item id

The id of the library to retrieve information about.

=back

=cut

sub library_info {
	my $self = shift;

	my %params = validate(@_, {
		id		=> { type => SCALAR, optional => 1 },
	});

	my $statement = 'SELECT id, name, intertome FROM libraries';
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

#{{{library_not_access
sub library_not_access {

=head2 library_not_access

foo

=cut

my $self = shift;

my %params = validate(@_, {
    user		=> { type => SCALAR, regex => qr/^\d+$/ },
  });

my ($sql, @bind) = sql_interp('SELECT library FROM library_access WHERE library not in ( SELECT library FROM library_access WHERE', {uid => $params{user}}, ') ');

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

This function returns the libraries that a user has access to and can also be used to modify the list of libraries the user has access to.  Arguments are as a hashref:

=over

=item user

The ID of the user (note, this is not a patron) to retrieve (or modify) library access information

=item libraries

This parameter should be specified only when you want to modify the access list of the user given in the user parameter.  Their library access list will be changed to reflect the libraries specified here.

The library list should be passed in as an arrayref of library IDs.

=back

This function will return an array of libraries that the specified user has access to.

=cut

sub library_access {
	my $self = shift;

	my %params = validate(@_, {
		user		=> { type => SCALAR, regex => qr/^\d+$/ },
		libraries	=> { type => ARRAYREF, optional => 1 },
	});

	my ($sql, @bind) = sql_interp('SELECT library FROM library_access WHERE', { uid => $params{user} });

	my $sth = $self->dbh->prepare($sql);
	$sth->execute(@bind);

	my @results;
	while(my @result = $sth->fetchrow_array) {
		push @results, $result[0];
	}

        # If we don't need to change anything, just return the list now
	unless($params{libraries}) { return @results; }

        # Convert the array into a hash for easy reference
	my %access = map { $_ => 1 } @results;
        # Add libraries that were requested but not already in the list
	foreach my $library (@{$params{libraries}}) {
		unless($access{$library}) {
			my ($sql, @bind) = sql_interp('INSERT INTO library_access', { library => $library, uid => $params{user} });
			$self->dbh->do($sql, undef, @bind);
		} else {
			delete $access{$library};
		}
	}
        # Remove libraries that were not requested but were in the list
	foreach my $library (keys %access) {
		my ($sql, @bind) = sql_interp('DELETE FROM library_access WHERE', { library => $library, uid => $params{user} });
		$self->dbh->do($sql, undef, @bind);
	}

        return @{$params{libraries}};
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

#{{{ end pod
=head1 AUTHOR

Curtis "Fjord" Hawthornre

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
#}}}
# vim600: set foldmethod=marker
