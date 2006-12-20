package TOMETest;
use strict;

our %CONFIG;
require '../site-config.pl';

sub new {
	my ($type) = shift;

	my $self = {
		config	=> \%CONFIG,
	};

	bless ($self, $type);
	return ($self);
}

1;
