package TOME::Interface;

use base 'TOME';

use Crypt::PasswdMD5;
use CGI::Application::Plugin::ValidateRM;
use CGI::Application::Plugin::Forward;

use strict;
use warnings;

#{{{setup
sub setup {
	my $self = shift;

	$self->run_modes([ qw(first_login inventory mainsearch updatebook addtomebook addtomebook_isbn addtomebook_process updatetomebook addclass addclass_process tomebookinfo checkout checkin updatecheckoutcomments report fillreservation cancelcheckout classsearch updateclasscomments updateclassinfo deleteclassbook addclassbook findorphans confirm deleteclass finduseless stats login logout management useradd libraryadd sessionsemester semesterset semesteradd removetomebook patronview addpatron_ajax addpatron_process patronupdate autocomplete_isbn autocomplete_class autocomplete_patron patronaddclass isbnview libraryupdate ajax_updateclassinfo ajax_isbnreserve ajax_libraries_selection_list ajax_fill_reservation ajax_checkin ajax_books_donated_list tomekeepers classes) ]);
	$self->run_modes({ AUTOLOAD => 'autoload_rm' }); # Don't actually want to name the sub AUTOLOAD
	$self->start_mode('mainsearch');
}
#}}}

#{{{autoload_rm
sub autoload_rm {
	my $self = shift;
	my $attempted_rm = shift;

	return $self->error({
		message		=> "Unrecoverable URL error",
		extended	=> "Attempted runmode: '$attempted_rm'",
	});
}
#}}}

#{{{cgiapp_prerun
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

	unless($self->param('user_info')->{has_logged_in}) {
		$self->prerun_mode('first_login');
		return;
	}
}
#}}}

#{{{logout
sub logout {
	my $self = shift;
	$self->session->delete;

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl");
	return;
}
#}}}

#{{{login
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
#}}}

#{{{first_login
sub first_login {
	my $self = shift;
	my $error = '';
        my $q = $self->query;
        my $email = '';
        my $firstname;

        if($q->param('email') =~ m/^([A-z0-9_\-]+)\@letu\.edu$/) {
            $email = $1;
        } elsif ($q->param('email') =~ m/^([A-z0-9_\-]+)\@.*$/) {
            $email = '';
        } else {
          $email = $q->param('email');
        }

        if(($q->param('first_name') eq 'firstname') || $q->param('last_name') eq 'lastname') {
          $firstname = '';
        } else {
          $firstname = $q->param('first_name');
        }



        if($firstname && $q->param('last_name') && $email && $q->param('password1') && ($q->param('password1') eq $q->param('password2'))) {
          $self->user_update({
              id => $self->session->param('id'),
              email => "$email\@letu.edu",
              first_name => $firstname,
              last_name => $q->param('last_name'),
              has_logged_in => 'true',
              second_contact => $q->param('contact'),
              password => unix_md5_crypt($q->param('password1')),
            });

          $self->header_type('redirect');
          $self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl");
          return ;
        }

	return $self->template({ file => 'firstlogin.html', vars => { error => $error, id => $self->session->param('id') }});
}
#}}}

