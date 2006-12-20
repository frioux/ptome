package TOME::Interface;

use base 'TOME';

use Crypt::PasswdMD5;
use CGI::Application::Plugin::ValidateRM;
use CGI::Application::Plugin::Forward;

use strict;
use warnings;

sub setup {
	my $self = shift;

	$self->run_modes([ qw( mainsearch updatebook addtomebook addtomebook_isbn addtomebook_process updatetomebook addclass addclass_process tomebookinfo checkout checkin updatecheckoutcomments report fillreservation cancelcheckout classsearch updateclasscomments updateclassinfo deleteclassbook addclassbook findorphans confirm deleteclass finduseless stats login logout management useradd libraryadd sessionsemester semesterset semesteradd removetomebook patronview addpatron addpatron_process patronupdate autocomplete_isbn autocomplete_class autocomplete_patron ) ]);
	$self->run_modes({ AUTOLOAD => 'autoload_rm' }); # Don't actually want to name the sub AUTOLOAD
	$self->start_mode('mainsearch');
}

sub autoload_rm {
	my $self = shift;
	my $attempted_rm = shift;

	return $self->error({
		message		=> "Unrecoverable URL error",
		extended	=> "Attempted runmode: '$attempted_rm'",
	});
}

sub cgiapp_prerun {
	my $self = shift;
	
	unless($self->session->param('~logged-in')) {
		$self->prerun_mode('login');
		return;
	}

	$self->param('user_info', $self->user_info({ id => $self->session->param('id') }));

	if($self->param('user_info')->{disabled}) {
		$self->prerun_mode('login');
		return;
	}
}

sub logout {
	my $self = shift;
	$self->session->delete;

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl");
	return;
}

sub login {
	my $self = shift;
	my $error = '';
	
	if($self->query->param('username')) {
		my $username = $self->query->param('username');
		my $user = $self->user_info({ username => $username });
		if(!$user->{disabled} && (unix_md5_crypt($self->query->param('password'), $user->{password}) eq $user->{password})) {
			$self->session->clear;
			$self->session->param('~logged-in', 1);
			if($user->{admin}) { $self->session->param('admin', 1); }
			$self->session->param('id', $user->{id});
			
			$self->header_type('redirect');
			$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl");
			return;

		} else {
			$error = 'Invalid username or password';
		}
	}

	return $self->template({ file => 'adminlogin.html', vars => { error => $error }, plain => 1 });
}

sub autocomplete_isbn {
	my $self = shift;

	my @books;
	foreach($self->books_search({ isbn => uc $self->query->param('isbn') })) { # We make the ISBN upper case for the user
		my $book_info = $self->book_info({ isbn => $_ });
		my $title = $book_info->{title};
		if(length($title) > 33) {
			$title = substr($title, 0, 30) . '...';
		}
		my $edition = $book_info->{edition};
		if(length($edition) > 13) {
			$edition = substr($edition, 0, 10) . '...';
		}
		push @books, '<li class="auto_complete_item"><div class="primary">' . $_ . '</div><span class="informal"><div class="secondary">' . $title . ': ' . $edition . '</div></span></li>';
	}

	return '<ul class="auto_complete_list">' . join("\n", @books) . '</ul>';
}

sub autocomplete_patron {
	my $self = shift;

	my @patrons;
	foreach my $patron ($self->patrons_search({ email => $self->query->param('patron'), name => $self->query->param('patron') })) {
		if(length($patron->{name}) > 33) {
			$patron->{name} = substr($patron->{name}, 0, 30) . '...';
		}
		if(length($patron->{email}) > 33) {
			$patron->{email} = substr($patron->{email}, 0, 30) . '...';
		}
		push @patrons, '<li class="auto_complete_item"><span class="informal"><div class="primary">' . $patron->{name} . '</div></span><div class="secondary">' . $patron->{email} . '</div></li>';
	}

	return '<ul class="auto_complete_list">' . join("\n", @patrons) . '</ul>';
}

sub autocomplete_class {
	my $self = shift;

	my @classes;
	foreach(@{$self->class_search({ id => $self->query->param('class') })}) {
		my $name = $_->{name};
		if(length($name) > 33) {
			$name = substr($name, 0, 30) . '...';
		}
		push @classes, '<li class="auto_complete_item"><div class="primary">' . $_->{id} . '</div><span class="informal"><div class="secondary">' . $name . '</div></span></li>';
	}

	return '<ul class="auto_complete_list">' . join("\n", @classes) . '</ul>';
}

