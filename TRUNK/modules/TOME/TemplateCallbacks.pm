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
	return $self->{tome}->patron_info(@_);
}

1;