#{{{autocomplete_isbn
sub autocomplete_isbn {
	my $self = shift;

	my @books;
	foreach($self->books_search({ isbn => uc $self->query->param('isbn'), title => $self->query->param('isbn'), author => $self->query->param('isbn'), })) { # We make the ISBN upper case for the user
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
#}}}

#{{{autocomplete_patron
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
#}}}

#{{{autocomplete_class
sub autocomplete_class {
	my $self = shift;

	my @classes;
	foreach($self->class_search({ id => $self->query->param('class'), name => $self->query->param('class') })) {
		my $name = $self->class_info({ id => $_ })->{name};
		if(length($name) > 33) {
			$name = substr($name, 0, 30) . '...';
		}
		push @classes, '<li class="auto_complete_item"><div class="primary">' . $_ . '</div><span class="informal"><div class="secondary">' . $name . '</div></span></li>';
	}

	return '<ul class="auto_complete_list">' . join("\n", @classes) . '</ul>';
}
#}}}

#{{{classes
sub classes {

=head2 classes



=cut

my $self = shift;
my $classes = $self->class_list();

return $self->template(
  file => 'classes.html',
  vars => {
    classes => $classes,
  }
);

}
#}}}

#{{{management
sub management {

=head2 management

new admin page

=cut
my $self = shift;

	my $update = 0;
	if($self->query->param('update')) {
		unless(($self->query->param('id') == $self->session->param('id')) or $self->param('user_info')->{admin}) {
			return $self->error({ message => 'You do not have permissions to update that user',
                            extended => $self->session->param('id') . ' tried to update ' . $self->query->param('id') });
		}

		my %update = (
			id		=> $self->query->param('id'),
                        first_name      => $self->query->param('first_name'),
                        last_name       => $self->query->param('last_name'),
			username	=> $self->query->param('username'),
			email		=> $self->query->param('email'),
			notifications	=> $self->query->param('notifications') ? 'true' : 'false',
                        second_contact  => $self->query->param('second_contact'),

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
                # removed line, might need to add back
		$update = 1;
              }
	my $users;
	if($self->param('user_info')->{admin}) {
		$users = $self->user_info;
	} else {
		$users = [ $self->param('user_info') ];
	}

	foreach my $userinfo (@$users) {
		$userinfo->{libraries} = $self->library_info();
		my $library_access = $self->_libraryaccesshash($userinfo->{id});
		foreach(@{$userinfo->{libraries}}) {
			$_->{access} = $library_access->{$_->{id}} ? 1 : 0;
		}
	}


return $self->template({
  file => "management.html",
  vars => {admin => $self->param('user_info')->{admin}, users => $users, update => $update}});
}
#}}}

#{{{ mainsearch
sub mainsearch {
    my $self = shift;
    my $errs = shift;

    my $results = $self->check_rm('mainsearch',
        {
            optional => [qw(author title edition)],
            filters => ['trim'],
        },
        {target => 'mainsearch'}
    ) || return $self->check_rm_error_page;

    my %search;
    foreach ($results->valid()) {
        $search{$_} = $results->valid($_);
    }

    my @books = $self->isbn_search (\%search);

    return $self->template(
        file => 'mainsearch.html',
        vars => {
		books	=> \@books,
		errs	=> $errs,
	}
    );
}
#}}}

#{{{tomekeepers
sub tomekeepers {

  my $self = shift;
  my $users = $self->user_info;

  foreach my $userinfo (@$users) {
    $userinfo->{libraries} = $self->library_info();
    my $library_access = $self->_libraryaccesshash($userinfo->{id});
    foreach(@{$userinfo->{libraries}}) {
      $_->{access} = $library_access->{$_->{id}} ? 1 : 0;
    }
  }

  return $self->template(
    {
      file => 'tomekeepers.html', vars => {
        users => $users
      }
    }
  );
}
#}}}

#{{{removetomebook
sub removetomebook {
	my $self = shift;

	my %params;
	foreach(qw(id undo)) {
		if(defined($self->query->param($_))) {
			$params{$_} = $self->query->param($_);
		}
	}

        my $q = $self->query;

        my $patron_info = $self->patron_info({ email => $q->param('patron') });
	unless($patron_info) {
		return $self->forward('addpatron');
	}

	my %tomebook = (
		id		=> $q->param('id'),
		originator	=> $patron_info->{id},
		comments	=> $q->param('comments') || '',
		expire		=> $q->param('expire') || 0,
		library		=> $q->param('library'),
	);

	if($self->_libraryauthorized($self->param('user_info')->{id}, $self->tomebook_info_deprecated({ id => $params{id} })->{library})) {
		$self->tomebook_update({ %tomebook });
		$self->tomebook_remove(\%params);
	}



	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$params{id}");
	return;
}
#}}}

#{{{findorphans
sub findorphans {
	my $self = shift;

	my $libraries_selected = $self->_librariesselecteddefault;

	my @books = $self->find_orphans({ libraries => $libraries_selected });

	return $self->template({ file => 'findorphans.html', vars => {
		books => \@books,
		libraries		=> keys(%{$self->_libraryaccesshash($self->param('user_info')->{id})}),
		libraries_selected	=> $libraries_selected,
	}});
}
#}}}

#{{{finduseless
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
		libraries		=> keys(%{$self->_libraryaccesshash($self->param('user_info')->{id})}),
		libraries_selected	=> $libraries_selected,
	}});
}
#}}}