sub mainsearch {
	my $self = shift;

	my $q = $self->query;
	
	my %search;
	foreach (qw(title author edition status semester)) {
		if($q->param($_)) {
			$search{$_} = $q->param($_);
		}
	}

	$search{isbn} = uc $q->param('isbn') if $q->param('isbn'); # If there's an ISBN, it should be upper case

	$search{libraries} = $self->_librariesselecteddefault();

	my @tomebooks;

	if($q->param('rm')) {
		my @results = $self->tomebooks_search({%search});
		foreach(@results) {
			push @tomebooks, $self->tomebook_info_deprecated({ id => $_ });
		}
	}
	
	my $classes = $self->class_search;
	
	my $libraries = $self->_libraryaccess($self->param('user_info')->{id});
	
	return $self->template({ file => 'mainsearch.html', vars => {
		classes			=> $classes,
		tomebooks		=> \@tomebooks,
		libraries		=> $libraries,
		librarieshash		=> $self->_librarieshash(),
		libraries_selected	=> $search{libraries},
		semester_selected	=> $self->_semesterselecteddefault(),
	}});
}

sub removetomebook {
	my $self = shift;

	my %params;
	foreach(qw(id undo)) {
		if(defined($self->query->param($_))) {
			$params{$_} = $self->query->param($_);
		}
	}

	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info_deprecated({ id => $params{id} })->{library})) {
		$self->tomebook_remove(\%params);
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$params{id}");
	return;
}

sub findorphans {
	my $self = shift;

	my $libraries_selected = $self->_librariesselecteddefault;

	my @books;
	foreach($self->find_orphans({ libraries => $libraries_selected })) {
		push @books, $self->book_info({ isbn => $_ });
	}

	return $self->template({ file => 'findorphans.html', vars => {
		books => \@books,
		libraries		=> $self->_libraryaccess($self->param('user_info')->{id}),
		libraries_selected	=> $libraries_selected,
	}});
}

sub finduseless {
	my $self = shift;

	my $libraries_selected = $self->_librariesselecteddefault;

	my @tomebooks;
	foreach($self->find_useless({ libraries => $libraries_selected })) {
		push @tomebooks, $self->tomebook_info_deprecated({ id => $_ });
		$tomebooks[-1]{classes} = $self->book_classes({ isbn => $tomebooks[-1]{isbn} });
	}

	return $self->template({ file => 'finduseless.html', vars => {
		tomebooks		=> \@tomebooks,
		libraries		=> $self->_libraryaccess($self->param('user_info')->{id}),
		libraries_selected	=> $libraries_selected,
	}});
}

sub stats {
	my $self = shift;

	my $libraries_selected = $self->_librariesselecteddefault;
	
	return $self->template({ file => 'stats.html', vars => {
		libraries		=> $self->_libraryaccess($self->param('user_info')->{id}),
		libraries_selected	=> $libraries_selected,
		stats			=> $self->tome_stats({ libraries => $libraries_selected })
	}});
}

sub confirm {
	my $self = shift;

	return $self->template({ file => 'confirm.html' });
}

sub classsearch {
	my $self = shift;

	my $q = $self->query;

	my $classinfo = $self->class_info_deprecated({ id => $q->param('class') });

	my $libraries = $self->_libraryaccess($self->param('user_info')->{id});
	my (@mylibraries, @otherlibraries);
	foreach(@$libraries) {
		if($_->{access}) {
			push @mylibraries, $_;
		} else {
			push @otherlibraries, $_;
		}
	}
	my @otherlibraryids = map { $_->{id} } @otherlibraries;
		
	foreach my $book (@{$classinfo->{books}}) {
		$book->{info} = $self->book_info({ isbn => $book->{isbn} });
		$book->{mylibraries} = [ @mylibraries ];
		foreach my $library (@{$book->{mylibraries}}) {
			$library = { %$library }; # Ugly, but I have to make a "deep copy" of the hash ref
			$library->{total} = scalar($self->tomebooks_search({ isbn => $book->{isbn}, status => 'in_collection', libraries => [ $library->{id} ] }));
			$library->{available} = scalar($self->tomebooks_search({ isbn => $book->{isbn}, status => 'can_reserve', semester => ($self->session->param('currsemester') ? $self->session->param('currsemester')->{id} : $self->param('currsemester')->{id}), libraries => [ $library->{id} ] }));
		}
		
		$book->{otherlibraries} = {
			ids		=> \@otherlibraryids,
			total		=> scalar($self->tomebooks_search({ isbn => $book->{isbn}, status => 'in_collection', libraries => \@otherlibraryids })),
			available	=> scalar($self->tomebooks_search({ isbn => $book->{isbn}, status => 'can_reserve', semester => ($self->session->param('currsemester') ? $self->session->param('currsemester')->{id} : $self->param('currsemester')->{id}), libraries => \@otherlibraryids })),
		};
	}

	return $self->template({ file => 'classsearch.html', vars => {
		id		=> $q->param('class'),
		name		=> $classinfo->{name},
		comments	=> $classinfo->{comments},
		books		=> $classinfo->{books},
	}});
}

