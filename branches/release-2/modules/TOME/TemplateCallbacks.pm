package TOME::TemplateCallbacks;

use strict;
use warnings;

sub new {
	my $class = shift;
	my $tome = shift;

	my $self = { tome => $tome };

	bless $self, $class;
}

sub patron_info {
	my $self = shift;
	my $id = shift;
	return $self->{tome}->patron_info({ id => $id });
}

sub patron_checkouts {
	my $self = shift;
	my $patron = shift;
	return $self->{tome}->checkout_search({ patron => $patron, status => 'checked_out' });
}

sub patron_reservations {
	my $self = shift;
	my $patron = shift;
	return $self->{tome}->reservation_search({ patron => $patron });
}

sub checkout_info {
	my $self = shift;
	my $checkout = shift;

	return $self->{tome}->checkout_info({ id => $checkout });
}

sub isbnview_to_libraries {
  my $self = shift;
  my $semester = shift;
  my $from_library = shift;
  my $isbn = shift;

  return $self->{tome}->isbnview_to_libraries($semester, $from_library, $isbn);
}

sub tomebook_info {
	my $self = shift;
	my $tomebook = shift;

	return $self->{tome}->tomebook_info({ tomebook => $tomebook });
}

sub semester {
  my $self = shift;
  return 2;
}

sub book_info {
	my $self = shift;
	my $isbn = shift;

	return $self->{tome}->book_info({ isbn => $isbn });
}

sub class_book_info {
  my $self = shift;
  my $class = shift;
  my $isbn = shift;

  return $self->{tome}->class_book_info({ isbn => $isbn, class_id => $class });
}

sub book_classes {
        my $self = shift;
        my $isbn = shift;

        return $self->{tome}->book_classes({ isbn => $isbn });
}

sub library_info {
	my $self = shift;
	my $library = shift;

	return $self->{tome}->library_info({ id => $library });
}

sub libraries {
        my $self = shift;

        return $self->{tome}->library_info();
}

sub library_access {
	my $self = shift;

	return [ $self->{tome}->library_access({ user => $self->{tome}->param('user_info')->{id} }) ];
}

sub library_not_access {
	my $self = shift;

	return [ $self->{tome}->library_not_access({ user => $self->{tome}->param('user_info')->{id} }) ];
}

sub reservation_info {
    my $self = shift;
    my $reservation = shift;

    return $self->{tome}->reservation_info({ id => $reservation });
}

sub tomebooks_available_for_checkout {
  my $self = shift;
  my $isbn = shift;
  my $library = shift;
  my $semester = shift;

  return $self->{tome}->tomebook_availability_search({ isbn => $isbn, libraries => [ $library ], semester => $semester, status => 'can_checkout' });
}


1;