#{{{stats
sub stats {
	my $self = shift;

	my $libraries_selected = $self->_librariesselecteddefault;
        my $stats =$self->tome_stats({ libraries => $libraries_selected }) ;
        warn join(', ', keys(%{$stats}));

	return $self->template({ file => 'stats.html', vars => {
                test                    => 'frew',
		libraries_selected	=> $libraries_selected,
		stats			=> $stats
	}});
}
#}}}

#{{{confirm
sub confirm {
	my $self = shift;

	return $self->template({ file => 'confirm.html' });
}
#}}}

#{{{classsearch
sub classsearch {
	my $self = shift;

	my $q = $self->query;

	my $class = uc $q->param('class'); # Make sure that it got uppercased

	my $classinfo = $self->class_info({ id => $class });

	# Check to make sure we actually got something back
	unless($classinfo) {
		return $self->template({ file => 'classunknown.html',
			vars	=> {
				id	=> $class,
			},
		});
	}

	$classinfo = $self->class_info_deprecated({ id => $q->param('class') });

	my $libraries = $self->library_info;

        my %mylibraries = %{$self->_libraryaccesshash($self->param('user_info')->{id})};
	my @otherlibraries;
	foreach(@$libraries) {
		if(!$mylibraries{$_->{id}}) {
			push @otherlibraries, $_;
		}
	}
        my @mylibraries = keys(%mylibraries);
	my @otherlibraryids = map { $_->{id} } @otherlibraries;

	foreach my $book (@{$classinfo->{books}}) {
		$book->{info} = $self->book_info({ isbn => $book->{isbn} });
		$book->{mylibraries} = [ @mylibraries ];
		foreach my $library (@{$book->{mylibraries}}) {
			my $library = $self->library_info({id => $library});
			$library->{total} = $self->tomebook_availability_search_amount({ isbn => $book->{isbn}, status => 'in_collection', libraries => [ $library->{id} ] });
			$library->{available} = $self->tomebook_availability_search_amount({ isbn => $book->{isbn}, status => 'can_reserve', semester => ($self->session->param('currsemester') ? $self->session->param('currsemester')->{id} : $self->param('currsemester')->{id}), libraries => [ $library->{id} ] });
		}

		$book->{otherlibraries} = {
			ids		=> \@otherlibraryids,
			total		=> $self->tomebook_availability_search_amount({ isbn => $book->{isbn}, status => 'in_collection', libraries => \@otherlibraryids }),
			available	=> $self->tomebook_availability_search_amount({ isbn => $book->{isbn}, status => 'can_reserve', semester => ($self->session->param('currsemester') ? $self->session->param('currsemester')->{id} : $self->param('currsemester')->{id}), libraries => \@otherlibraryids }),
		};
	}
my $semester;
    if ($q->param('semester')) {
        $semester = $q->param('semester');
    } elsif ($self->session->param('currsemester')) {
        $semester = $self->session->param('currsemester')->{id};
    } else {
        $semester = $self->param('currsemester')->{id};
    }

    # from_libraries refers to libraries that the
    # reservation is coming from, not the book.
    my $library_access = $self->_libraryaccesshash($self->param('user_info')->{id});
    my @from_libraries = keys %{$library_access};

	return $self->template({ file => 'classsearch.html', vars => {
		id		=> $q->param('class'),
		name		=> $classinfo->{name},
		comments	=> $classinfo->{comments},
		books		=> $classinfo->{books},
                semester        => $semester,
                libraries_from  => \@from_libraries,
	}});
}
#}}}