sub updatetomebook {
	my $self = shift;
	
	my $results = $self->check_rm('tomebookinfo', {
		required		=> [qw(
			id
			patron
			library
		)],
		optional		=> [qw(
			comments
			expire
		)],
		filters			=> 'trim',
		msgs			=> {
			any_errors	=> 'updatetomebook_errs',
		},
	}, { target => 'updatetomebook' }) || return $self->check_rm_error_page;

	my $patron_info = $self->patron_info({ email => $results->valid('patron') });
	unless($patron_info) {
		return $self->forward('addpatron');
	}

	my %tomebook = (
		id		=> $results->valid('id'),
		originator	=> $patron_info->{id},
		comments	=> $results->valid('comments') || '',
		expire		=> $results->valid('expire') || 0,
		library		=> $results->valid('library'),
	);
	
	# Verify that they're authorized for the library this book is in and authorized for the library they're trying to move the book to
	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info_deprecated({ id => $tomebook{id} })->{library}) && $self->_libraryauthorized($self->param('user_info')->{id}, $tomebook{library})) {
		$self->tomebook_update({ %tomebook });
	}

	my $id = $results->valid('id');

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$id&edit=1");
	return;
}

sub updateclassinfo {
	my $self = shift;

	my $q = $self->query;

	my $class = $q->param('class');

	$self->classbook_update({ class => $class, usable => ($q->param('usable') ? 'true' : 'false'), verified => $q->param('verified'), comments => $q->param('comments'), isbn => $q->param('isbn'), uid => $self->param('user_info')->{id} });

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=classsearch&class=$class");
	return;
}

sub updateclasscomments {
	my $self = shift;

	my $q = $self->query;

	my $class = $q->param('class');
	$self->class_update_comments({ id => $class, comments => $q->param('comments') });

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=classsearch&class=$class");
	return;
}

sub deleteclassbook {
	my $self = shift;

	my $q = $self->query;

	my $class = $q->param('class');
	$self->class_delete_book({ class => $class, isbn => $q->param('isbn') });

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=classsearch&class=$class");
	return;
}

sub addclassbook {
	my $self = shift;

	my $q = $self->query;
	
	my $isbn = uc $q->param('isbn'); # All ISBNs are uppercase, might as well convert it here
	$isbn =~ s/[- ]//g; # We don't want hyphens or spaces, they're useless
	
	unless($self->book_exists({ isbn => $isbn })) {
		if($q->param('addbook')) {
			my %addbook = (
				isbn	=> $isbn,
				title	=> $q->param('title'),
				author	=> $q->param('author'),
			);
			
			if($q->param('edition')) {
				$addbook{edition} = $q->param('edition');
			}

			$self->add_book({%addbook});
		} else {
			return $self->template({ file => 'addclassbook-isbn.html', vars => {
				librarieshash	=> $self->_librarieshash(),
				classinfo	=> $self->class_info_deprecated({ id => $q->param('class') }),
			}});
		}
	}

	my %book = (
		isbn		=> $isbn,
		usable		=> ($q->param('usable') ? 'true' : 'false'),
		verified	=> $q->param('verified'),
		comments	=> $q->param('comments'),
		class		=> $q->param('class'),
		uid		=> $self->param('user_info')->{id},
	);

	$self->classbook_add({%book});

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=classsearch&class=$book{class}");
	return;
}

