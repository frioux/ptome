package TOMETest::DBTest;
use base 'TOMETest';

use DBI;

use strict;

sub new {
	my $class = shift;

	my $self = $class->SUPER::new();

	my $dbh = DBI->connect("dbi:Pg:dbname=$self->{config}{dbidbname};host=$self->{config}{dbihostname};port=$self->{config}{dbiport}", $self->{config}{dbiusername}, $self->{config}{dbipassword}, { RaiseError => 1, PrintError => 0 }) or die $DBI::errstr;

	$self->{dbh} = $dbh;

	return $self;
}

return (1);