#{{{updatetomebook
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
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=tomebookinfo&id=$id");
	return;
}
#}}}

#{{{patronaddclass
sub patronaddclass {
    my $self = shift;

    my $results = $self->check_rm('patronview', {
        required                => ['class', 'patronid'],
	filters			=> ['trim'],
        constraint_methods      => {
            class => sub {
                my $dfv = shift;
                $dfv->name_this('bad_class');
                return $self->class_info({ id => $dfv->get_current_constraint_value() });
		  },
	  },
    msgs => {
                constraints => {
                    'bad_class'    => 'Class does not exist',
                },
            },
    }, { target => 'patronaddclass' }) || return $self->check_rm_error_page;

   $self->patron_add_class({
     patron     => $results->valid('patronid'),
     class      => $results->valid('class'),
    });

    return $self->forward('patronview');
}
#}}}

#{{{updateclassinfo
sub updateclassinfo {
	my $self = shift;

	my $q = $self->query;

	my $class = $q->param('class');

	$self->classbook_update({ class => $class, usable => ($q->param('usable') ? 'true' : 'false'), verified => $q->param('verified'), comments => $q->param('comments'), isbn => $q->param('isbn'), uid => $self->param('user_info')->{id} });

	return $self->template({ file => 'classsearch_blocks/usableinfo.html',
            vars => {
              b => $q->param('isbn')
            }, plain => 1,
          });
}
#}}}

#{{{ajax_updateclassinfo
sub ajax_updateclassinfo {
  my $self = shift;
  my $q = $self->query;
  my $commit = $q->param('ucommit');
  if($commit eq 'update') {

    $self->classbook_update({ class => $q->param('class'), usable => ($q->param('usable') ? 'true' : 'false'), verified => $q->param('verified'), comments => $q->param('comments'), isbn => $q->param('isbn'), uid => $self->param('user_info')->{id} });

  return $self->template({ file => 'classsearch_blocks/usableinfo.html',
            vars => {
              book => $q->param('isbn'),
              class => $q->param('class'),
            }, plain => 1,
          });
  } elsif ($commit eq 'delete') {
	$self->class_delete_book({ class => $q->param('class'), isbn => $q->param('isbn') });
        return "Book association removed";
  }



}
#}}}

#{{{updateclasscomments
sub updateclasscomments {
	my $self = shift;

	my $q = $self->query;

	my $class = $q->param('class');
	$self->class_update_comments({ id => $class, comments => $q->param('comments') });

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=classsearch&class=$class");
	return;
}
#}}}

#{{{deleteclassbook
sub deleteclassbook {
	my $self = shift;

	my $q = $self->query;

	my $class = $q->param('class');
	$self->class_delete_book({ class => $class, isbn => $q->param('isbn') });

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=classsearch&class=$class");
	return;
}
#}}}