sub report {
	my $self = shift;

	my $q = $self->query;

	my $semester_selected = $self->_semesterselecteddefault();
	my $libraries_selected = $self->_librariesselecteddefault();

	my $reservation = $self->reservation_search({ semester => $semester_selected, libraries => $libraries_selected });
	foreach(@$reservation) {
		$_->{tomebookinfo} = $self->tomebook_info_deprecated({ id => $_->{tomebook} });
	}
	my $dueback = $self->dueback_search({ semester => $semester_selected, libraries => $libraries_selected });
	foreach(@$dueback) {
		$_->{tomebookinfo} = $self->tomebook_info_deprecated({ id => $_->{tomebook} });
	}
	my $expiring = $self->expire_search({ semester => $semester_selected, libraries => $libraries_selected });
	foreach(@$expiring) {
		$_->{tomebookinfo} = $self->tomebook_info_deprecated({ id => $_->{tomebook} });
	}

	return $self->template({ file => 'report.html', vars => {
		reservation		=> $reservation,
		dueback			=> $dueback,
		expiring		=> $expiring,
		libraries		=> $self->_libraryaccess($self->param('user_info')->{id}),
		libraries_selected	=> $libraries_selected,
		semester_selected	=> $semester_selected,
	}});
}

sub deleteclass {
	my $self = shift;

	my $q = $self->query;

	$self->class_delete({id => $q->param('id')});

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl");
	return;
}

sub updatebook {
	my $self = shift;

	my $q = $self->query;

	if($q->param('update')) {
		my %book = (
			isbn => $q->param('isbn'),
			title => $q->param('title'),
			author => $q->param('author'),
		);
	
		if($q->param('edition')) {
			$book{edition} = $q->param('edition');
		}

		$self->book_update({%book});
	}

	return $self->template({ file => 'updatebook.html', vars => $self->book_info({ isbn => $q->param('isbn') }) });
}

sub addclass {
	my $self = shift;
	my $errs = shift;


	return $self->template({ file => 'addclass.html', vars => { errs => $errs } });
}

sub addclass_process {
	my $self = shift;

	my $results = $self->check_rm('addclass', {
		required		=> [qw(
			id
			name
		)],
		filters			=> 'trim',
		field_filters		=> {
			id	=> sub {
				my $value = shift;
				$value =~ tr/a-z/A-Z/;
				$value =~ s/[^A-Z0-9]//g;
				return $value;
			},
		},
		constraint_methods	=> {
			id	=> sub {
				my $dfv = shift;
				$dfv->name_this('class_exists');
				return !($self->class_info_deprecated({ id => $dfv->get_current_constraint_value() })->{name});
			},
		},
		msgs			=> {
			constraints	=> {
				'class_exists'	=> 'Class already exists',
			},
		},
	}, { target => 'addclass' }) || return $self->check_rm_error_page;

	my %class = (
		id	=> $results->valid('id'),
		name	=> $results->valid('name'),
	);
	
	$self->add_class({%class});

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=classsearch&class=$class{id}");
	return;
}

sub patronview {
	my $self = shift;
	my $errs = shift;

	my $q = $self->query;

	my $patron;
	if($q->param('patron')) {
		$patron = $self->patron_info({ email => $self->query->param('patron') });
		return $self->error({ message => 'Unable to locate patron with email ' . $self->query->param('patron') }) unless $patron;
	} elsif($q->param('id')) {
		$patron = $self->patron_info({ id => $self->query->param('id') });
		return $self->error({ message => 'Unable to locate patron with ID ' . $self->query->param('id') }) unless $patron;
	}

	return $self->template({ file => 'patronview.html', vars => { patron => $patron->{id}, errs => $errs }});
}

sub patronupdate {
	my $self = shift;

	my $results = $self->check_rm('patronview', {
		required	=> [qw(
			id
			name
			email
		)],
		filters		=> 'trim',
	}, { target => 'patronupdate' }) || return $self->check_rm_error_page;

	my $update = $results->valid;

	$self->patron_update({ id => $update->{id}, email => $update->{email}, name => $update->{name} });

	return $self->forward('patronview');
}	

sub addpatron {
	my $self = shift;
	my $errs = shift;
	
	return $self->template({ file => 'addpatron.html' , vars => { errs => $errs }}); 
}

