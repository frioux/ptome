package TOMETest;
use strict;

our %CONFIG = (
        cgibase         => '/perl/tome/cgi',
        staticbase      => '/tome',

        templatepath    => '../templates',

        dbidbname	=> 'tome',
	dbihostname	=> 'localhost',
	dbiport		=> '5432',
        dbiusername     => 'tome',
        dbipassword     => 'password',

        notifyfrom      => 'TOMEkeeper <tomekeeper@tome>',
        adminemail      => 'TOMEadmin <tomeadmin@tome>',

        devmode         => 0,
        devemailto      => 'TOMEadmin <tomeadmin@tome>',
);

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
