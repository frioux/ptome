package Interface;

use lib '.';

use base 'TOME';

use Crypt::PasswdMD5;
use MIME::Lite;
use CGI::Application::Plugin::ValidateRM;

use strict;
use warnings;

sub setup {
	my $self = shift;

	$self->run_modes([ qw( mainsearch updatebook addtomebook addtomebook_isbn addtomebook_process updatetomebook addclass addclass_process tomebookinfo checkout checkin updatecheckoutcomments report fillreservation cancelcheckout classsearch updateclasscomments updateclassinfo deleteclassbook addclassbook findorphans confirm deleteclass finduseless stats login logout management useradd libraryadd sessionsemester semesterset semesteradd removetomebook autocomplete_isbn autocomplete_class ) ]);
	$self->start_mode('mainsearch');
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
	foreach($self->books_search({ isbn => $self->query->param('isbn') })) {
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
	foreach (qw(isbn title author edition status semester)) {
		if($q->param($_)) {
			$search{$_} = $q->param($_);
		}
	}

	$search{libraries} = $self->_librariesselecteddefault();

	my @tomebooks;

	if($q->param('rm')) {
		my @results = $self->tomebooks_search({%search});
		foreach(@results) {
			push @tomebooks, $self->tomebook_info({ id => $_ });
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

	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info({ id => $params{id} })->{library})) {
		$self->tomebook_remove(\%params);
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$params{id}");
	return;
}

sub findorphans {
	my $self = shift;

	my @books;
	foreach($self->find_orphans()) {
		push @books, $self->book_info({ isbn => $_ });
	}

	return $self->template({ file => 'findorphans.html', vars => {
		books => \@books,
	}});
}

sub finduseless {
	my $self = shift;

	my $libraries_selected = $self->_librariesselecteddefault;

	my @tomebooks;
	foreach($self->find_useless({ libraries => $libraries_selected })) {
		push @tomebooks, $self->tomebook_info({ id => $_ });
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

	my $classinfo = $self->class_info({ id => $q->param('class') });

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

	my $q = $self->query;

	my $id = $q->param('id');

	my %tomebook = (
		id		=> $id,
		originator	=> $q->param('originator'),
		comments	=> $q->param('comments'),
		expire		=> $q->param('expire'),
		library		=> $q->param('library'),
	);
	
	# Verify that they're authorized for the library this book is in and authorized for the library they're trying to move the book to
	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info({ id => $tomebook{id} })->{library}) && $self->_libraryauthorized($self->param('user_info')->{id}, $tomebook{library})) {
		$self->tomebook_update({ %tomebook });
	}

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
	
	my $isbn = $q->param('isbn');
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
				classinfo	=> $self->class_info({ id => $q->param('class') }),
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
		$_->{tomebookinfo} = $self->tomebook_info({ id => $_->{tomebook} });
	}
my $dueback = $self->dueback_search({ semester => $semester_selected, libraries => $libraries_selected });
	foreach(@$dueback) {
		$_->{tomebookinfo} = $self->tomebook_info({ id => $_->{tomebook} });
	}
	my $expiring = $self->expire_search({ semester => $semester_selected, libraries => $libraries_selected });
	foreach(@$expiring) {
		$_->{tomebookinfo} = $self->tomebook_info({ id => $_->{tomebook} });
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
			id	=> 'uc',
			id	=> sub {
				my $value = shift;
				$value =~ s/[^A-Z0-9]//g;
				return $value;
			},
		},
		constraint_methods	=> {
			id	=> sub {
				my $dfv = shift;
				$dfv->name_this('class_exists');
				return !($self->class_info({ id => $dfv->get_current_constraint_value() })->{name});
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
			originator
			library
		)],
		filters		=> 'trim',
		field_filters	=> {
			isbn	=> 'uc',
			isbn	=> sub { my $value = shift; $value =~ s/[- ]//g; return $value; },
		},
	}) || return $self->check_rm_error_page;

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
			}) || return $self->check_rm_error_page;
			
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

	my %book = (
		isbn		=> $addtomebook_results->valid('isbn'),
		originator	=> $addtomebook_results->valid('originator'),
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

	my $q = $self->query;
	my $id = $q->param('tomebook');

	my $reservation = $q->param('reservation') ? 'true' : 'false';
	my $error;
	if($reservation eq 'true') {
		$error = $self->tomebook_can_reserve({tomebook => $q->param('tomebook'), semester => $q->param('semester')});
	} else { 
		$error = $self->tomebook_can_checkout({tomebook => $q->param('tomebook'), semester => $q->param('semester')});
	}
	return $error if $error;

	my $checkoutid;
	if($self->_libraryauthorized($self->param('user_info')->{id}, $q->param('library'))) {
		my $tomebook = $self->tomebook_info({id => $q->param('tomebook')});
		# InterTOME loans may only be on a reservation basis
		unless($self->_libraryauthorized($self->param('user_info')->{id}, $tomebook->{library})) {
			$reservation = 'true';
			# Send out interTOME notices here
			foreach my $uid ($self->library_users({library => $tomebook->{library}})) {
				my $userinfo = $self->user_info({id => $uid});
				if($userinfo->{notifications}) {
					my $message = MIME::Lite->new(
						From	=> $TOME::CONFIG{notifyfrom},
						To	=> $userinfo->{username} . ' <' . $userinfo->{email} . '>',
						Subject	=> 'InterTOME Loan for #' . $tomebook->{id},
						Data	=> $self->template({file => 'interTOMEnotify.email', plain => 1, vars => {
							tomebooklibrary	=> $self->library_info({id => $tomebook->{library}}),
							tomebook	=> $tomebook,
							notifieduser	=> $userinfo,
							borrower	=> $q->param('borrower'),
							semester	=> $q->param('semester'),
							library		=> $self->library_info({id => $q->param('library')}),
						}}),
					);
					$message->send;
				}
			}
		}
		$checkoutid = $self->tomebook_checkout({tomebook => $q->param('tomebook'), borrower => $q->param('borrower'), semester => $q->param('semester'), reservation => $reservation, uid => $self->param('user_info')->{id}, library => $q->param('library') });
	}
	
	if($q->param('comments')) {
		$self->update_checkout_comments({id => $checkoutid, comments => $q->param('comments')});
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

	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info({ id => $tomebook })->{library})) {
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

	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info({ id => $tomebook })->{library})) {
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

	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info({ id => $tomebook })->{library})) {
		$self->tomebook_cancel_checkout({id => $id});
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$tomebook");
	return;
}

sub tomebookinfo {
	my $self = shift;

	my $q = $self->query;

	my $id = $q->param('id');
	my $info;
	
	eval { $info = $self->tomebook_info({ id => $id }); };

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