sub addpatron_process {
	my $self = shift;
	my $results = $self->check_rm('addpatron', {
		required		=> [qw(
			ap_email1
			ap_email2
			ap_name
		)],
		filters			=> 'trim',
		constraint_methods	=> {
			ap_email1	=> sub {
				my $dfv = shift;
				$dfv->name_this('emails_match');
				return ($dfv->get_current_constraint_value() eq $dfv->get_input_data( as_hashref => 1 )->{'ap_email2'});
			},
		},
		msgs			=> {
			constraints	=> {
				'emails_match'	=> 'Emails do not match',
			},
		},
	}, { target => 'addpatron' }) || return $self->check_rm_error_page;

	$self->patron_add({ email => $results->valid('ap_email1'), name => $results->valid('ap_name') });

	return $self->forward($self->query->param('finalrm'));
}

sub addtomebook {
	my $self = shift;
	my $errs = shift;
	
	return $self->template({ file => 'addtomebook.html', vars => {
			libraries	=> $self->_libraryaccess($self->param('user_info')->{id}),
			errs		=> $errs,
	}});
}

sub addtomebook_isbn {
	my $self = shift;
	my $errs = shift;

	return $self->template({ file => 'addtomebook_isbn.html', vars => {
		librarieshash	=> $self->_librarieshash(),
		errs		=> $errs,
	}});
}


