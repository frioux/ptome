package TOMETest;
use strict;

our %CONFIG;

require '../site-config.pl';

sub new {
	my ($type) = $_[0];
	my ($self) = {};
	bless ($self, $type);
	return($self);
}

sub returnconfig {
	#my $temp = $CONFIG;
	return %CONFIG;
}
