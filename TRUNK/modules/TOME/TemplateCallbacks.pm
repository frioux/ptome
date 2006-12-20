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

sub patron_checkouts_checkedout {
	my $self = shift;
	my $patron = shift;
	return $self->{tome}->patron_checkouts({ patron => $patron, type => 'checkedout' });
}

sub patron_checkouts_reserved {
	my $self = shift;
	my $patron = shift;
	return $self->{tome}->patron_checkouts({ patron => $patron, type => 'reserved' });
}

sub checkout_info {
	my $self = shift;
	my $checkout = shift;

	return $self->{tome}->checkout_info({ checkout => $checkout });
}

sub tomebook_info {
	my $self = shift;
	my $tomebook = shift;

	return $self->{tome}->tomebook_info({ tomebook => $tomebook });
}

sub book_info {
	my $self = shift;
	my $isbn = shift;

	return $self->{tome}->book_info({ isbn => $isbn });
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

1;