sub addtomebook_process {
	my $self = shift;

	my $q = $self->query;

	my $addtomebook_results = $self->check_rm('addtomebook', {
		required	=> [qw(
			isbn
			patron
			library
		)],
		optional	=> [qw(
			comments
			expire
		)],
		filters		=> 'trim',
		field_filters	=> {
			isbn	=> sub { my $value = shift; $value =~ s/[- ]//g; $value = uc $value; return $value; },
		},
	}, { target => 'addtomebook' }) || return $self->check_rm_error_page;

	unless($self->patron_info({ email => $addtomebook_results->valid('patron') })) {
		return $self->forward('addpatron');
	}

	unless($self->book_exists({ isbn => $addtomebook_results->valid('isbn') })) {
		if($q->param('addbook')) {
			my $addtomebook_isbn_results = $self->check_rm('addtomebook_isbn', {
				required	=> [qw(
					title
					author
				)],
				optional	=> [qw(
					edition
				)],
				filters		=> 'trim',
			}, { target => 'addtomebook_isbn' }) || return $self->check_rm_error_page;
			
			my %addbook = (
				isbn	=> $addtomebook_results->valid('isbn'),
				title	=> $addtomebook_isbn_results->valid('title'),
				author	=> $addtomebook_isbn_results->valid('author'),
			);
			
			if($addtomebook_isbn_results->valid('edition')) {
				$addbook{edition} = $addtomebook_isbn_results->valid('edition');
			}

			$self->add_book({%addbook});
		} else {
			return $self->addtomebook_isbn;
		}
	}

	my $patron_info = $self->patron_info({ email => $addtomebook_results->valid('patron') });
	
	my %book = (
		isbn		=> $addtomebook_results->valid('isbn'),
		originator	=> $patron_info->{id},
		library		=> $addtomebook_results->valid('library'),
	);


	foreach(qw(expire comments)) {
		if($addtomebook_results->valid($_)) {
			$book{$_} = $addtomebook_results->valid($_);
		}
	}

	my $id;
	if($self->_libraryauthorized($self->param('user_info')->{id}, $book{library})) {
		$id = $self->add_tomebook(\%book);
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$id");
	return;
}

sub checkout {
	my $self = shift;
	
	my $results = $self->check_rm('tomebookinfo', {
		required	=> [qw(
			id
			library
			semester
			patron
		)],
		optional	=> [qw(
			reservation
			comments
		)],
		filters		=> 'trim',
		msgs		=> {
			any_errors	=> 'checkout_errs',
		},
	}, { target => 'checkout' }) || return $self->check_rm_error_page;

	my $q = $self->query;
	my $id = $results->valid('id');

	my $reservation = $results->valid('reservation') ? 'true' : 'false';
	my $error;
	if($reservation eq 'true') {
		$error = $self->tomebook_can_reserve({tomebook => $id, semester => $results->valid('semester')});
	} else { 
		$error = $self->tomebook_can_checkout({tomebook => $id, semester => $results->valid('semester')});
	}
	return $error if $error;

	my $patron_info = $self->patron_info({ email => $results->valid('patron') });
	unless($patron_info) { return $self->forward('addpatron'); }

	my $checkoutid;
	if($self->_libraryauthorized($self->param('user_info')->{id}, $results->valid('library'))) {
		my $tomebook = $self->tomebook_info_deprecated({id => $id});
		# InterTOME loans may only be on a reservation basis
		unless($self->_libraryauthorized($self->param('user_info')->{id}, $tomebook->{library})) {
			$reservation = 'true';
			# Send out interTOME notices here
			foreach my $uid ($self->library_users({library => $tomebook->{library}})) {
				my $userinfo = $self->user_info({id => $uid});
				if($userinfo->{notifications}) {
					$self->sendmail({
						To	=> $userinfo->{username} . ' <' . $userinfo->{email} . '>',
						Subject	=> 'InterTOME Loan for #' . $tomebook->{id},
						Data	=> $self->template({file => 'interTOMEnotify.email', plain => 1, vars => {
							tomebooklibrary	=> $self->library_info({id => $tomebook->{library}}),
							tomebook	=> $tomebook,
							notifieduser	=> $userinfo,
							borrower	=> "$patron_info->{name} ($patron_info->{email})",
							semester	=> $results->valid('semester'),
							library		=> $self->library_info({id => $results->valid('library')}),
						}}),
					});
				}
			}
		}
		$checkoutid = $self->tomebook_checkout({tomebook => $id, borrower => $patron_info->{id}, semester => $results->valid('semester'), reservation => $reservation, uid => $self->param('user_info')->{id}, library => $results->valid('library') });
	}
	
	if($results->valid('comments')) {
		$self->update_checkout_comments({id => $checkoutid, comments => $results->valid('comments')});
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$id");
	return;
}


sub checkin {
	my $self = shift;

	my $q = $self->query;

	my $id = $q->param('id');
	my $tomebook = $q->param('tomebook');

	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info_deprecated({ id => $tomebook })->{library})) {
		$self->tomebook_checkin({ id => $self->query->param('id') });
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$tomebook");
	return;
}

sub updatecheckoutcomments {
	my $self = shift;

	my $q = $self->query;

	my $id = $q->param('id');
	my $tomebook = $q->param('tomebook');
	
	$self->update_checkout_comments({id => $id, comments => $q->param('comments')});
	
	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$tomebook");
	return;
}

sub fillreservation {
	my $self = shift;

	my $q = $self->query;

	my $id = $q->param('id');
	my $tomebook = $q->param('tomebook');

	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info_deprecated({ id => $tomebook })->{library})) {
		$self->tomebook_fill_reservation({id => $id});
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$tomebook");
	return;
}

sub cancelcheckout {
	my $self = shift;

	my $q = $self->query;

	my $id = $q->param('id');
	my $tomebook = $q->param('tomebook');

	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info_deprecated({ id => $tomebook })->{library})) {
		$self->tomebook_cancel_checkout({id => $id});
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$tomebook");
	return;
}

sub tomebookinfo {
	my $self = shift;
	my $errs = shift;

	my $q = $self->query;

	my $id = $q->param('id');
	my $info;
	
	eval { $info = $self->tomebook_info_deprecated({ id => $id }); };

	if($@ || !$info->{isbn}) {
		return $self->error({ message => 'Unable to find TOME book with ID "' . $id . '"' });
	}

	my $libraries = $self->_libraryaccess($self->param('user_info')->{id});

	return $self->template({ file => 'tomebookinfo.html', vars => {
		tomebook	=> $info,
		checkouts	=> $self->checkout_history({ id => $id }),
		libraries	=> $libraries,
		classes		=> $self->book_classes({ isbn => $info->{isbn} }),
		librarieshash	=> { map { $_->{id} => $_ } @{$libraries} },
		errs		=> $errs,
	}});
}