#{{{addclassbook
sub addclassbook {
	my $self = shift;

	my $q = $self->query;

	my $isbn = uc $q->param('isbn'); # All ISBNs are uppercase, might as well convert it here
	$isbn =~ s/[- ]//g; # We don't want hyphens or spaces, they're useless

        my %libraries_hash = map { $_->{id} => $_ } @{$self->library_info};

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
				librarieshash	=> %libraries_hash,
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
#}}}

#{{{report
sub report {
    my $self = shift;

    my $q = $self->query;

    return $self->template({ file => 'report.html', vars => {
        local_reservations       =>  $self->reservation_search({
                semester            => $self->_semesterselecteddefault(),
                library_to          => $self->_librariesselecteddefault(),
                library_from        => $self->_librariesselecteddefault(),
            }) ,
        local_dueback            => [ $self->checkout_search({
                semester            => $self->_semesterselecteddefault(),
                library_to          => $self->_librariesselecteddefault(),
                library_from        => $self->_librariesselecteddefault(),
                status              => 'checked_out',
            }) ],
        local_expiring      =>       $self->expire_search({
            semester                =>$self->_semesterselecteddefault(),
            libraries               => $self->_librariesselecteddefault(),
          }) ,
        reserved_from_remote_to_local =>  $self->reservation_search({
            semester => $self->_semesterselecteddefault(),
            library_from  => $self->_librariesnotselecteddefault(),
            library_to  => $self->_librariesselecteddefault(),
          }) ,
        reserved_from_local_to_remote =>  $self->reservation_search({
            semester => $self->_semesterselecteddefault(),
            library_from  => $self->_librariesselecteddefault(),
            library_to  => $self->_librariesnotselecteddefault(),
          }) ,
        dueback_from_local_to_remote  => [ $self->checkout_search({
                semester            => $self->_semesterselecteddefault(),
                library_to          => $self->_librariesnotselecteddefault(),
                library_from        => $self->_librariesselecteddefault(),
                status              => 'checked_out',
            }) ],
        dueback_from_remote_to_local => [ $self->checkout_search({
                semester            => $self->_semesterselecteddefault(),
                library_to          => $self->_librariesselecteddefault(),
                library_from        => $self->_librariesnotselecteddefault(),
                status              => 'checked_out',
            }) ],
        libraries_selected  => $self->_librariesselecteddefault(),
        libraries_not_selected  => $self->_librariesnotselecteddefault(),
        semester_selected   => $self->_semesterselecteddefault(),
    }});
}
#}}}

#{{{deleteclass
sub deleteclass {
	my $self = shift;

	my $q = $self->query;

	$self->class_delete({id => $q->param('id')});

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl");
	return;
}
#}}}

#{{{updatebook
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
#}}}

#{{{addclass
sub addclass {
	my $self = shift;
	my $errs = shift;


	return $self->template({ file => 'addclass.html', vars => { errs => $errs } });
}
#}}}

#{{{addclass_process
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
#}}}

#{{{patronview
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
#}}}

#{{{patronupdate
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
#}}}

#{{{addpatron_ajax
sub addpatron_ajax {
	my $self = shift;
	my $errs = shift;

	return $self->template({ file => 'blocks/addpatron.html' , vars => { errs => $errs }, plain => 1});
}
#}}}

#{{{addpatron_process
sub addpatron_process {
	my $self = shift;
	my $results = $self->check_rm('addpatron_ajax', {
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
	}, { target => 'addpatron_ajax' }) || return $self->check_rm_error_page;

	$self->patron_add({ email => $results->valid('ap_email1'), name => $results->valid('ap_name') });

	return $self->forward($self->query->param('finalrm'));
}
#}}}

#{{{addtomebook
sub addtomebook {
	my $self = shift;
	my $errs = shift;

	return $self->template({ file => 'addtomebook.html', vars => { errs => $errs }});
}
#}}}

#{{{addtomebook_isbn
sub addtomebook_isbn {
	my $self = shift;
	my $errs = shift;

        my %libraries_hash = map { $_->{id} => $_ } @{$self->library_info};

	return $self->template({ file => 'addtomebook_isbn.html', vars => {
		librarieshash	=> %libraries_hash,
		errs		=> $errs,
	}});
}
#}}}

#{{{addtomebook_process
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
		return $self->forward('addpatron_ajax');
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
#}}}

#{{{checkout
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
	unless($patron_info) { return $self->forward('addpatron_ajax'); }

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
#}}}

#{{{checkin
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
#}}}

#{{{updatecheckoutcomments
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
#}}}

#{{{fillreservation
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
#}}}

#{{{cancelcheckout
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
#}}}

#{{{tomebookinfo
sub tomebookinfo {
	my $self = shift;
	my $errs = shift;

	my $q = $self->query;

	my $id = $q->param('id');
	my $info;

	$info = $self->tomebook_info({ tomebook => $id });

	if($@ || !$info->{isbn}) {
		return $self->error({ message => 'Unable to find TOME book with ID "' . $id . '"' });
	}

	my @libraries = keys(%{$self->_libraryaccesshash($self->param('user_info')->{id})});

	return $self->template({ file => 'tomebookinfo.html', vars => {
		tomebook	=> $info,
		checkouts	=> $self->checkout_history({ id => $id }),
		libraries	=> \@libraries,
		classes		=> $self->book_classes({ isbn => $info->{isbn} }),
		librarieshash	=> $self->_libraryaccesshash($self->param('user_info')->{id}),
		errs		=> $errs,
	}});
}
#}}}

#{{{inventory
sub inventory {
  my $self = shift;


  return $self->template({
      file => 'inventory.html',
      vars => {
        books => $self->inventory_search({ libraries => $self->_librariesselecteddefault}),
      }
      });
}
#}}}

#{{{libraryupdate
sub libraryupdate {
	my $self = shift;

	if($self->user_info({ id => $self->session->param('id') })->{admin}) {
		$self->library_update({
			id		=> $self->query->param('id'),
			name		=> $self->query->param('name'),
			intertome	=> $self->query->param('intertome') ? 'true' : 'false',
		});
	}

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=management");
	return;
}
#}}}

#{{{useradd
sub useradd {
	my $self = shift;

        if($self->query->param('password1') ne $self->query->param('password2')) {
          return $self->error({ message => 'Passwords do not match', extended => 'Try again'});
        }
	if($self->user_info({ id => $self->session->param('id') })->{admin}) {
		$self->user_add({
			username	=> $self->query->param('username'),
			email		=> $self->query->param('email'),
                        first_name      => $self->query->param('first_name'),
                        last_name       => $self->query->param('last_name'),
                        password        => unix_md5_crypt($self->query->param('password1')),
		});
            }

	$self->header_type('redirect');
	$self->header_props(-url => "$TOME::CONFIG{cgibase}/admin.pl?rm=management");
	return;
}
#}}}

#{{{libraryadd
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
#}}}

#{{{semesteradd
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
#}}}

#{{{semesterset
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
#}}}

#{{{sessionsemester
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
#}}}

#{{{isbnview
sub isbnview {
    my $self = shift;
    my $errs = shift;

    my $q = $self->query;


    my $semester;
    if ($q->param('semester')) {
        $semester = $q->param('semester');
    } elsif ($self->session->param('currsemester')) {
        $semester = $self->session->param('currsemester')->{id};
    } else {
        $semester = $self->param('currsemester')->{id};
    }

    # from_libraries refers to libraries that the
    # reservation is coming from, not the book.
    my $library_access = $self->_libraryaccesshash($self->param('user_info')->{id});
    my @from_libraries = keys %{$library_access};
    my $isbn = $q->param('isbn');

    return $self->template({file => 'isbnview.html',
        vars => {
            isbn => $isbn,
            libraries_from => \@from_libraries,
            libraries_to => $self->isbnview_to_libraries($semester, $from_libraries[0], $isbn),
            semester => $semester,
            errs        => $errs,
        }
    });

}
#}}}

#{{{ajax_isbnreserve
sub ajax_isbnreserve {
    my $self = shift;

    my $q = $self->query();


    my $results = $self->check_rm('isbnview', {
            required		=> [qw(
                    isbn
                    patron
                    library_to
                    library_from
                    semester
            )],
            optional		=> [qw(
                    comment
            )],
            filters			=> 'trim',
    }, { target => 'ajax_isbnreserve' }) || return $self->check_rm_error_page;

    my $patron_info = $self->patron_info({ email => $results->valid('patron') });
    unless($patron_info) {
            return $self->forward('addpatron_ajax');
    }

    my $id = $self->reservation_create({
        isbn => $q->param('isbn'),
        uid  => $self->param('user_info')->{id},
        patron => $self->patron_info({
            email => $q->param('patron')})->{id},
        comment => $q->param('comment')?$q->param('comment'):"",
        library_from => $q->param('library_from'),
        library_to => $q->param('library_to'),
        semester => $q->param('semester'),
    });

    return "Book has been reserved!";
}
#}}}

#{{{_libraryaccesshash
sub _libraryaccesshash {
    my $self = shift;
    my $uid = shift;

    return { map {$_ => 1} ($self->library_access({ user => $uid })) };
}
#}}}

#{{{ajax_libaries_selection_list

sub ajax_libraries_selection_list {
    my $self = shift;

    return $self->template({file => 'blocks/libraries_selection.html',
        vars => {
            semester => $self->query->param('semester'),
            library_from => $self->query->param('library_from'),
            isbn => $self->query->param('isbn'),
        }, plain => 1,
    });
}

#}}}

#{{{ajax_books_donated_list

sub ajax_books_donated_list {
    my $self = shift;

    my $patronid = $self->query->param('patronid');

    return $self->template({file => 'blocks/books_donated.html',
        vars => {
            ids => $self->donated_search({patron_id => $patronid}),
        }, plain => 1,
    });

}

#}}}

#{{{ ajax_fill_reservation
sub ajax_fill_reservation {
  my $self = shift;
  if ($self->query->param('commit') eq 'fill') {
    my $checkout = $self->reservation_fulfill({reservation_id => $self->query->param('reservation_id'), tomebook_id => $self->query->param('tomebook_id')});
    if ($checkout != -1) {
      return "Checked out!";
    } else {
      return "You can't make that checkout because it is not your book.";
    }
  } elsif ($self->query->param('commit') eq 'cancel') {
    my $cancel = $self->reservation_cancel({id => $self->query->param('reservation_id')});
    if ($cancel) {
      return "Reservation Cancelled!";
    } else {
      return "Could not cancel reservation because it is not your reservation or your floor.";
    }
  }
}
#}}}

#{{{ajax_checkin
sub ajax_checkin {
  my $self = shift;
  if ($self->query->param('commit') eq 'checkin') {
    my $checkin = $self->tomebook_checkin({id => $self->query->param('checkout_id')});
    if ($checkin) {
      return "Checked in";
    } else {
      return "Could not check in";
    }
  } elsif ($self->query->param('commit') eq 'cancel') {
    my $cancel = $self->tomebook_cancel_checkout({id => $self->query->param('checkout_id')});
    if ($cancel) {
      return "Cancelled!";
    } else {
      return "Could not cancel because it is not your book to check in.";
    }
  }
}
#}}}

#{{{_libraries

#{{{_libraryauthorized
sub _libraryauthorized {
	my $self = shift;
	my ($uid, $library) = @_;

	return scalar( grep { $_ == $library } ($self->library_access({user => $uid})) ) == 1;
}
#}}}

#{{{_librariesnotselecteddefault
sub _librariesnotselecteddefault {
	my $self = shift;

	my @libraries_not_selected = $self->query->param('not_libraries');
	unless(@libraries_not_selected) {
		foreach ($self->library_not_access({user =>$self->param('user_info')->{id}})) {
				push @libraries_not_selected, $_;
		}
	}
	return \@libraries_not_selected;
}
#}}}

#{{{_librariesselecteddefault
sub _librariesselecteddefault {
	my $self = shift;

	my @libraries_selected = $self->query->param('libraries');
	unless(@libraries_selected) {
		foreach ($self->library_access({user =>$self->param('user_info')->{id}})) {
				push @libraries_selected, $_;
		}
	}
	return \@libraries_selected;
}
#}}}

#}}}

#{{{_semesterselecteddefault
# !!! This logic is duplicated in blocks/semesterbox.html.  There's probably a good way to consolidate these...
sub _semesterselecteddefault {
	my $self = shift;

	my $semester_selected = $self->query->param('semester');
	unless($semester_selected) {
		$semester_selected = ($self->session->param('currsemester') || $self->param('currsemester'))->{id};
	}
	return $semester_selected;
}
#}}}

1;