sub management {
	my $self = shift;

	my $update = 0;
	if($self->query->param('update')) {
		unless(($self->query->param('id') == $self->session->param('id')) or $self->param('user_info')->{admin}) {
			return $self->error({ message => 'You do not have permissions to update that user', extended => $self->session->param('id') . ' tried to update ' . $self->query->param('id') });
		}
		
		my %update = (
			id		=> $self->query->param('id'),
			username	=> $self->query->param('username'),
			email		=> $self->query->param('email'),
			notifications	=> $self->query->param('notifications') ? 'true' : 'false',
		);
		
		if($self->param('user_info')->{admin}) {
			$update{admin} = $self->query->param('admin') ? 'true' : 'false',
			$update{disabled} = $self->query->param('disabled') ? 'true' : 'false',
			my @libraries = $self->query->param('libraries');
			$self->library_access({ user => $self->query->param('id'), libraries => \@libraries });
		}
		
		if($self->query->param('password1')) {
			if($self->query->param('password1') ne $self->query->param('password2')) {
				return $self->error({ message => 'The two passwords do not match' });
			} else {
				$update{password} = unix_md5_crypt($self->query->param('password1'));
			}
		}
	
		$self->user_update({ %update });
		$self->param('user_info', $self->user_info({ id => $self->session->param('id') }));
		$update = 1;
	}
	
	my $users;
	if($self->param('user_info')->{admin}) {
		$users = $self->user_info;
	} else {
		$users = [ $self->param('user_info') ];
	}

	foreach my $userinfo (@$users) {
		$userinfo->{libraries} = $self->_libraryaccess($userinfo->{id});
	}

	return $self->template({ file => 'management.html', vars => { admin => $self->param('user_info')->{admin}, users => $users, update => $update }});
}

sub useradd {
	my $self = shift;

	if($self->user_info({ id => $self->session->param('id') })->{admin}) {
		$self->user_add({
			username	=> $self->query->param('username'),
			email		=> $self->query->param('email'),
		});
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=management");
	return;
}

sub libraryadd {
	my $self = shift;

	if($self->user_info({ id => $self->session->param('id') })->{admin}) {
		$self->library_add({
			name	=> $self->query->param('name'),
		});
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=management");
	return;
}

sub semesteradd {
	my $self = shift;

	if($self->user_info({ id => $self->session->param('id') })->{admin}) {
		$self->semester_add({
			name	=> $self->query->param('name'),
		});
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=management");
	return;
}

sub semesterset {
	my $self = shift;

	if($self->user_info({ id => $self->session->param('id') })->{admin}) {
		$self->semester_set({
			id	=> $self->query->param('semester'),
		});
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=management");
	return;
}

sub sessionsemester {
	my $self = shift;

	my $sessionsemester = (grep { $_->{id} == $self->query->param('semester') } @{$self->param('semesters')})[0];
	unless ($sessionsemester->{id}) {
		return $self->error({ message => 'Invalid semester chosen', extended => 'Tried to select semester ' . $self->query->param('semester') });
	} else {
		if($sessionsemester->{id} == $self->param('currsemester')->{id}) {
			$self->session->clear('currsemester');
		} else {
			$self->session->param('currsemester', $sessionsemester);
		}
	}
	
	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=management");
	return;
}

sub _libraryaccess {
	my $self = shift;
	my $uid = shift;
	
	my %library_access = map { $_->{id} => 1 } @{$self->library_access({ user => $uid })};
	my $libraries = $self->library_info;
	foreach my $library (@{$libraries}) {
		$library->{access} = $library_access{$library->{id}} ? 1 : 0;
	}

	return $libraries;
}

sub _libraryauthorized {
	my $self = shift;
	my ($uid, $library) = @_;

	return scalar(grep { $_->{id} == $library } @{$self->library_access({user => $uid})}) == 1;
}

sub _librarieshash {
	my $self = shift;

	return { map { $_->{id} => $_ } @{$self->library_info} };
}

sub _librariesselecteddefault {
	my $self = shift;

	my @libraries_selected = $self->query->param('libraries');
	unless(@libraries_selected) {
		foreach (@{$self->_libraryaccess($self->param('user_info')->{id})}) {
			if($_->{access}) {
				push @libraries_selected, $_->{id};
			}
		}
	}
	return \@libraries_selected;
}

sub _semesterselecteddefault {
	my $self = shift;

	my $semester_selected = $self->query->param('semester');
	unless($semester_selected) {
		$semester_selected = ($self->session->param('currsemester') || $self->param('currsemester'))->{id};
	}
	return $semester_selected;
}

1;
